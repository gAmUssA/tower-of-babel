"""
Inventory Service for Kafka Schema Registry Demo
"""

import os
import logging
import threading
import time
from contextlib import asynccontextmanager
from typing import Dict, List

# Import dotenv correctly
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Depends, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

from inventory_service.consumer import OrderKafkaConsumer
from inventory_service.consumer.avro_kafka_consumer import AvroOrderKafkaConsumer

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
SCHEMA_REGISTRY_URL = os.getenv('SCHEMA_REGISTRY_URL', 'http://localhost:8081')

# In-memory inventory store (for demo purposes)
inventory_store: Dict[str, Dict] = {}

# Kafka consumer instances
kafka_consumer = None
avro_kafka_consumer = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan event handler for startup and shutdown"""
    global kafka_consumer, avro_kafka_consumer
    
    # Startup
    try:
        logger.info("Starting regular Kafka consumer")
        kafka_consumer = OrderKafkaConsumer(
            bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
            topic=KAFKA_TOPIC,
            group_id=KAFKA_GROUP_ID,
            inventory_store=inventory_store
        )
        kafka_consumer.start()
        logger.info("Regular Kafka consumer started successfully")
        
        # Start Avro Kafka consumer with different group ID to get all messages
        logger.info("Starting Avro Kafka consumer")
        avro_kafka_consumer = AvroOrderKafkaConsumer(
            bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
            topic=KAFKA_TOPIC,
            group_id=f"{KAFKA_GROUP_ID}-avro",
            schema_registry_url=SCHEMA_REGISTRY_URL,
            inventory_store=inventory_store
        )
        avro_kafka_consumer.start()
        logger.info("Avro Kafka consumer started successfully")
    except Exception as e:
        logger.error(f"Failed to start Kafka consumer: {e}")
        # Still allow the app to start even if Kafka consumer fails
    
    yield
    
    # Shutdown
    if kafka_consumer:
        logger.info("Stopping regular Kafka consumer")
        kafka_consumer.stop()
        logger.info("Regular Kafka consumer stopped")
    
    if avro_kafka_consumer:
        logger.info("Stopping Avro Kafka consumer")
        avro_kafka_consumer.stop()
        logger.info("Avro Kafka consumer stopped")


# Create FastAPI app with lifespan
app = FastAPI(
    title="Inventory Service",
    description="Inventory Service for Kafka Schema Registry Demo",
    version="0.1.0",
    lifespan=lifespan
)

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files for dashboard assets
static_path = os.path.join(os.path.dirname(__file__), "..", "src", "public")
if os.path.exists(static_path):
    app.mount("/static", StaticFiles(directory=static_path), name="static")


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

@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "Inventory Service is running"}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    global kafka_consumer, avro_kafka_consumer
    kafka_status = "connected" if kafka_consumer and kafka_consumer.consumer else "disconnected"
    avro_status = "connected" if avro_kafka_consumer and avro_kafka_consumer.consumer else "disconnected"
    return {
        "status": "healthy",
        "kafka": kafka_status,
        "avro_kafka": avro_status,
        "error_count": {
            "json": kafka_consumer.get_error_count() if kafka_consumer else 0,
            "avro": avro_kafka_consumer.get_error_count() if avro_kafka_consumer else 0
        }
    }

@app.get("/inventory/{order_id}")
async def get_inventory_status(order_id: str):
    """Get inventory status for an order"""
    if order_id not in inventory_store:
        raise HTTPException(status_code=404, detail="Order not found")
    return inventory_store[order_id]

@app.get("/inventory")
async def get_all_inventory(source: str = Query(None, description="Filter by source (json, java, avro)")):
    """Get all inventory items with optional filtering by source"""
    if source:
        # Filter inventory items by source
        return [item for item in inventory_store.values() if item.get("source", "") == source]
    return list(inventory_store.values())

@app.get("/errors")
async def get_error_stats():
    """Get error statistics"""
    global kafka_consumer, avro_kafka_consumer
    
    if not kafka_consumer and not avro_kafka_consumer:
        return {"error": "No Kafka consumers started"}
    
    return {
        "json_consumer": {
            "error_count": kafka_consumer.get_error_count() if kafka_consumer else 0,
            "last_errors": kafka_consumer.get_last_errors() if kafka_consumer else []
        },
        "avro_consumer": {
            "error_count": avro_kafka_consumer.get_error_count() if avro_kafka_consumer else 0,
            "last_errors": avro_kafka_consumer.get_last_errors() if avro_kafka_consumer else []
        }
    }

@app.get("/dashboard")
async def serve_dashboard():
    """Serve the inventory dashboard frontend"""
    dashboard_path = os.path.join(os.path.dirname(__file__), "..", "src", "public", "dashboard.html")
    if not os.path.exists(dashboard_path):
        raise HTTPException(status_code=404, detail="Dashboard not found")
    return FileResponse(dashboard_path)

# Run the application with uvicorn when this script is executed directly
if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "inventory_service.main:app",
        host="0.0.0.0",
        port=int(os.getenv("SERVER_PORT", "9000")),
        reload=True,
    )
