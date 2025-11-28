# Distributed Federated Learning Guide

This guide explains how to run the Federated Learning Client on different machines (e.g., your PC, your professor's PC) while connecting to the central Aggregator on the VPS.

## 1. Prerequisites

- **Docker** installed on the machine.
- **NVIDIA GPU** (optional but recommended) with drivers installed.
- Internet connection to reach the VPS.

## 2. Setup the Aggregator (VPS Side)

Ensure the Aggregator is running on the VPS in Distributed Mode (the updated code supports this automatically).

```bash
# On VPS
cd ~/TP_Federated
./deploy_docker.sh
```

## 3. Run the Client (Your PC / Professor's PC)

### Option A: Using the Script (Recommended)

1. Copy the `TP_Federated` folder (or just `client.py`, `Dockerfile.client`, `requirements.txt`, and `run_distributed_client.sh`) to the target machine.
2. Run the script:

```bash
# Basic usage (uses default VPS URL)
./run_distributed_client.sh

# Custom Client ID
./run_distributed_client.sh my_custom_id

# Custom URL (if port is different, e.g., 8800)
./run_distributed_client.sh professor_pc http://REDACTED:8800
```

### Option B: Manual Docker Run

```bash
# Build
docker build -t fl-client -f Dockerfile.client .

# Run (with GPU)
docker run -it --rm \
  --gpus all \
  --network host \
  -e CLIENT_ID="professor_client" \
  -e AGGREGATOR_URL="http://REDACTED:9000" \
  -e MODE="DISTRIBUTED" \
  fl-client
```

## 4. How it Works

1. The Client connects to the Aggregator (`/join`).
2. It polls for the current round status (`/status`).
3. When a new round starts (status="waiting"), it trains locally.
4. It submits the model update (`/submit`).
5. The Aggregator waits for enough clients (default: 2) to submit, then aggregates.

## 5. Troubleshooting

- **Connection Refused**: Check if the VPS firewall allows port 9000 (or 8800).
- **No GPU**: The script automatically falls back to CPU mode.
