"""
Federated Learning Aggregator Service
Collects local model updates and computes global model via Federated Averaging
Supports both Orchestrator-driven and Distributed (Client-driven) modes.
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import List, Dict, Optional
import numpy as np
import asyncio
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("Aggregator")

app = FastAPI(title="FL Aggregator Service")

# --- Data Models ---

class ClientUpdate(BaseModel):
    """Model update from a single client"""
    client_id: str
    w: float
    b: float
    loss: float

class AggregateRequest(BaseModel):
    """Request containing updates from multiple clients (Orchestrator mode)"""
    updates: List[ClientUpdate]

class GlobalModel(BaseModel):
    """Aggregated global model"""
    round: int
    global_w: float
    global_b: float
    num_clients: int
    client_losses: Dict[str, float]
    avg_loss: float
    status: str = "completed"

class RoundStatus(BaseModel):
    """Current status of the training round"""
    round: int
    status: str  # "waiting", "training", "aggregating", "completed"
    required_clients: int
    connected_clients: int
    submitted_clients: int
    global_w: float
    global_b: float

# --- State Management ---

class AggregatorState:
    def __init__(self):
        self.current_round = 1
        self.status = "waiting"  # waiting, training, completed
        self.global_w = 0.0
        self.global_b = 0.0
        self.updates_buffer: List[ClientUpdate] = []
        self.required_clients = 2  # Minimum clients to aggregate
        self.known_clients = set()
        
    def reset_round(self):
        self.current_round += 1
        self.updates_buffer = []
        self.status = "waiting"
        logger.info(f"Started new round {self.current_round}")

state = AggregatorState()

# --- Core Logic ---

def perform_aggregation(updates: List[ClientUpdate]) -> GlobalModel:
    """Perform FedAvg algorithm"""
    if not updates:
        raise ValueError("No client updates provided")
    
    # Extract parameters
    client_ws = [update.w for update in updates]
    client_bs = [update.b for update in updates]
    client_losses = {update.client_id: update.loss for update in updates}
    
    # Compute global parameters (FedAvg)
    global_w = np.mean(client_ws)
    global_b = np.mean(client_bs)
    avg_loss = np.mean([update.loss for update in updates])
    
    # Update state
    state.global_w = float(global_w)
    state.global_b = float(global_b)
    
    # Log results
    print(f"\n{'='*60}")
    print(f"ROUND {state.current_round} AGGREGATION RESULTS")
    print(f"{'='*60}")
    print(f"Clients: {len(updates)}")
    for update in updates:
        print(f"  Client {update.client_id}: w={update.w:.4f}, b={update.b:.4f}, loss={update.loss:.4f}")
    print(f"\nGlobal Model:")
    print(f"  w = {global_w:.4f}")
    print(f"  b = {global_b:.4f}")
    print(f"  Avg Loss = {avg_loss:.4f}")
    print(f"  Target: w=3.5, b=2.0")
    print(f"{'='*60}\n")
    
    return GlobalModel(
        round=state.current_round,
        global_w=float(global_w),
        global_b=float(global_b),
        num_clients=len(updates),
        client_losses=client_losses,
        avg_loss=float(avg_loss)
    )

# --- Endpoints ---

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "aggregator", "mode": "distributed"}

@app.get("/status", response_model=RoundStatus)
async def get_status():
    """Clients poll this to check if they should train"""
    return RoundStatus(
        round=state.current_round,
        status=state.status,
        required_clients=state.required_clients,
        connected_clients=len(state.known_clients),
        submitted_clients=len(state.updates_buffer),
        global_w=state.global_w,
        global_b=state.global_b
    )

@app.post("/join/{client_id}")
async def join_round(client_id: str):
    """Clients register here"""
    state.known_clients.add(client_id)
    logger.info(f"Client {client_id} joined. Total: {len(state.known_clients)}")
    return {"status": "joined", "round": state.current_round}

@app.post("/submit")
async def submit_update(update: ClientUpdate):
    """Clients submit their training results here"""
    # Check if already submitted
    for existing in state.updates_buffer:
        if existing.client_id == update.client_id:
            return {"status": "already_submitted", "message": "Update updated"}
            
    state.updates_buffer.append(update)
    state.known_clients.add(update.client_id)
    
    logger.info(f"Received update from {update.client_id}. Progress: {len(state.updates_buffer)}/{state.required_clients}")
    
    # Check if we can aggregate
    if len(state.updates_buffer) >= state.required_clients:
        logger.info("Threshold reached. Aggregating...")
        perform_aggregation(state.updates_buffer)
        state.status = "completed"
        
    return {"status": "accepted", "round": state.current_round}

@app.post("/reset")
async def reset_round():
    """Manually start a new round"""
    state.reset_round()
    return {"status": "new_round_started", "round": state.current_round}

# --- Legacy Support (Orchestrator Mode) ---

@app.post("/aggregate", response_model=GlobalModel)
async def aggregate_legacy(request: AggregateRequest):
    """Legacy endpoint for orchestrator-driven flow"""
    return perform_aggregation(request.updates)

if __name__ == "__main__":
    import uvicorn
    print("Starting Distributed Aggregator on port 9000")
    uvicorn.run(app, host="0.0.0.0", port=9000)
