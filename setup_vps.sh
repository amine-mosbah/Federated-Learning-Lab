#!/bin/bash

# VPS Setup Script for Federated Learning Lab
# Complete automated setup for Ubuntu 20.04/22.04 with NVIDIA GPU

set -e

echo "======================================"
echo "VPS Setup for Federated Learning"
echo "======================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running on Ubuntu
if [[ ! -f /etc/os-release ]]; then
    echo -e "${RED}✗ Cannot detect OS. This script is for Ubuntu 20.04/22.04${NC}"
    exit 1
fi

source /etc/os-release
if [[ "$ID" != "ubuntu" ]]; then
    echo -e "${RED}✗ This script is designed for Ubuntu. Detected: $ID${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Detected: $PRETTY_NAME${NC}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Update system
echo -e "\n${YELLOW}[1/7] Updating system packages...${NC}"
sudo apt-get update -qq
echo -e "${GREEN}✓ System updated${NC}"

# Step 2: Check NVIDIA driver
echo -e "\n${YELLOW}[2/7] Checking NVIDIA drivers...${NC}"
if command_exists nvidia-smi; then
    echo -e "${GREEN}✓ NVIDIA driver already installed${NC}"
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
else
    echo -e "${YELLOW}⚠ NVIDIA driver not found. Installing...${NC}"
    echo -e "${BLUE}This may take several minutes...${NC}"
    
    sudo apt-get install -y nvidia-driver-535
    echo -e "${YELLOW}⚠ System needs to reboot to load NVIDIA driver${NC}"
    echo -e "${YELLOW}After reboot, run this script again.${NC}"
    read -p "Reboot now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo reboot
    fi
    exit 0
fi

# Step 3: Install Docker
echo -e "\n${YELLOW}[3/7] Installing Docker...${NC}"
if command_exists docker; then
    echo -e "${GREEN}✓ Docker already installed: $(docker --version)${NC}"
else
    echo -e "${BLUE}Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    echo -e "${GREEN}✓ Docker installed${NC}"
    echo -e "${YELLOW}⚠ You may need to log out and back in for group changes to take effect${NC}"
fi

# Step 4: Install Docker Compose
echo -e "\n${YELLOW}[4/7] Checking Docker Compose...${NC}"
if docker compose version &>/dev/null; then
    echo -e "${GREEN}✓ Docker Compose already installed: $(docker compose version)${NC}"
else
    echo -e "${RED}✗ Docker Compose not found. Please install Docker Compose v2+${NC}"
    exit 1
fi

# Step 5: Install NVIDIA Container Toolkit
echo -e "\n${YELLOW}[5/7] Installing NVIDIA Container Toolkit...${NC}"
if docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi &>/dev/null; then
    echo -e "${GREEN}✓ NVIDIA Container Toolkit already working${NC}"
else
    echo -e "${BLUE}Installing NVIDIA Container Toolkit...${NC}"
    
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    sudo apt-get update -qq
    sudo apt-get install -y nvidia-docker2
    sudo systemctl restart docker
    
    echo -e "${GREEN}✓ NVIDIA Container Toolkit installed${NC}"
    
    # Test GPU access
    echo -e "${BLUE}Testing GPU access in Docker...${NC}"
    if docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi; then
        echo -e "${GREEN}✓ GPU access working in Docker${NC}"
    else
        echo -e "${RED}✗ GPU access test failed${NC}"
        exit 1
    fi
fi

# Step 6: Install Python dependencies for orchestrator
echo -e "\n${YELLOW}[6/7] Installing Python dependencies...${NC}"
if command_exists python3; then
    echo -e "${GREEN}✓ Python3 found: $(python3 --version)${NC}"
else
    sudo apt-get install -y python3 python3-pip
fi

pip3 install --user httpx
echo -e "${GREEN}✓ Python dependencies installed${NC}"

# Step 7: Configure firewall
echo -e "\n${YELLOW}[7/7] Configuring firewall...${NC}"
if command_exists ufw; then
    # Check if UFW is active
    if sudo ufw status | grep -q "Status: active"; then
        echo -e "${BLUE}UFW is active, adding rules...${NC}"
        sudo ufw allow 8001/tcp comment 'FL Client 1'
        sudo ufw allow 8002/tcp comment 'FL Client 2'
        sudo ufw allow 8003/tcp comment 'FL Client 3'
        sudo ufw allow 9000/tcp comment 'FL Aggregator'
        sudo ufw reload
        echo -e "${GREEN}✓ Firewall rules added${NC}"
    else
        echo -e "${YELLOW}⚠ UFW is installed but not active${NC}"
        read -p "Enable UFW and add rules? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo ufw allow ssh
            sudo ufw allow 8001/tcp comment 'FL Client 1'
            sudo ufw allow 8002/tcp comment 'FL Client 2'
            sudo ufw allow 8003/tcp comment 'FL Client 3'
            sudo ufw allow 9000/tcp comment 'FL Aggregator'
            sudo ufw --force enable
            echo -e "${GREEN}✓ Firewall enabled and configured${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠ UFW not installed, skipping firewall configuration${NC}"
fi

# Summary
echo -e "\n${GREEN}======================================"
echo "VPS Setup Complete!"
echo "======================================${NC}"
echo -e "\n${YELLOW}System Information:${NC}"
echo "  OS: $PRETTY_NAME"
echo "  Docker: $(docker --version)"
echo "  GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)"
echo "  CUDA: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "  1. If you just added yourself to docker group, log out and back in"
echo "  2. Navigate to project directory: cd ~/TP_Federated"
echo "  3. Deploy services: ./deploy_docker.sh"
echo "  4. Run federated learning: python3 orchestrator.py"

echo -e "\n${YELLOW}Useful Commands:${NC}"
echo "  Deploy:          ./deploy_docker.sh"
echo "  Check services:  docker compose ps"
echo "  View logs:       docker compose logs -f"
echo "  Stop services:   docker compose down"
echo "  Monitor GPU:     watch nvidia-smi"

echo -e "\n${GREEN}Setup completed successfully!${NC}"
