"""
Federated Learning Aggregator Service
Collects local model updates and computes global model via Federated Averaging
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict
import numpy as np

app = FastAPI(title="FL Aggregator Service")


class ClientUpdate(BaseModel):
    """Model update from a single client"""
    client_id: str
    w: float
    b: float
    loss: float


class AggregateRequest(BaseModel):
    """Request containing updates from multiple clients"""
    updates: List[ClientUpdate]


class GlobalModel(BaseModel):
    """Aggregated global model"""
    global_w: float
    global_b: float
    num_clients: int
    client_losses: Dict[str, float]
    avg_loss: float


def federated_averaging(updates: List[ClientUpdate]) -> GlobalModel:
    """
    Perform Federated Averaging (FedAvg) algorithm
    
    Computes the global model as the average of all client models:
    global_w = (1/K) * Σ(client_w_i)
    global_b = (1/K) * Σ(client_b_i)
    
    where K is the number of clients
    
    Args:
        updates: List of client model updates
    
    Returns:
        GlobalModel: Aggregated global model parameters
    """
    if not updates:
        raise ValueError("No client updates provided")
    
    # Extract parameters from all clients
    client_ws = [update.w for update in updates]
    client_bs = [update.b for update in updates]
    client_losses = {update.client_id: update.loss for update in updates}
    
    # Compute global parameters as simple average
    global_w = np.mean(client_ws)
    global_b = np.mean(client_bs)
    avg_loss = np.mean([update.loss for update in updates])
    
    print(f"\n{'='*60}")
    print(f"FEDERATED AVERAGING RESULTS")
    print(f"{'='*60}")
    print(f"Number of clients: {len(updates)}")
    print(f"\nClient Updates:")
    for update in updates:
        print(f"  Client {update.client_id}: w={update.w:.4f}, b={update.b:.4f}, loss={update.loss:.4f}")
    print(f"\nGlobal Model:")
    print(f"  w = {global_w:.4f}")
    print(f"  b = {global_b:.4f}")
    print(f"  Average Loss = {avg_loss:.4f}")
    print(f"\nTheoretical Target: w=3.5, b=2.0")
    print(f"Error: Δw={abs(global_w - 3.5):.4f}, Δb={abs(global_b - 2.0):.4f}")
    print(f"{'='*60}\n")
    
    return GlobalModel(
        global_w=float(global_w),
        global_b=float(global_b),
        num_clients=len(updates),
        client_losses=client_losses,
        avg_loss=float(avg_loss)
    )


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "aggregator"
    }


@app.post("/aggregate", response_model=GlobalModel)
async def aggregate(request: AggregateRequest):
    """
    Aggregate client model updates into a global model
    
    Args:
        request: Contains list of client updates
    
    Returns:
        GlobalModel: Aggregated global model parameters
    """
    try:
        if not request.updates:
            raise HTTPException(status_code=400, detail="No client updates provided")
        
        if len(request.updates) < 2:
            raise HTTPException(
                status_code=400, 
                detail=f"Need at least 2 clients for aggregation, got {len(request.updates)}"
            )
        
        global_model = federated_averaging(request.updates)
        return global_model
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Aggregation failed: {str(e)}")


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "Federated Learning Aggregator",
        "algorithm": "Federated Averaging (FedAvg)",
        "endpoints": {
            "health": "/health",
            "aggregate": "/aggregate (POST)"
        }
    }


if __name__ == "__main__":
    import uvicorn
    print("Starting Aggregator Service on port 9000")
    uvicorn.run(app, host="0.0.0.0", port=9000)
