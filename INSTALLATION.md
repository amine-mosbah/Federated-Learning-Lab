# Installation Requirements & Setup Guide

## 📦 What You Need to Download/Install

### For Local Development & Testing

#### 1. Python 3.8 or higher

```bash
# Check if installed
python3 --version

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install python3 python3-pip python3-venv

# macOS (with Homebrew)
brew install python@3.10

# Windows
# Download from https://www.python.org/downloads/
```

#### 2. Python Packages (auto-installed from requirements.txt)

```bash
pip install -r requirements.txt
```

The requirements.txt includes:

- `fastapi` - Web framework for APIs
- `uvicorn` - ASGI server
- `numpy` - Numerical computing
- `numba` - JIT compiler with CUDA support
- `pydantic` - Data validation
- `httpx` - HTTP client

#### 3. NVIDIA GPU Drivers (for GPU acceleration)

```bash
# Check if installed
nvidia-smi

# Ubuntu/Debian - Install latest driver
sudo apt-get update
sudo apt-get install nvidia-driver-535

# After installation, reboot
sudo reboot

# Verify installation
nvidia-smi
```

**Note**: If you don't have an NVIDIA GPU, the code will automatically fall back to CPU mode.

### For Docker Deployment

#### 4. Docker

```bash
# Check if installed
docker --version

# Install on Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install on macOS
# Download Docker Desktop from https://www.docker.com/products/docker-desktop

# Install on Windows
# Download Docker Desktop from https://www.docker.com/products/docker-desktop

# Verify installation
docker run hello-world
```

#### 5. Docker Compose v2+

```bash
# Check if installed
docker compose version

# Usually included with Docker Desktop
# For Linux, install docker-compose-plugin
sudo apt-get update
sudo apt-get install docker-compose-plugin

# Verify
docker compose version
```

#### 6. NVIDIA Container Toolkit (for Docker GPU support)

```bash
# Ubuntu/Debian only - needed for GPU in Docker

# Add repository
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install
sudo apt-get update
sudo apt-get install -y nvidia-docker2

# Restart Docker
sudo systemctl restart docker

# Test GPU access in Docker
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
```

### For VPS Deployment

All of the above, plus:

#### 7. SSH Client

```bash
# Usually pre-installed on Linux/macOS
ssh -V

# Windows - Use built-in OpenSSH or download PuTTY
# https://www.putty.org/
```

#### 8. Git (optional, for code transfer)

```bash
# Check if installed
git --version

# Ubuntu/Debian
sudo apt-get install git

# macOS
brew install git

# Windows
# Download from https://git-scm.com/download/win
```

## ✅ Installation Checklist

Before starting the lab, verify you have:

### Minimum Requirements

- [ ] Python 3.8+ installed
- [ ] pip package manager working
- [ ] Internet connection for downloading packages

### For GPU Acceleration (Recommended)

- [ ] NVIDIA GPU available
- [ ] NVIDIA drivers installed (`nvidia-smi` works)
- [ ] CUDA Toolkit (installed with drivers or separately)

### For Docker Deployment

- [ ] Docker installed and running
- [ ] Docker Compose v2+ installed
- [ ] (Optional) NVIDIA Container Toolkit for GPU in Docker

### For VPS Deployment

- [ ] VPS with Ubuntu 20.04/22.04
- [ ] VPS has NVIDIA GPU
- [ ] SSH access to VPS
- [ ] All of the above installed on VPS

## 🚀 Quick Installation Commands

### Ubuntu 20.04/22.04 - Complete Setup

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Python and tools
sudo apt-get install -y python3 python3-pip python3-venv git curl

# Install NVIDIA drivers
sudo apt-get install -y nvidia-driver-535
sudo reboot

# After reboot: Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose plugin
sudo apt-get install -y docker-compose-plugin

# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker

# Clone project
cd ~
git clone <your-repo-url> TP_Federated
cd TP_Federated

# Install Python dependencies
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Test GPU in Docker
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
```

### macOS - Local Development

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Python
brew install python@3.10

# Install Docker Desktop
# Download from https://www.docker.com/products/docker-desktop

# Clone project
cd ~/Desktop
git clone <your-repo-url> TP_Federated
cd TP_Federated

# Install Python dependencies
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**Note**: GPU acceleration requires NVIDIA GPU, which is not available on Mac. The code will run in CPU mode.

## 🔍 Verification Steps

After installation, verify everything works:

```bash
# 1. Check Python
python3 --version
# Expected: Python 3.8.x or higher

# 2. Check pip
pip3 --version
# Expected: pip 20.x or higher

# 3. Check GPU (if available)
nvidia-smi
# Expected: Shows GPU info and driver version

# 4. Check Docker
docker --version
docker compose version
# Expected: Docker 20.x+, Compose v2.x+

# 5. Check GPU in Docker (if applicable)
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
# Expected: Shows GPU info from inside container

# 6. Check Python packages
cd TP_Federated
python3 -c "import fastapi, numpy, numba; print('All packages OK')"
# Expected: "All packages OK"

# 7. Check CUDA in Python (if GPU available)
python3 -c "from numba import cuda; print('CUDA available:', cuda.is_available())"
# Expected: "CUDA available: True" (or False if no GPU)
```

## 🐛 Common Installation Issues

### Issue: Python not found

```bash
# Try python instead of python3
python --version

# Or install Python 3
sudo apt-get install python3
```

### Issue: pip not found

```bash
# Install pip
sudo apt-get install python3-pip

# Or use python -m pip
python3 -m pip --version
```

### Issue: nvidia-smi not found

```bash
# Check if NVIDIA GPU exists
lspci | grep -i nvidia

# If GPU exists, install drivers
sudo apt-get install nvidia-driver-535
sudo reboot
```

### Issue: Permission denied for docker

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or run
newgrp docker

# Test
docker ps
```

### Issue: Cannot install numba with CUDA

```bash
# Numba will work without CUDA (CPU only)
# For CUDA support, ensure:
# 1. NVIDIA drivers installed
# 2. CUDA toolkit installed
# 3. Compatible versions

# Check CUDA version
nvcc --version

# If needed, install CUDA toolkit
# https://developer.nvidia.com/cuda-downloads
```

## 📚 Additional Resources

- **Python**: https://www.python.org/
- **Docker**: https://docs.docker.com/
- **NVIDIA Drivers**: https://www.nvidia.com/Download/index.aspx
- **CUDA Toolkit**: https://developer.nvidia.com/cuda-downloads
- **Numba**: https://numba.pydata.org/
- **FastAPI**: https://fastapi.tiangolo.com/

## 🎯 What to Install for Different Scenarios

### Scenario 1: Testing locally without GPU

```bash
# Minimal installation
- Python 3.8+
- pip install -r requirements.txt
```

### Scenario 2: Testing locally with GPU

```bash
# Full local installation
- Python 3.8+
- NVIDIA drivers
- pip install -r requirements.txt
```

### Scenario 3: Docker deployment with GPU

```bash
# Docker + GPU
- Docker + Docker Compose
- NVIDIA drivers
- NVIDIA Container Toolkit
- pip install httpx (for orchestrator)
```

### Scenario 4: VPS deployment

```bash
# Complete setup
- All of the above on VPS
- SSH access
- Firewall configuration (UFW)
```

## ⏱️ Estimated Installation Times

- Python packages: 2-5 minutes
- NVIDIA drivers: 5-10 minutes (+ reboot)
- Docker: 5-10 minutes
- NVIDIA Container Toolkit: 5-10 minutes
- **Total**: ~30-45 minutes for complete setup

## 💡 Pro Tips

1. **Use virtual environments** for Python to avoid conflicts
2. **Check versions** - newer isn't always better
3. **Reboot after driver installation** is usually required
4. **Test GPU access** before deploying
5. **Use the automated scripts** (setup_vps.sh) when possible
6. **Keep documentation handy** for troubleshooting

---

**Ready to install?** Start with `python3 --version` and work through the checklist! 🚀
