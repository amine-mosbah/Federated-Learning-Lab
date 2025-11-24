# Federated Learning Lab - Quick Start Guide

## 🚀 Quick Deployment Steps

### Local Testing (Your Machine)

```bash
# 1. Install dependencies
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 2. Run test (automated)
./test_local.sh
```

### Docker Testing (Your Machine)

```bash
# 1. Ensure Docker and nvidia-docker2 installed
docker --version
nvidia-smi

# 2. Deploy
./deploy_docker.sh

# 3. Check status
docker compose ps
docker compose logs -f
```

### VPS Deployment (Remote Server)

```bash
# 1. Connect to VPS
ssh username@your-vps-ip

# 2. Transfer project
# (From local machine)
scp -r /home/hama/Desktop/TP_Hamza/TP_Federated username@your-vps-ip:~/

# 3. Setup VPS (on VPS)
cd ~/TP_Federated
./setup_vps.sh

# 4. Deploy (on VPS)
./deploy_docker.sh

# 5. Run FL round (on VPS)
python3 orchestrator.py
```

## 📋 Prerequisites Checklist

### Before Starting

- [ ] Python 3.8+ installed
- [ ] NVIDIA GPU available
- [ ] NVIDIA drivers installed (`nvidia-smi` works)
- [ ] Docker installed (for Docker deployment)
- [ ] nvidia-docker2 installed (for Docker GPU support)

### Check Your System

```bash
# Python
python3 --version

# GPU
nvidia-smi

# Docker
docker --version
docker compose version

# GPU in Docker
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
```

## 🔧 Common Commands

### Service Management

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart a service
docker compose restart client1

# View logs
docker compose logs -f client1

# Check status
docker compose ps
```

### Testing Endpoints

```bash
# Health checks
curl http://localhost:8001/health
curl http://localhost:8002/health
curl http://localhost:8003/health
curl http://localhost:9000/health

# Train a client
curl -X POST http://localhost:8001/train

# Full FL round
python3 orchestrator.py
```

### Monitoring

```bash
# Watch GPU usage
watch -n 1 nvidia-smi

# Container stats
docker stats

# Service logs (live)
docker compose logs -f
```

## 🐛 Quick Troubleshooting

### CUDA not available

```bash
# Check NVIDIA driver
nvidia-smi

# Check Docker GPU access
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi

# Restart Docker
sudo systemctl restart docker
```

### Port already in use

```bash
# Find process
sudo lsof -i :8001

# Kill process
sudo kill -9 <PID>

# Or change port in docker-compose.yml
```

### Container won't start

```bash
# Check logs
docker compose logs client1

# Rebuild
docker compose down
docker compose build --no-cache
docker compose up -d
```

## 📊 Expected Output

After running `python3 orchestrator.py`:

```
======================================================================
FEDERATED LEARNING ORCHESTRATOR
======================================================================

[1/3] Checking service health...
✓ Client 1 is healthy
✓ Client 2 is healthy
✓ Client 3 is healthy
✓ Aggregator is healthy

✓ All services are healthy!

[2/3] Training local models...
----------------------------------------------------------------------

→ Training Client 1...
  Client 1 results: w=3.4892, b=1.9951, loss=0.0123

→ Training Client 2...
  Client 2 results: w=3.5123, b=2.0089, loss=0.0118

→ Training Client 3...
  Client 3 results: w=3.4981, b=1.9978, loss=0.0121

✓ All clients completed training!

[3/3] Aggregating models...
----------------------------------------------------------------------

============================================================
FEDERATED AVERAGING RESULTS
============================================================
Number of clients: 3

Client Updates:
  Client 1: w=3.4892, b=1.9951, loss=0.0123
  Client 2: w=3.5123, b=2.0089, loss=0.0118
  Client 3: w=3.4981, b=1.9978, loss=0.0121

Global Model:
  w = 3.4999
  b = 2.0006
  Average Loss = 0.0121

Theoretical Target: w=3.5, b=2.0
Error: Δw=0.0001, Δb=0.0006
============================================================

======================================================================
FEDERATED LEARNING ROUND COMPLETED
======================================================================

✓ Results saved to fl_results.json
```

## 📦 File Structure

```
TP_Federated/
├── client.py              # Client service (GPU training)
├── aggregator.py          # Aggregator service
├── orchestrator.py        # FL round coordinator
├── requirements.txt       # Python dependencies
├── docker-compose.yml     # Docker orchestration
├── Dockerfile.client      # Client container
├── Dockerfile.aggregator  # Aggregator container
├── test_local.sh         # Local test script
├── deploy_docker.sh      # Docker deployment
├── setup_vps.sh          # VPS setup script
├── README.md             # Full documentation
└── QUICKSTART.md         # This file
```

## 🎯 Deliverables

- [x] 3 client services with GPU acceleration
- [x] 1 aggregator service
- [x] docker-compose.yml with GPU support
- [x] Complete documentation
- [x] Testing scripts
- [x] VPS deployment guide

## 📞 Getting Help

1. Read the full [README.md](README.md)
2. Check service logs: `docker compose logs -f`
3. Test GPU: `nvidia-smi`
4. Verify endpoints: `curl http://localhost:8001/health`
5. Contact instructor for VPS access

## 🎓 Key Concepts

- **Federated Learning**: Distributed training without sharing raw data
- **FedAvg**: Simple averaging of client model parameters
- **GPU Acceleration**: Numba CUDA kernels for gradient computation
- **Microservices**: Independent, scalable service architecture
- **Privacy-Preserving**: Only model updates shared, not data

## ⚡ Performance Tips

- Monitor GPU usage: `watch nvidia-smi`
- Adjust DATA_SIZE in client.py for faster training
- Use SSD for better I/O performance on VPS
- Ensure good network connectivity between services

---

**Ready to start?** Run `./test_local.sh` for local testing or `./deploy_docker.sh` for Docker deployment!
