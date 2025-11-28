#!/bin/bash

# Distributed FL Client Runner
# Usage: ./run_distributed_client.sh [CLIENT_ID] [AGGREGATOR_URL]

# Default values
DEFAULT_CLIENT_ID="client_$(hostname)_$RANDOM"
DEFAULT_AGGREGATOR_URL="http://REDACTED:8800"

CLIENT_ID=${1:-$DEFAULT_CLIENT_ID}
AGGREGATOR_URL=${2:-$DEFAULT_AGGREGATOR_URL}

echo "=================================================="
echo "Federated Learning Distributed Client"
echo "=================================================="
echo "Client ID:      $CLIENT_ID"
echo "Aggregator URL: $AGGREGATOR_URL"
echo "=================================================="

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed."
    exit 1
fi

# Check for NVIDIA GPU
USE_GPU=false
if command -v nvidia-smi &> /dev/null; then
    echo "✓ NVIDIA GPU detected"
    USE_GPU=true
else
    echo "⚠ No NVIDIA GPU detected. Running in CPU mode (slower)."
fi

# Build the image
echo "Building client image..."
docker build -t fl-client -f Dockerfile.client .

# Run the container
echo "Starting client..."
if [ "$USE_GPU" = true ]; then
    docker run -it --rm \
        --gpus all \
        --network host \
        -e CLIENT_ID="$CLIENT_ID" \
        -e AGGREGATOR_URL="$AGGREGATOR_URL" \
        -e MODE="DISTRIBUTED" \
        fl-client
else
    docker run -it --rm \
        --network host \
        -e CLIENT_ID="$CLIENT_ID" \
        -e AGGREGATOR_URL="$AGGREGATOR_URL" \
        -e MODE="DISTRIBUTED" \
        fl-client
fi
