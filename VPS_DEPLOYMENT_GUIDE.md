# VPS Deployment Guide for Your Specific Setup

## 🎯 VPS Information

- **Host**: `REDACTED`
- **SSH Port**: `2222`
- **Username**: `latis`
- **Password**: `REDACTED`
- **Port Mapping**: Port 8000 on VPS → Port 8800 externally

## 🚀 Quick Deployment (Automated)

### Option 1: Using the Automated Script

```bash
# From your local machine
cd /home/hama/Desktop/TP_Hamza/TP_Federated

# Make script executable
chmod +x deploy_to_vps.sh

# Run deployment
./deploy_to_vps.sh
```

This script will:
1. ✅ Test VPS connection
2. ✅ Transfer all project files
3. ✅ Setup the VPS environment
4. ✅ Install dependencies
5. ✅ Deploy with Docker

## 📝 Manual Deployment Steps

### Step 1: Connect to VPS

```bash
ssh latis@REDACTED -p 2222
# Password: REDACTED
```

### Step 2: Transfer Project Files

**From your local machine** (in a new terminal):

```bash
# Using SCP
scp -P 2222 -r /home/hama/Desktop/TP_Hamza/TP_Federated latis@REDACTED:~/

# Or using rsync (better for updates)
rsync -avz -e "ssh -p 2222" /home/hama/Desktop/TP_Hamza/TP_Federated/ latis@REDACTED:~/TP_Federated/
```

### Step 3: Setup VPS Environment

**On the VPS**:

```bash
cd ~/TP_Federated

# Make scripts executable
chmod +x *.sh

# Run setup script
./setup_vps.sh
```

**Important**: If NVIDIA drivers are newly installed, reboot:

```bash
sudo reboot
```

Wait 2 minutes, then reconnect:

```bash
ssh latis@REDACTED -p 2222
```

### Step 4: Verify GPU

```bash
# Check NVIDIA driver
nvidia-smi

# Check Docker GPU access
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
```

### Step 5: Deploy Services

```bash
cd ~/TP_Federated

# Deploy with Docker
./deploy_docker.sh
```

### Step 6: Verify Services

```bash
# Check running containers
docker compose ps

# Check service health
curl http://localhost:8001/health
curl http://localhost:8002/health
curl http://localhost:8003/health
curl http://localhost:9000/health

# View logs
docker compose logs -f
```

### Step 7: Run Federated Learning

```bash
cd ~/TP_Federated

# Run FL training round
python3 orchestrator.py

# View results
cat fl_results.json
```

## 🔍 Monitoring

### Monitor GPU Usage

```bash
# Real-time GPU monitoring
watch -n 1 nvidia-smi

# Or in a tmux session
tmux new -s gpu-monitor
watch nvidia-smi
# Detach: Ctrl+B, then D
```

### Monitor Docker Containers

```bash
# Container stats
docker stats

# Service logs
docker compose logs -f client1
docker compose logs -f aggregator

# All logs
docker compose logs -f
```

## 🌐 Port Configuration

### Internal Ports (on VPS)

- Client 1: `8001`
- Client 2: `8002`
- Client 3: `8003`
- Aggregator: `9000`

### External Access

If you need to access services from outside the VPS, ensure ports are open:

```bash
# Check firewall status
sudo ufw status

# Allow ports (if needed)
sudo ufw allow 8001/tcp
sudo ufw allow 8002/tcp
sudo ufw allow 8003/tcp
sudo ufw allow 9000/tcp
```

**Note**: According to your setup, port 8000 is mapped to 8800 externally. If you need similar mappings for other ports, configure them in your VPS network settings.

## 🔧 Common Issues & Solutions

### Issue 1: Cannot connect via SSH

```bash
# Test connection
ping REDACTED

# Verify SSH port
nmap REDACTED -p 2222

# Try with verbose output
ssh -v latis@REDACTED -p 2222
```

### Issue 2: Permission denied on docker commands

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in
exit
ssh latis@REDACTED -p 2222

# Verify
docker ps
```

### Issue 3: GPU not detected

```bash
# Check GPU visibility
lspci | grep -i nvidia

# Check NVIDIA driver
nvidia-smi

# If missing, install driver
sudo apt-get install -y nvidia-driver-535
sudo reboot
```

### Issue 4: Out of disk space

```bash
# Check disk usage
df -h

# Clean Docker
docker system prune -a --volumes -f

# Remove old images
docker image prune -a -f
```

### Issue 5: Services won't start

```bash
# Check logs
docker compose logs client1

# Rebuild from scratch
docker compose down
docker compose build --no-cache
docker compose up -d

# Check if ports are in use
sudo netstat -tlnp | grep 8001
```

## 📊 Running Multiple FL Rounds

```bash
cd ~/TP_Federated

# Round 1
python3 orchestrator.py
cp fl_results.json fl_results_round1.json

# Wait a bit
sleep 5

# Round 2
python3 orchestrator.py
cp fl_results.json fl_results_round2.json

# Compare results
diff fl_results_round1.json fl_results_round2.json
```

## 🔐 Using tmux for Persistent Sessions

Recommended for long-running experiments:

```bash
# Install tmux (if not installed)
sudo apt-get install -y tmux

# Create session
tmux new -s federated-learning

# Run your commands
cd ~/TP_Federated
./deploy_docker.sh
python3 orchestrator.py

# Detach from session: Ctrl+B, then D

# List sessions
tmux ls

# Reattach to session
tmux attach -t federated-learning

# Kill session
tmux kill-session -t federated-learning
```

## 📁 Useful Commands

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

### File Management

```bash
# View results
cat fl_results.json | python3 -m json.tool

# Save logs
docker compose logs > deployment_logs.txt

# Backup results
mkdir -p ~/backups
cp fl_results.json ~/backups/fl_results_$(date +%Y%m%d_%H%M%S).json
```

### System Monitoring

```bash
# CPU and Memory
htop

# Disk usage
df -h
du -sh ~/TP_Federated

# Network
netstat -tlnp

# GPU
nvidia-smi
```

## 🎯 Quick Reference Commands

```bash
# Connect to VPS
ssh latis@REDACTED -p 2222

# Navigate to project
cd ~/TP_Federated

# Check services
docker compose ps

# View logs
docker compose logs -f

# Run FL round
python3 orchestrator.py

# Monitor GPU
watch nvidia-smi

# Stop services
docker compose down

# Start services
docker compose up -d
```

## 📞 Troubleshooting Checklist

- [ ] Can connect to VPS via SSH
- [ ] Project files transferred successfully
- [ ] NVIDIA driver installed (`nvidia-smi` works)
- [ ] Docker installed and running
- [ ] NVIDIA Container Toolkit installed
- [ ] Docker GPU test passes
- [ ] All 4 services are healthy
- [ ] Orchestrator runs successfully
- [ ] Results saved to `fl_results.json`
- [ ] GPU utilization visible during training

## 🎓 Next Steps After Deployment

1. **Verify deployment**: Run health checks on all services
2. **Run FL round**: Execute `python3 orchestrator.py`
3. **Monitor GPU**: Watch `nvidia-smi` during training
4. **Save results**: Backup `fl_results.json`
5. **Document**: Take screenshots of successful runs
6. **Experiment**: Try multiple rounds, adjust parameters

## 📝 Notes

- The VPS has port 8000 mapped to 8800 externally
- If you need to expose FL services externally, configure port forwarding
- Always use `tmux` for long-running processes
- Regularly backup your results
- Monitor disk space and clean Docker images periodically

---

**Ready to deploy?** Start with the automated script or follow the manual steps above!
