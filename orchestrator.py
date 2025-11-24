#!/usr/bin/env python3
"""
Federated Learning Orchestrator
Coordinates a complete FL training round across all clients
"""

import httpx
import asyncio
import json
from typing import List, Dict
import sys


# Service endpoints
CLIENT_URLS = [
    "http://localhost:8001",
    "http://localhost:8002",
    "http://localhost:8003"
]
AGGREGATOR_URL = "http://localhost:9000"


async def check_health(client: httpx.AsyncClient, url: str, service_name: str) -> bool:
    """Check if a service is healthy"""
    try:
        response = await client.get(f"{url}/health", timeout=5.0)
        if response.status_code == 200:
            print(f"✓ {service_name} is healthy")
            return True
        else:
            print(f"✗ {service_name} returned status {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ {service_name} is not responding: {e}")
        return False


async def train_client(client: httpx.AsyncClient, url: str, client_id: int) -> Dict:
    """Request training from a single client"""
    try:
        print(f"\n→ Training Client {client_id}...")
        response = await client.post(f"{url}/train", timeout=30.0)
        response.raise_for_status()
        result = response.json()
        print(f"  Client {client_id} results: w={result['w']:.4f}, b={result['b']:.4f}, loss={result['loss']:.4f}")
        return result
    except Exception as e:
        print(f"✗ Client {client_id} training failed: {e}")
        raise


async def aggregate_models(client: httpx.AsyncClient, updates: List[Dict]) -> Dict:
    """Send client updates to aggregator"""
    try:
        print(f"\n→ Aggregating models from {len(updates)} clients...")
        response = await client.post(
            f"{AGGREGATOR_URL}/aggregate",
            json={"updates": updates},
            timeout=10.0
        )
        response.raise_for_status()
        result = response.json()
        return result
    except Exception as e:
        print(f"✗ Aggregation failed: {e}")
        raise


async def run_federated_learning_round():
    """Execute a complete federated learning round"""
    print("="*70)
    print("FEDERATED LEARNING ORCHESTRATOR")
    print("="*70)
    
    async with httpx.AsyncClient() as client:
        # Step 1: Health checks
        print("\n[1/3] Checking service health...")
        all_healthy = True
        
        for idx, url in enumerate(CLIENT_URLS):
            if not await check_health(client, url, f"Client {idx + 1}"):
                all_healthy = False
        
        if not await check_health(client, AGGREGATOR_URL, "Aggregator"):
            all_healthy = False
        
        if not all_healthy:
            print("\n✗ Some services are not healthy. Please check your deployment.")
            sys.exit(1)
        
        print("\n✓ All services are healthy!")
        
        # Step 2: Train all clients
        print("\n[2/3] Training local models...")
        print("-" * 70)
        
        training_tasks = [
            train_client(client, url, idx + 1) 
            for idx, url in enumerate(CLIENT_URLS)
        ]
        
        try:
            client_updates = await asyncio.gather(*training_tasks)
        except Exception as e:
            print(f"\n✗ Training failed: {e}")
            sys.exit(1)
        
        print("\n✓ All clients completed training!")
        
        # Step 3: Aggregate models
        print("\n[3/3] Aggregating models...")
        print("-" * 70)
        
        try:
            global_model = await aggregate_models(client, client_updates)
        except Exception as e:
            print(f"\n✗ Aggregation failed: {e}")
            sys.exit(1)
        
        # Display results
        print("\n" + "="*70)
        print("FEDERATED LEARNING ROUND COMPLETED")
        print("="*70)
        print(f"\nGlobal Model Parameters:")
        print(f"  w = {global_model['global_w']:.4f}")
        print(f"  b = {global_model['global_b']:.4f}")
        print(f"  Average Loss = {global_model['avg_loss']:.4f}")
        print(f"  Number of Clients = {global_model['num_clients']}")
        
        print(f"\nTheoretical Target:")
        print(f"  w = 3.5")
        print(f"  b = 2.0")
        
        print(f"\nError from Target:")
        error_w = abs(global_model['global_w'] - 3.5)
        error_b = abs(global_model['global_b'] - 2.0)
        print(f"  Δw = {error_w:.4f}")
        print(f"  Δb = {error_b:.4f}")
        
        print("\n" + "="*70)
        
        # Save results
        results = {
            "client_updates": client_updates,
            "global_model": global_model
        }
        
        with open("fl_results.json", "w") as f:
            json.dump(results, f, indent=2)
        
        print("\n✓ Results saved to fl_results.json")


if __name__ == "__main__":
    try:
        asyncio.run(run_federated_learning_round())
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        sys.exit(1)
