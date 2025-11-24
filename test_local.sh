#!/bin/bash

# Federated Learning Test Script - Local Testing
# Tests all services locally before Docker deployment

set -e

echo "======================================"
echo "FL Local Test Script"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Python installation
echo -e "\n${YELLOW}[1/5] Checking Python installation...${NC}"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✓ Python found: $PYTHON_VERSION${NC}"
else
    echo -e "${RED}✗ Python 3 not found. Please install Python 3.8+${NC}"
    exit 1
fi

# Check if virtual environment exists
echo -e "\n${YELLOW}[2/5] Setting up virtual environment...${NC}"
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

echo "Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo -e "\n${YELLOW}[3/5] Installing dependencies...${NC}"
pip install -q --upgrade pip
pip install -q -r requirements.txt
echo -e "${GREEN}✓ Dependencies installed${NC}"

# Check CUDA availability
echo -e "\n${YELLOW}[4/5] Checking CUDA/GPU availability...${NC}"
python3 -c "
from numba import cuda
try:
    if cuda.is_available():
        print('✓ CUDA is available')
        print(f'  Devices: {cuda.gpus}')
    else:
        print('⚠ CUDA not available - will use CPU fallback')
except Exception as e:
    print(f'⚠ CUDA check failed: {e}')
    print('  Will use CPU fallback')
"

# Start services in background
echo -e "\n${YELLOW}[5/5] Starting services...${NC}"

# Kill any existing instances
pkill -f "python3.*client.py" 2>/dev/null || true
pkill -f "python3.*aggregator.py" 2>/dev/null || true
sleep 2

echo "Starting Client 1 on port 8001..."
CLIENT_ID=1 PORT=8001 python3 client.py > logs_client1.txt 2>&1 &
CLIENT1_PID=$!

echo "Starting Client 2 on port 8002..."
CLIENT_ID=2 PORT=8002 python3 client.py > logs_client2.txt 2>&1 &
CLIENT2_PID=$!

echo "Starting Client 3 on port 8003..."
CLIENT_ID=3 PORT=8003 python3 client.py > logs_client3.txt 2>&1 &
CLIENT3_PID=$!

echo "Starting Aggregator on port 9000..."
python3 aggregator.py > logs_aggregator.txt 2>&1 &
AGGREGATOR_PID=$!

# Wait for services to start
echo -e "\n${YELLOW}Waiting for services to start...${NC}"
sleep 5

# Check if services are running
echo -e "\n${YELLOW}Checking service health...${NC}"
check_service() {
    local url=$1
    local name=$2
    if curl -s "$url/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ $name is running${NC}"
        return 0
    else
        echo -e "${RED}✗ $name failed to start${NC}"
        return 1
    fi
}

ALL_HEALTHY=true
check_service "http://localhost:8001" "Client 1" || ALL_HEALTHY=false
check_service "http://localhost:8002" "Client 2" || ALL_HEALTHY=false
check_service "http://localhost:8003" "Client 3" || ALL_HEALTHY=false
check_service "http://localhost:9000" "Aggregator" || ALL_HEALTHY=false

if [ "$ALL_HEALTHY" = false ]; then
    echo -e "\n${RED}Some services failed to start. Check log files:${NC}"
    echo "  - logs_client1.txt"
    echo "  - logs_client2.txt"
    echo "  - logs_client3.txt"
    echo "  - logs_aggregator.txt"
    
    # Cleanup
    kill $CLIENT1_PID $CLIENT2_PID $CLIENT3_PID $AGGREGATOR_PID 2>/dev/null || true
    exit 1
fi

# Run federated learning orchestrator
echo -e "\n${GREEN}======================================"
echo "All services are running!"
echo "======================================${NC}"
echo -e "\n${YELLOW}Running federated learning round...${NC}\n"

python3 orchestrator.py

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}Shutting down services...${NC}"
    kill $CLIENT1_PID $CLIENT2_PID $CLIENT3_PID $AGGREGATOR_PID 2>/dev/null || true
    echo -e "${GREEN}✓ All services stopped${NC}"
}

# Register cleanup on exit
trap cleanup EXIT

echo -e "\n${GREEN}======================================"
echo "Test completed successfully!"
echo "======================================${NC}"
echo -e "\nLogs saved to:"
echo "  - logs_client1.txt"
echo "  - logs_client2.txt"
echo "  - logs_client3.txt"
echo "  - logs_aggregator.txt"
echo "  - fl_results.json"
echo -e "\nPress Ctrl+C to stop all services..."

# Keep script running
wait
