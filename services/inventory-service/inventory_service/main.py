"""
Inventory Service for Kafka Schema Registry Demo
"""

import os
import logging
import threading
import time
from typing import Dict, List

import os
# Import dotenv correctly
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from inventory_service.consumer import OrderKafkaConsumer

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Get environment variables
KAFKA_BOOTSTRAP_SERVERS = os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'localhost:29092')
KAFKA_TOPIC = os.getenv('KAFKA_TOPIC', 'orders')
KAFKA_GROUP_ID = os.getenv('KAFKA_GROUP_ID', 'inventory-service')

# Create FastAPI app
app = FastAPI(
    title="Inventory Service",
    description="Inventory Service for Kafka Schema Registry Demo",
    version="0.1.0",
)

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory inventory store (for demo purposes)
inventory_store: Dict[str, Dict] = {}

# Kafka consumer instance
kafka_consumer = None

class InventoryStatus(BaseModel):
    """Inventory status response model"""
    order_id: str
    product_id: str
    quantity: int
    status: str
    user_id: str = ""

class ErrorStats(BaseModel):
    """Error statistics response model"""
    error_count: int
    last_errors: List[str] = []

# Error tracking
last_errors: List[str] = []
max_errors_to_track = 10

@app.on_event("startup")
async def startup_event():
    """Start Kafka consumer on application startup"""
    global kafka_consumer
    try:
        logger.info("Starting Kafka consumer")
        kafka_consumer = OrderKafkaConsumer(
            bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
            topic=KAFKA_TOPIC,
            group_id=KAFKA_GROUP_ID,
            inventory_store=inventory_store
        )
        kafka_consumer.start()
        logger.info("Kafka consumer started successfully")
    except Exception as e:
        logger.error(f"Failed to start Kafka consumer: {e}")
        # Still allow the app to start even if Kafka consumer fails

@app.on_event("shutdown")
async def shutdown_event():
    """Stop Kafka consumer on application shutdown"""
    global kafka_consumer
    if kafka_consumer:
        logger.info("Stopping Kafka consumer")
        kafka_consumer.stop()
        logger.info("Kafka consumer stopped")

@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "Inventory Service is running"}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    global kafka_consumer
    kafka_status = "connected" if kafka_consumer and kafka_consumer.consumer else "disconnected"
    return {
        "status": "healthy",
        "kafka": kafka_status,
        "error_count": kafka_consumer.get_error_count() if kafka_consumer else 0
    }

@app.get("/inventory/{order_id}")
async def get_inventory_status(order_id: str):
    """Get inventory status for an order"""
    if order_id not in inventory_store:
        raise HTTPException(status_code=404, detail="Order not found")
    return inventory_store[order_id]

@app.get("/inventory")
async def get_all_inventory():
    """Get all inventory items"""
    return list(inventory_store.values())

@app.get("/errors")
async def get_error_stats():
    """Get error statistics"""
    global kafka_consumer
    if not kafka_consumer:
        return ErrorStats(error_count=0, last_errors=["Kafka consumer not started"])
    
    return ErrorStats(
        error_count=kafka_consumer.get_error_count(),
        last_errors=last_errors
    )

# Run the application with uvicorn when this script is executed directly
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("inventory_service.main:app", host="0.0.0.0", port=9000, reload=True)


if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=int(os.getenv("SERVER_PORT", "9000")),
        reload=True,
    )
