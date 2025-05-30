"""
Inventory Service for Kafka Schema Registry Demo
"""

import os
from typing import Dict

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# Load environment variables
load_dotenv()

# Create FastAPI app
app = FastAPI(
    title="Inventory Service",
    description="Inventory Service for Kafka Schema Registry Demo",
    version="0.1.0",
)

# In-memory inventory store (for demo purposes)
inventory_store: Dict[str, Dict] = {}


class InventoryStatus(BaseModel):
    """Inventory status response model"""
    order_id: str
    product_id: str
    quantity: int
    status: str


@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "Inventory Service is running"}


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}


@app.get("/inventory/{order_id}")
async def get_inventory_status(order_id: str):
    """Get inventory status for an order"""
    if order_id not in inventory_store:
        raise HTTPException(status_code=404, detail="Order not found")
    return inventory_store[order_id]


if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=int(os.getenv("SERVER_PORT", "9000")),
        reload=True,
    )
