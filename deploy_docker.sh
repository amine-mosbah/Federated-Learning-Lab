#!/bin/bash

# Federated Learning Docker Deployment Script
# Deploys the FL system using Docker Compose

set -e

echo "======================================"
echo "FL Docker Deployment Script"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Docker installation
echo -e "\n${YELLOW}[1/4] Checking Docker installation...${NC}"
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo -e "${GREEN}✓ Docker found: $DOCKER_VERSION${NC}"
else
    echo -e "${RED}✗ Docker not found. Please install Docker first.${NC}"
    exit 1
fi

# Check Docker Compose
if command -v docker compose &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version)
    echo -e "${GREEN}✓ Docker Compose found: $COMPOSE_VERSION${NC}"
else
    echo -e "${RED}✗ Docker Compose not found. Please install Docker Compose first.${NC}"
    exit 1
fi

# Check NVIDIA Docker runtime
echo -e "\n${YELLOW}[2/4] Checking NVIDIA Docker runtime...${NC}"
if docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
    echo -e "${GREEN}✓ NVIDIA Docker runtime is working${NC}"
else
    echo -e "${RED}✗ NVIDIA Docker runtime not working.${NC}"
    echo -e "${YELLOW}Please install nvidia-docker2:${NC}"
    echo "  sudo apt-get install -y nvidia-docker2"
    echo "  sudo systemctl restart docker"
    exit 1
fi

# Build and start services
echo -e "\n${YELLOW}[3/4] Building and starting Docker containers...${NC}"
docker compose down 2>/dev/null || true
docker compose build --no-cache
docker compose up -d

# Wait for services to be ready
echo -e "\n${YELLOW}[4/4] Waiting for services to start...${NC}"
sleep 10

# Check service health
echo -e "\n${YELLOW}Checking service health...${NC}"
check_service() {
    local url=$1
    local name=$2
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url/health" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ $name is healthy${NC}"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 1
    done
    
    echo -e "${RED}✗ $name failed to start (timeout)${NC}"
    return 1
}

ALL_HEALTHY=true
check_service "http://localhost:8001" "Client 1" || ALL_HEALTHY=false
check_service "http://localhost:8002" "Client 2" || ALL_HEALTHY=false
check_service "http://localhost:8003" "Client 3" || ALL_HEALTHY=false
check_service "http://localhost:9000" "Aggregator" || ALL_HEALTHY=false

if [ "$ALL_HEALTHY" = false ]; then
    echo -e "\n${RED}Some services failed to start. Check logs:${NC}"
    echo "  docker compose logs client1"
    echo "  docker compose logs client2"
    echo "  docker compose logs client3"
    echo "  docker compose logs aggregator"
    exit 1
fi

echo -e "\n${GREEN}======================================"
echo "All services are running!"
echo "======================================${NC}"

echo -e "\n${YELLOW}Service URLs:${NC}"
echo "  Client 1:   http://localhost:8001"
echo "  Client 2:   http://localhost:8002"
echo "  Client 3:   http://localhost:8003"
echo "  Aggregator: http://localhost:9000"

echo -e "\n${YELLOW}Running federated learning orchestrator...${NC}\n"

# Run orchestrator
python3 orchestrator.py

echo -e "\n${GREEN}======================================"
echo "Federated Learning Round Complete!"
echo "======================================${NC}"

echo -e "\n${YELLOW}Useful commands:${NC}"
echo "  View logs:       docker compose logs -f [service_name]"
echo "  Stop services:   docker compose down"
echo "  Check GPU usage: watch nvidia-smi"
echo "  Restart:         docker compose restart"

echo -e "\n${YELLOW}Monitor GPU usage:${NC}"
echo "  Run in another terminal: watch nvidia-smi"
