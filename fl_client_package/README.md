# Federated Learning Client

This package allows you to run a Federated Learning client that connects to the central Aggregator on the VPS.

## 📋 Prerequisites

1.  **Docker** must be installed and running.
2.  (Optional) **NVIDIA GPU** with drivers for accelerated training.

## 🚀 How to Run

1.  Open a terminal in this folder.
2.  Run the start script:

```bash
# Make executable (first time only)
chmod +x run_distributed_client.sh

# Run the client
./run_distributed_client.sh
```

That's it! The client will:
1.  Build the Docker image automatically.
2.  Connect to the VPS Aggregator.
3.  Wait for the training round to start.
4.  Train the model and submit results.

## ⚙️ Advanced Usage

You can customize the Client ID or Aggregator URL if needed:

```bash
# Custom Client ID
./run_distributed_client.sh professor_pc

# Custom Aggregator URL (Default is http://REDACTED:8800)
./run_distributed_client.sh professor_pc http://REDACTED:8800
```
