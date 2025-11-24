"""
Federated Learning Client Service
Implements local training with Numba CUDA GPU acceleration
"""

import os
import numpy as np
from numba import cuda
import math
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict
import sys

app = FastAPI(title="FL Client Service")

# Client configuration
CLIENT_ID = os.getenv("CLIENT_ID", "1")
PORT = int(os.getenv("PORT", "8001"))

# Training hyperparameters
LEARNING_RATE = 0.01
EPOCHS = 100
DATA_SIZE = 1000

# True model parameters (for synthetic data generation)
TRUE_W = 3.5
TRUE_B = 2.0


class ModelWeights(BaseModel):
    """Model weights response"""
    client_id: str
    w: float
    b: float
    loss: float


@cuda.jit
def compute_gradients_kernel(x, y, w, b, grad_w, grad_b, n):
    """
    CUDA kernel to compute gradients for linear regression
    
    Each thread computes partial gradients for one data point:
    - prediction: y_pred = w * x + b
    - error: err = y_pred - y
    - gradient_w: err * x
    - gradient_b: err
    
    Uses atomic operations to safely accumulate gradients across threads
    """
    idx = cuda.grid(1)
    
    if idx < n:
        # Compute prediction for this data point
        y_pred = w[0] * x[idx] + b[0]
        
        # Compute error
        error = y_pred - y[idx]
        
        # Compute local gradients
        local_grad_w = error * x[idx]
        local_grad_b = error
        
        # Atomic add to accumulate gradients safely across threads
        cuda.atomic.add(grad_w, 0, local_grad_w)
        cuda.atomic.add(grad_b, 0, local_grad_b)


def generate_synthetic_data(n: int, seed: int = None):
    """
    Generate synthetic data for linear regression: y = TRUE_W * x + TRUE_B + noise
    
    Args:
        n: Number of data points
        seed: Random seed for reproducibility
    
    Returns:
        x, y: Input and target arrays
    """
    if seed is not None:
        np.random.seed(seed)
    
    # Generate random x values
    x = np.random.randn(n).astype(np.float32)
    
    # Generate y with linear relationship + Gaussian noise
    noise = np.random.randn(n).astype(np.float32) * 0.1
    y = TRUE_W * x + TRUE_B + noise
    
    return x, y


def train_local_model():
    """
    Train a linear regression model locally using GPU acceleration
    
    Returns:
        Dict with trained weights (w, b) and final loss
    """
    # Check if CUDA is available
    try:
        cuda_available = cuda.is_available()
        print(f"CUDA available: {cuda_available}")
        if cuda_available:
            print(f"CUDA devices: {cuda.gpus}")
    except Exception as e:
        print(f"CUDA check failed: {e}")
        cuda_available = False
    
    # Generate synthetic data (each client gets different seed)
    seed = int(CLIENT_ID) * 42
    x, y = generate_synthetic_data(DATA_SIZE, seed=seed)
    
    # Initialize model parameters
    w = np.array([0.0], dtype=np.float32)
    b = np.array([0.0], dtype=np.float32)
    
    n = len(x)
    
    if cuda_available:
        # GPU training
        print("Training on GPU...")
        
        # Transfer data to GPU
        x_device = cuda.to_device(x)
        y_device = cuda.to_device(y)
        w_device = cuda.to_device(w)
        b_device = cuda.to_device(b)
        
        # Configure CUDA kernel launch parameters
        threads_per_block = 256
        blocks_per_grid = (n + threads_per_block - 1) // threads_per_block
        
        # Training loop
        for epoch in range(EPOCHS):
            # Initialize gradient accumulators on GPU
            grad_w_device = cuda.to_device(np.array([0.0], dtype=np.float32))
            grad_b_device = cuda.to_device(np.array([0.0], dtype=np.float32))
            
            # Launch kernel to compute gradients
            compute_gradients_kernel[blocks_per_grid, threads_per_block](
                x_device, y_device, w_device, b_device, 
                grad_w_device, grad_b_device, n
            )
            
            # Copy gradients back to CPU
            grad_w = grad_w_device.copy_to_host()
            grad_b = grad_b_device.copy_to_host()
            
            # Average gradients
            grad_w[0] /= n
            grad_b[0] /= n
            
            # Update parameters on CPU
            w[0] -= LEARNING_RATE * grad_w[0]
            b[0] -= LEARNING_RATE * grad_b[0]
            
            # Copy updated parameters back to GPU
            w_device = cuda.to_device(w)
            b_device = cuda.to_device(b)
            
            if (epoch + 1) % 20 == 0:
                print(f"Epoch {epoch + 1}/{EPOCHS}, w={w[0]:.4f}, b={b[0]:.4f}")
        
        # Copy final parameters back
        w = w_device.copy_to_host()
        b = b_device.copy_to_host()
        
    else:
        # CPU fallback training
        print("CUDA not available. Training on CPU...")
        
        for epoch in range(EPOCHS):
            # Compute predictions
            y_pred = w[0] * x + b[0]
            
            # Compute errors
            errors = y_pred - y
            
            # Compute gradients (vectorized)
            grad_w = np.mean(errors * x)
            grad_b = np.mean(errors)
            
            # Update parameters
            w[0] -= LEARNING_RATE * grad_w
            b[0] -= LEARNING_RATE * grad_b
            
            if (epoch + 1) % 20 == 0:
                print(f"Epoch {epoch + 1}/{EPOCHS}, w={w[0]:.4f}, b={b[0]:.4f}")
    
    # Compute final loss (MSE)
    y_pred = w[0] * x + b[0]
    loss = np.mean((y_pred - y) ** 2)
    
    print(f"Client {CLIENT_ID} training complete: w={w[0]:.4f}, b={b[0]:.4f}, loss={loss:.4f}")
    print(f"Target values: w={TRUE_W}, b={TRUE_B}")
    
    return {
        "client_id": CLIENT_ID,
        "w": float(w[0]),
        "b": float(b[0]),
        "loss": float(loss)
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "client_id": CLIENT_ID,
        "cuda_available": cuda.is_available()
    }


@app.post("/train", response_model=ModelWeights)
async def train():
    """
    Train local model and return weights
    
    Returns:
        ModelWeights: Trained model parameters
    """
    try:
        result = train_local_model()
        return ModelWeights(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Training failed: {str(e)}")


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "Federated Learning Client",
        "client_id": CLIENT_ID,
        "endpoints": {
            "health": "/health",
            "train": "/train (POST)"
        }
    }


if __name__ == "__main__":
    import uvicorn
    print(f"Starting Client {CLIENT_ID} on port {PORT}")
    uvicorn.run(app, host="0.0.0.0", port=PORT)
