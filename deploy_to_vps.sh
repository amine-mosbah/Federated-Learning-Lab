                                        #!/bin/bash

################################################################################
# Federated Learning VPS Deployment Script
# Target VPS: latis@REDACTED:2222
# Note: Port 8000 on VPS is mapped to 8800 externally
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# VPS Configuration
VPS_USER="latis"
VPS_HOST="REDACTED"
VPS_PORT="2222"
VPS_PASSWORD="REDACTED"
REMOTE_DIR="~/TP_Federated"

echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}FL VPS Deployment Script${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""
echo -e "${YELLOW}Target VPS:${NC} ${VPS_USER}@${VPS_HOST}:${VPS_PORT}"
echo -e "${YELLOW}Remote Directory:${NC} ${REMOTE_DIR}"
echo ""

# Function to print step headers
print_step() {
    echo ""
    echo -e "${GREEN}==>${NC} ${BLUE}$1${NC}"
    echo ""
}

# Function to run SSH command
run_ssh() {
    ssh -p ${VPS_PORT} -o StrictHostKeyChecking=no ${VPS_USER}@${VPS_HOST} "$1"
}

# Function to run SCP
run_scp() {
    scp -P ${VPS_PORT} -o StrictHostKeyChecking=no -r "$1" "${VPS_USER}@${VPS_HOST}:$2"
}

# Check if sshpass is installed (Skipped - using manual entry)
# if ! command -v sshpass &> /dev/null; then
#     echo -e "${RED}Error: sshpass is not installed${NC}"
#     echo "Install it with: sudo apt-get install sshpass"
#     exit 1
# fi

# Step 1: Test VPS connection
print_step "Step 1: Testing VPS connection..."
if run_ssh "echo 'Connection successful'"; then
    echo -e "${GREEN}✓ VPS connection successful${NC}"
else
    echo -e "${RED}✗ Failed to connect to VPS${NC}"
    exit 1
fi

# Step 2: Transfer project files to VPS
print_step "Step 2: Transferring project files to VPS..."
echo "Creating optimized archive (excluding venv, .git)..."

# Create tarball in /tmp to avoid "file changed" errors
tar -czf /tmp/project_deploy.tar.gz \
    --exclude='venv' \
    --exclude='.git' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='fl_client_package.zip' \
    .

echo "Transferring archive..."
if run_scp "/tmp/project_deploy.tar.gz" "~/"; then
    echo -e "${GREEN}✓ Archive transferred${NC}"
    
    echo "Extracting on VPS..."
    run_ssh "mkdir -p ${REMOTE_DIR} && tar -xzf ~/project_deploy.tar.gz -C ${REMOTE_DIR} && rm ~/project_deploy.tar.gz"
    
    # Cleanup local
    rm /tmp/project_deploy.tar.gz
    echo -e "${GREEN}✓ Files extracted successfully${NC}"
else
    rm /tmp/project_deploy.tar.gz
    echo -e "${RED}✗ File transfer failed${NC}"
    exit 1
fi

# Step 3: Setup VPS environment
print_step "Step 3: Setting up VPS environment..."

run_ssh "cd ${REMOTE_DIR} && chmod +x *.sh"

# Step 4: Run VPS setup script
print_step "Step 4: Running VPS setup script..."
echo -e "${YELLOW}Note: This may take 10-15 minutes...${NC}"

run_ssh "cd ${REMOTE_DIR} && ./setup_vps.sh" || {
    echo -e "${YELLOW}Warning: Setup script encountered issues. You may need to run it manually.${NC}"
}

# Step 5: Check if reboot is needed
print_step "Step 5: Checking system status..."
if run_ssh "command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null"; then
    echo -e "${GREEN}✓ NVIDIA drivers are working${NC}"
else
    echo -e "${YELLOW}⚠ NVIDIA drivers may need a reboot${NC}"
    echo -e "${YELLOW}After this script completes, you may need to:${NC}"
    echo -e "${YELLOW}  1. SSH into the VPS${NC}"
    echo -e "${YELLOW}  2. Run: sudo reboot${NC}"
    echo -e "${YELLOW}  3. Wait 2 minutes and reconnect${NC}"
    echo -e "${YELLOW}  4. Run: cd ${REMOTE_DIR} && ./deploy_docker.sh${NC}"
fi

# Step 6: Deploy with Docker
print_step "Step 6: Deploying with Docker..."
echo -e "${YELLOW}Attempting Docker deployment...${NC}"

run_ssh "cd ${REMOTE_DIR} && ./deploy_docker.sh" || {
    echo -e "${YELLOW}Warning: Docker deployment may need manual intervention${NC}"
}

# Step 7: Display access information
print_step "Deployment Summary"
echo ""
echo -e "${GREEN}✓ Project deployed to VPS${NC}"
echo ""
echo -e "${BLUE}To access your services:${NC}"
echo ""
echo -e "  ${YELLOW}SSH into VPS:${NC}"
echo -e "    ssh ${VPS_USER}@${VPS_HOST} -p ${VPS_PORT}"
echo ""
echo -e "  ${YELLOW}Service URLs (from VPS):${NC}"
echo -e "    Client 1: http://localhost:8001/health"
echo -e "    Client 2: http://localhost:8002/health"
echo -e "    Client 3: http://localhost:8003/health"
echo -e "    Aggregator: http://localhost:9000/health"
echo ""
echo -e "  ${YELLOW}Service URLs (external - if ports are exposed):${NC}"
echo -e "    Client 1: http://${VPS_HOST}:8001/health"
echo -e "    Client 2: http://${VPS_HOST}:8002/health"
echo -e "    Client 3: http://${VPS_HOST}:8003/health"
echo -e "    Aggregator: http://${VPS_HOST}:9000/health"
echo ""
echo -e "  ${YELLOW}Run FL training:${NC}"
echo -e "    ssh ${VPS_USER}@${VPS_HOST} -p ${VPS_PORT}"
echo -e "    cd ${REMOTE_DIR}"
echo -e "    python3 orchestrator.py"
echo ""
echo -e "  ${YELLOW}Monitor services:${NC}"
echo -e "    docker compose ps"
echo -e "    docker compose logs -f"
echo -e "    watch nvidia-smi"
echo ""
echo -e "${BLUE}=================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${BLUE}=================================${NC}"
