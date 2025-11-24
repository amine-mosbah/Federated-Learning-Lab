# Federated Learning with GPU Acceleration Lab

A complete implementation of Federated Learning using Numba CUDA for GPU acceleration, FastAPI microservices, and Docker deployment.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Local Development Setup](#local-development-setup)
- [Docker Deployment](#docker-deployment)
- [VPS Deployment Guide](#vps-deployment-guide)
- [Testing the System](#testing-the-system)
- [API Documentation](#api-documentation)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

This project implements a **Federated Learning (FL)** system where multiple clients train a shared machine learning model without sharing their raw data. Each client trains locally on GPU-accelerated hardware and sends only model parameters to a central aggregator.

### Learning Objectives

- Understand federated learning concepts and architecture
- Implement GPU-accelerated training using Numba CUDA kernels
- Build microservices with FastAPI
- Deploy distributed systems with Docker Compose
- Work with NVIDIA GPUs in containerized environments

### Model

Simple linear regression: `y = w * x + b`

- **Target parameters**: w=3.5, b=2.0
- **Training**: GPU-accelerated gradient descent using Numba CUDA
- **Aggregation**: Federated Averaging (FedAvg)

## 🏗️ Architecture

```
+------------------+
| Aggregator API   |
| (Port 9000)      |
+--------+---------+
         |
         | Federated Averaging
         |
    +----+----+----+
    |    |    |    |
+---v--+ | +--v---+ | +---v--+
|Client| | |Client| | |Client|
|  1   | | |  2   | | |  3   |
|8001  | | |8002  | | |8003  |
+------+ | +------+ | +------+
  GPU    |   GPU    |   GPU
```

### Components

1. **Client Services (×3)**

   - Local training with synthetic data
   - GPU-accelerated gradient computation via Numba CUDA
   - Exposes `/train` and `/health` endpoints
   - Returns trained model parameters (w, b, loss)

2. **Aggregator Service**

   - Collects client updates
   - Computes global model via Federated Averaging
   - Exposes `/aggregate` and `/health` endpoints

3. **Orchestrator**
   - Coordinates FL rounds
   - Manages client training and aggregation
   - Saves results to JSON

## ✨ Features

- ✅ **GPU Acceleration**: Numba CUDA kernels for gradient computation
- ✅ **Microservices**: FastAPI-based distributed architecture
- ✅ **Containerization**: Docker with NVIDIA GPU support
- ✅ **Orchestration**: Automated FL round execution
- ✅ **Privacy-Preserving**: Only model parameters shared, not raw data
- ✅ **Production-Ready**: Health checks, error handling, logging

## 📦 Prerequisites

### Local Development

```bash
# Python
Python 3.8+

# Python packages (auto-installed from requirements.txt)
- fastapi
- uvicorn
- numpy
- numba
- pydantic
- httpx

# For GPU acceleration
- NVIDIA GPU with CUDA support
- NVIDIA drivers (latest)
- CUDA Toolkit 11.0+ (for local development)
```

### Docker Deployment

```bash
# Docker
Docker 20.10+
Docker Compose 2.0+

# NVIDIA Container Toolkit
nvidia-docker2
```

## 🚀 Local Development Setup

### 1. Clone/Navigate to Project

```bash
cd /home/hama/Desktop/TP_Hamza/TP_Federated
```

### 2. Create Virtual Environment

```bash
python3 -m venv venv
source venv/bin/activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Run Local Test

```bash
# Option A: Use automated test script
./test_local.sh

# Option B: Manual start
# Terminal 1: Client 1
CLIENT_ID=1 PORT=8001 python3 client.py

# Terminal 2: Client 2
CLIENT_ID=2 PORT=8002 python3 client.py

# Terminal 3: Client 3
CLIENT_ID=3 PORT=8003 python3 client.py

# Terminal 4: Aggregator
python3 aggregator.py

# Terminal 5: Run orchestrator
python3 orchestrator.py
```

## 🐳 Docker Deployment

### Quick Start

```bash
# Build and deploy all services
./deploy_docker.sh
```

### Manual Docker Commands

```bash
# Build images
docker compose build

# Start all services
docker compose up -d

# Check service status
docker compose ps

# View logs
docker compose logs -f client1
docker compose logs -f aggregator

# Stop services
docker compose down

# Restart a service
docker compose restart client1
```

## 🌐 VPS Deployment Guide

Complete guide for deploying on a remote VPS with NVIDIA GPU.

### Step 1: VPS Requirements

- **OS**: Ubuntu 20.04/22.04 LTS
- **GPU**: NVIDIA GPU with CUDA support
- **RAM**: 4GB+ recommended
- **Storage**: 10GB+ free space
- **Network**: Ports 8001-8003, 9000 accessible

### Step 2: Connect to VPS

```bash
# SSH into your VPS
ssh username@your-vps-ip

# Or with key
ssh -i ~/.ssh/your-key.pem username@your-vps-ip
```

### Step 3: Install NVIDIA Drivers & CUDA

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Check if NVIDIA driver is installed
nvidia-smi

# If not installed, install NVIDIA drivers
sudo apt-get install -y nvidia-driver-535

# Reboot
sudo reboot

# After reboot, verify
nvidia-smi
```

### Step 4: Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Verify Docker installation
docker --version
docker compose version
```

### Step 5: Install NVIDIA Container Toolkit

```bash
# Add NVIDIA package repositories
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Install nvidia-docker2
sudo apt-get update
sudo apt-get install -y nvidia-docker2

# Restart Docker
sudo systemctl restart docker

# Test GPU access in Docker
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
```

### Step 6: Transfer Project to VPS

```bash
# Option A: Using SCP (from your local machine)
scp -r /home/hama/Desktop/TP_Hamza/TP_Federated username@your-vps-ip:~/

# Option B: Using Git
# On VPS:
cd ~
git clone https://github.com/yourusername/TP_Federated.git
cd TP_Federated
```

### Step 7: Configure Firewall

```bash
# Allow required ports
sudo ufw allow 8001/tcp
sudo ufw allow 8002/tcp
sudo ufw allow 8003/tcp
sudo ufw allow 9000/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

### Step 8: Deploy on VPS

```bash
# Navigate to project directory
cd ~/TP_Federated

# Build and start services
./deploy_docker.sh

# Or manually
docker compose up -d --build

# Check running containers
docker compose ps

# View logs
docker compose logs -f
```

### Step 9: Run Federated Learning

```bash
# Install Python dependencies for orchestrator
pip3 install httpx

# Run orchestrator
python3 orchestrator.py

# View results
cat fl_results.json
```

### Step 10: Monitor GPU Usage

```bash
# Watch GPU usage in real-time
watch -n 1 nvidia-smi

# Or in Docker
docker exec fl_client1 nvidia-smi
```

## 🧪 Testing the System

### Health Checks

```bash
# Check all services
curl http://localhost:8001/health
curl http://localhost:8002/health
curl http://localhost:8003/health
curl http://localhost:9000/health
```

### Manual Training Test

```bash
# Train individual client
curl -X POST http://localhost:8001/train

# Expected response:
# {
#   "client_id": "1",
#   "w": 3.4892,
#   "b": 1.9876,
#   "loss": 0.0123
# }
```

### Full Federated Learning Round

```bash
# Using orchestrator
python3 orchestrator.py

# Or manually
# 1. Train all clients
curl -X POST http://localhost:8001/train > client1.json
curl -X POST http://localhost:8002/train > client2.json
curl -X POST http://localhost:8003/train > client3.json

# 2. Aggregate results
curl -X POST http://localhost:9000/aggregate \
  -H "Content-Type: application/json" \
  -d '{
    "updates": [
      '$(cat client1.json)',
      '$(cat client2.json)',
      '$(cat client3.json)'
    ]
  }'
```

## 📚 API Documentation

### Client Service API

#### `GET /health`

Returns service health status.

**Response:**

```json
{
  "status": "healthy",
  "client_id": "1",
  "cuda_available": true
}
```

#### `POST /train`

Trains local model and returns weights.

**Response:**

```json
{
  "client_id": "1",
  "w": 3.4892,
  "b": 1.9876,
  "loss": 0.0123
}
```

### Aggregator Service API

#### `GET /health`

Returns service health status.

**Response:**

```json
{
  "status": "healthy",
  "service": "aggregator"
}
```

#### `POST /aggregate`

Aggregates client updates into global model.

**Request:**

```json
{
  "updates": [
    {
      "client_id": "1",
      "w": 3.48,
      "b": 1.98,
      "loss": 0.012
    },
    {
      "client_id": "2",
      "w": 3.52,
      "b": 2.01,
      "loss": 0.011
    },
    {
      "client_id": "3",
      "w": 3.49,
      "b": 2.02,
      "loss": 0.013
    }
  ]
}
```

**Response:**

```json
{
  "global_w": 3.4967,
  "global_b": 2.0033,
  "num_clients": 3,
  "client_losses": {
    "1": 0.012,
    "2": 0.011,
    "3": 0.013
  },
  "avg_loss": 0.012
}
```

### Interactive API Docs

Once services are running:

- Client 1: http://localhost:8001/docs
- Client 2: http://localhost:8002/docs
- Client 3: http://localhost:8003/docs
- Aggregator: http://localhost:9000/docs

## 📊 Monitoring

### GPU Usage

```bash
# Real-time monitoring
watch -n 1 nvidia-smi

# Log GPU stats
nvidia-smi --query-gpu=timestamp,name,temperature.gpu,utilization.gpu,utilization.memory \
  --format=csv -l 1 > gpu_stats.csv
```

### Container Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f client1

# Last 100 lines
docker compose logs --tail=100 client1
```

### System Resources

```bash
# Docker stats
docker stats

# Container resource usage
docker compose top
```

## 🔧 Troubleshooting

### Issue: CUDA not available in container

**Solution:**

```bash
# Check NVIDIA Docker runtime
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi

# Restart Docker daemon
sudo systemctl restart docker

# Rebuild containers
docker compose down
docker compose up -d --build
```

### Issue: Port already in use

**Solution:**

```bash
# Find process using port
sudo lsof -i :8001

# Kill process
sudo kill -9 <PID>

# Or change port in docker-compose.yml
```

### Issue: Service not responding

**Solution:**

```bash
# Check container status
docker compose ps

# View logs
docker compose logs client1

# Restart service
docker compose restart client1

# Full restart
docker compose down
docker compose up -d
```

### Issue: Connection refused from orchestrator

**Solution:**

```bash
# Wait for services to fully start
sleep 10

# Check health endpoints
curl http://localhost:8001/health

# Verify network connectivity
docker network inspect tp_federated_fl_network
```

### Issue: Out of memory on GPU

**Solution:**

- Reduce DATA_SIZE in client.py
- Reduce number of concurrent clients
- Use CPU fallback mode

## 📁 Project Structure

```
TP_Federated/
├── client.py                  # FL Client service with GPU training
├── aggregator.py              # FL Aggregator service
├── orchestrator.py            # FL round orchestration
├── requirements.txt           # Python dependencies
├── Dockerfile.client          # Client container image
├── Dockerfile.aggregator      # Aggregator container image
├── docker-compose.yml         # Multi-container orchestration
├── test_local.sh             # Local testing script
├── deploy_docker.sh          # Docker deployment script
├── README.md                 # This file
└── .gitignore                # Git ignore rules
```

## 🎓 Expected Results

After running a complete FL round:

```
Client 1: w=3.487, b=1.995
Client 2: w=3.492, b=2.008
Client 3: w=3.503, b=1.997

Global Model: w=3.494, b=2.000
Error: Δw=0.006, Δb=0.000
```

The global model should be very close to the theoretical values (w=3.5, b=2.0).

## 🚀 Next Steps / Bonus Challenges

- [ ] Implement multiple FL rounds (iterative training)
- [ ] Add logistic regression instead of linear regression
- [ ] Integrate Prometheus for metrics collection
- [ ] Add Grafana dashboards for visualization
- [ ] Implement client selection strategies
- [ ] Add differential privacy mechanisms
- [ ] Support weighted aggregation based on data size

## 📝 Deliverables Checklist

- [x] 3 client services with GPU acceleration
- [x] 1 aggregator service
- [x] Complete docker-compose.yml with GPU support
- [x] Source code on GitHub
- [x] README with deployment instructions
- [x] Testing scripts
- [x] VPS deployment guide

## 🤝 Authors

Lab completed by: [Your Name]
Date: November 24, 2025

## 📄 License

This project is for educational purposes as part of a Federated Learning lab session.

## 🆘 Support

For issues or questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review Docker logs: `docker compose logs -f`
3. Contact the instructor for VPS access
