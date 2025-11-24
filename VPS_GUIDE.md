# VPS Deployment Guide - Complete Walkthrough

This guide provides step-by-step instructions for deploying the Federated Learning lab on a remote VPS with an NVIDIA GPU.

## 📋 Prerequisites

### What You Need

- **VPS with NVIDIA GPU** (e.g., AWS EC2 p3.2xlarge, Google Cloud with GPU, or similar)
- **SSH access** to the VPS
- **Ubuntu 20.04 or 22.04** LTS installed
- **Root or sudo access**
- **Public IP address** for the VPS
- **Minimum specs**: 4GB RAM, 10GB storage, 1 NVIDIA GPU

## 🌐 Step-by-Step Deployment

### Step 1: Obtain VPS Access

Contact your instructor to receive:

- VPS IP address
- SSH credentials (username and password or private key)
- Confirmation that VPS has NVIDIA GPU

Example credentials:

```
IP: 203.0.113.10
User: ubuntu
Key: ~/.ssh/vps_key.pem
```

### Step 2: Connect to VPS via SSH

#### Option A: Using password

```bash
ssh username@your-vps-ip
# Enter password when prompted
```

#### Option B: Using private key

```bash
# Set correct permissions for key
chmod 600 ~/.ssh/vps_key.pem

# Connect
ssh -i ~/.ssh/vps_key.pem username@your-vps-ip
```

#### Verify connection

```bash
# Check OS
cat /etc/os-release

# Check available resources
free -h
df -h

# Check if GPU is visible
lspci | grep -i nvidia
```

### Step 3: Transfer Project to VPS

#### Option A: Using SCP (from your local machine)

```bash
# In a new terminal on your LOCAL machine
cd /home/hama/Desktop/TP_Hamza
scp -r TP_Federated username@your-vps-ip:~/

# Or with private key
scp -i ~/.ssh/vps_key.pem -r TP_Federated username@your-vps-ip:~/
```

#### Option B: Using Git (on VPS)

```bash
# On VPS
cd ~
git clone https://github.com/yourusername/TP_Federated.git
cd TP_Federated
```

#### Option C: Using rsync (recommended for updates)

```bash
# From local machine
rsync -avz -e "ssh -i ~/.ssh/vps_key.pem" \
  /home/hama/Desktop/TP_Hamza/TP_Federated/ \
  username@your-vps-ip:~/TP_Federated/
```

### Step 4: Run Automated VPS Setup

On the VPS, run the automated setup script:

```bash
cd ~/TP_Federated
./setup_vps.sh
```

This script will:

1. ✅ Update system packages
2. ✅ Install/verify NVIDIA drivers
3. ✅ Install Docker
4. ✅ Install Docker Compose
5. ✅ Install NVIDIA Container Toolkit
6. ✅ Install Python dependencies
7. ✅ Configure firewall

**Important**: If NVIDIA drivers are newly installed, you'll need to reboot:

```bash
sudo reboot
```

Then reconnect and run the script again:

```bash
ssh username@your-vps-ip
cd ~/TP_Federated
./setup_vps.sh
```

### Step 5: Verify Setup

After setup completes, verify everything:

```bash
# Check NVIDIA driver
nvidia-smi

# Check Docker
docker --version
docker compose version

# Check Docker GPU access
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi

# Check project files
ls -la ~/TP_Federated/
```

Expected output from `nvidia-smi`:

```
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 535.xx.xx    Driver Version: 535.xx.xx    CUDA Version: 12.2   |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  Tesla V100-SXM2...  Off  | 00000000:00:1E.0 Off |                    0 |
| N/A   32C    P0    25W / 300W |      0MiB / 16384MiB |      0%      Default |
```

### Step 6: Deploy with Docker

```bash
cd ~/TP_Federated
./deploy_docker.sh
```

This will:

1. Build Docker images
2. Start all services
3. Verify service health
4. Run a federated learning round

Monitor the deployment:

```bash
# Watch logs in real-time
docker compose logs -f

# Check service status
docker compose ps

# Monitor GPU usage (in another terminal)
watch -n 1 nvidia-smi
```

### Step 7: Access Services

Services are now running on the VPS. You can access them from:

#### From the VPS itself:

```bash
# Health checks
curl http://localhost:8001/health
curl http://localhost:8002/health
curl http://localhost:8003/health
curl http://localhost:9000/health
```

#### From your local machine (if firewall allows):

```bash
# Replace with your VPS IP
VPS_IP="203.0.113.10"

curl http://$VPS_IP:8001/health
curl http://$VPS_IP:8002/health
curl http://$VPS_IP:8003/health
curl http://$VPS_IP:9000/health
```

#### Interactive API documentation:

Open in your browser (replace with your VPS IP):

- http://203.0.113.10:8001/docs (Client 1)
- http://203.0.113.10:8002/docs (Client 2)
- http://203.0.113.10:8003/docs (Client 3)
- http://203.0.113.10:9000/docs (Aggregator)

### Step 8: Run Federated Learning

On the VPS:

```bash
cd ~/TP_Federated
python3 orchestrator.py
```

You should see output like:

```
======================================================================
FEDERATED LEARNING ORCHESTRATOR
======================================================================

[1/3] Checking service health...
✓ Client 1 is healthy
✓ Client 2 is healthy
✓ Client 3 is healthy
✓ Aggregator is healthy

[2/3] Training local models...
→ Training Client 1...
  Client 1 results: w=3.4892, b=1.9951, loss=0.0123
...

Global Model:
  w = 3.4999
  b = 2.0006
  Average Loss = 0.0121
```

Results are saved to `fl_results.json`:

```bash
cat fl_results.json
```

### Step 9: Monitor GPU Usage

Open a separate SSH session and monitor GPU:

```bash
ssh username@your-vps-ip
watch -n 1 nvidia-smi
```

You should see GPU utilization increase during training.

## 🔒 Security Configuration

### Firewall Setup

The setup script configures UFW. Verify:

```bash
sudo ufw status
```

Should show:

```
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
8001/tcp                   ALLOW       Anywhere                   # FL Client 1
8002/tcp                   ALLOW       Anywhere                   # FL Client 2
8003/tcp                   ALLOW       Anywhere                   # FL Client 3
9000/tcp                   ALLOW       Anywhere                   # FL Aggregator
```

### Restrict Access (Optional)

For production, restrict access to specific IPs:

```bash
# Remove open rules
sudo ufw delete allow 8001/tcp
sudo ufw delete allow 8002/tcp
sudo ufw delete allow 8003/tcp
sudo ufw delete allow 9000/tcp

# Add IP-restricted rules (replace with your IP)
sudo ufw allow from YOUR_IP to any port 8001
sudo ufw allow from YOUR_IP to any port 8002
sudo ufw allow from YOUR_IP to any port 8003
sudo ufw allow from YOUR_IP to any port 9000

sudo ufw reload
```

## 🔧 Common VPS Issues & Solutions

### Issue 1: Cannot connect via SSH

**Solution:**

```bash
# Check if VPS is running
ping your-vps-ip

# Verify SSH port
nmap your-vps-ip -p 22

# Check firewall on VPS (if you have console access)
sudo ufw allow ssh
sudo ufw enable
```

### Issue 2: Permission denied on docker commands

**Solution:**

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in
exit
ssh username@your-vps-ip

# Verify
docker ps
```

### Issue 3: GPU not detected

**Solution:**

```bash
# Check if GPU is visible to system
lspci | grep -i nvidia

# Check NVIDIA driver
nvidia-smi

# If driver missing, install
sudo apt-get install -y nvidia-driver-535
sudo reboot
```

### Issue 4: Out of disk space

**Solution:**

```bash
# Check disk usage
df -h

# Clean up Docker
docker system prune -a --volumes -f

# Remove old images
docker image prune -a -f
```

### Issue 5: Service won't start

**Solution:**

```bash
# Check logs
docker compose logs client1

# Rebuild
docker compose down
docker compose build --no-cache
docker compose up -d

# Check if port is in use
sudo netstat -tlnp | grep 8001
```

## 📊 Performance Monitoring

### Monitor Resources

```bash
# CPU and Memory
htop

# Disk I/O
iotop

# Network
iftop

# GPU (continuous)
nvidia-smi dmon
```

### Docker Statistics

```bash
# Real-time container stats
docker stats

# Specific container
docker stats fl_client1
```

### Log Analysis

```bash
# View logs
docker compose logs -f client1

# Search for errors
docker compose logs | grep -i error

# Save logs to file
docker compose logs > deployment.log
```

## 🔄 Restarting Services

### Restart individual service

```bash
docker compose restart client1
```

### Restart all services

```bash
docker compose restart
```

### Full rebuild

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

## 🧹 Cleanup

### Stop services

```bash
docker compose down
```

### Remove everything

```bash
# Remove containers and images
docker compose down --rmi all --volumes

# Clean Docker system
docker system prune -a --volumes -f
```

### Remove project

```bash
cd ~
rm -rf TP_Federated
```

## 📈 Running Multiple FL Rounds

To run multiple rounds manually:

```bash
# Round 1
python3 orchestrator.py

# Wait a bit
sleep 5

# Round 2
python3 orchestrator.py

# Compare results
cat fl_results.json
```

## 🔐 Best Practices for VPS

1. **Always use SSH keys** instead of passwords
2. **Keep system updated**: `sudo apt-get update && sudo apt-get upgrade`
3. **Monitor resource usage** to avoid overloading
4. **Set up automatic backups** of results
5. **Use tmux or screen** for long-running processes
6. **Document any changes** you make
7. **Clean up unused Docker resources** regularly

## 📝 Using tmux for Persistent Sessions

Recommended for long-running experiments:

```bash
# Install tmux
sudo apt-get install -y tmux

# Start tmux session
tmux new -s fl

# Run your commands
cd ~/TP_Federated
./deploy_docker.sh

# Detach from session: Ctrl+B, then D

# Reattach later
tmux attach -t fl

# List sessions
tmux ls
```

## 🎯 Checklist for Successful Deployment

- [ ] VPS with NVIDIA GPU provisioned
- [ ] SSH access configured
- [ ] Project transferred to VPS
- [ ] `setup_vps.sh` completed successfully
- [ ] `nvidia-smi` shows GPU
- [ ] Docker GPU test passes
- [ ] `deploy_docker.sh` completes without errors
- [ ] All 4 services are healthy
- [ ] `orchestrator.py` runs successfully
- [ ] Results saved to `fl_results.json`
- [ ] GPU utilization visible in `nvidia-smi`

## 📞 Support

If you encounter issues:

1. **Check logs**: `docker compose logs -f`
2. **Verify GPU**: `nvidia-smi`
3. **Test connectivity**: `curl http://localhost:8001/health`
4. **Review this guide** for common solutions
5. **Contact instructor** for VPS-specific issues

## 🎓 After Completion

Once your lab is complete:

1. Save your results: `cp fl_results.json fl_results_backup.json`
2. Take screenshots of successful deployment
3. Note the final global model parameters
4. Document any interesting observations
5. Stop services: `docker compose down`
6. Push code to GitHub for submission

---

**Good luck with your VPS deployment!** 🚀
