# 🚀 Quick VPS Deployment Reference Card

## 📋 VPS Credentials
```
Host: REDACTED
Port: 2222
User: latis
Pass: REDACTED
```

## ⚡ Quick Deploy (Choose One)

### Option A: Automated Deployment (Recommended)
```bash
cd /home/hama/Desktop/TP_Hamza/TP_Federated
./deploy_to_vps.sh
```

### Option B: Manual Deployment
```bash
# 1. Transfer files
scp -P 2222 -r /home/hama/Desktop/TP_Hamza/TP_Federated latis@REDACTED:~/

# 2. Connect to VPS
ssh latis@REDACTED -p 2222

# 3. Setup and deploy
cd ~/TP_Federated
./setup_vps.sh
./deploy_docker.sh

# 4. Run FL training
python3 orchestrator.py
```

## 🔍 Essential Commands (On VPS)

### Connect
```bash
ssh latis@REDACTED -p 2222
```

### Check Services
```bash
docker compose ps
curl http://localhost:8001/health
curl http://localhost:8002/health
curl http://localhost:8003/health
curl http://localhost:9000/health
```

### Run Training
```bash
cd ~/TP_Federated
python3 orchestrator.py
cat fl_results.json
```

### Monitor
```bash
# GPU usage
watch -n 1 nvidia-smi

# Container logs
docker compose logs -f

# Container stats
docker stats
```

### Manage Services
```bash
# Start
docker compose up -d

# Stop
docker compose down

# Restart
docker compose restart

# Rebuild
docker compose down
docker compose build --no-cache
docker compose up -d
```

## 🐛 Quick Fixes

### GPU not working?
```bash
nvidia-smi
sudo reboot
```

### Docker permission error?
```bash
sudo usermod -aG docker $USER
exit
# Reconnect
```

### Port in use?
```bash
sudo netstat -tlnp | grep 8001
docker compose down
docker compose up -d
```

### Out of space?
```bash
docker system prune -a --volumes -f
```

## 📊 Service Ports

| Service    | Port | URL                          |
|------------|------|------------------------------|
| Client 1   | 8001 | http://localhost:8001/health |
| Client 2   | 8002 | http://localhost:8002/health |
| Client 3   | 8003 | http://localhost:8003/health |
| Aggregator | 9000 | http://localhost:9000/health |

## 🎯 Expected Output

After running `python3 orchestrator.py`:
```
Global Model:
  w = 3.4999
  b = 2.0006
  Average Loss = 0.0121

Theoretical Target: w=3.5, b=2.0
Error: Δw=0.0001, Δb=0.0006
```

## 📝 Useful File Locations

- Project: `~/TP_Federated`
- Results: `~/TP_Federated/fl_results.json`
- Logs: `docker compose logs`

## 🔐 Using tmux (Recommended)

```bash
# Create session
tmux new -s fl

# Detach: Ctrl+B, then D

# Reattach
tmux attach -t fl

# List sessions
tmux ls
```

---

**Need help?** Check `VPS_DEPLOYMENT_GUIDE.md` for detailed instructions.
