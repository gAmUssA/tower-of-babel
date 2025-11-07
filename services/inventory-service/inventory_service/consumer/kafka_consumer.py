"""
Kafka consumer for inventory service with intentional JSON deserialization issues
"""

import json
import logging
import threading
from typing import Dict, Any, Optional

from confluent_kafka import Consumer, KafkaError, KafkaException

logger = logging.getLogger(__name__)

class OrderKafkaConsumer:
    """
    Kafka consumer for order events with intentional JSON deserialization issues.
    This consumer will attempt to deserialize messages with field name mismatches.
    """
    
    def __init__(
        self, 
        bootstrap_servers: str, 
        topic: str, 
        group_id: str,
        inventory_store: Dict[str, Dict]
    ):
        self.bootstrap_servers = bootstrap_servers
        self.topic = topic
        self.group_id = group_id
        self.inventory_store = inventory_store
        self.consumer = None
        self.running = False
        self.consumer_thread = None
        self.error_count = 0
        self.last_errors = []
        self.max_errors_to_track = 10
        
    def start(self):
        """Start the Kafka consumer in a separate thread"""
        if self.running:
            logger.warning("Kafka consumer already running")
            return
            
        self.running = True
        self.consumer_thread = threading.Thread(target=self._consume_loop)
        self.consumer_thread.daemon = True
        self.consumer_thread.start()
        logger.info(f"Started Kafka consumer for topic {self.topic}")
        
    def stop(self):
        """Stop the Kafka consumer"""
        self.running = False
        if self.consumer_thread:
            self.consumer_thread.join(timeout=5.0)
            self.consumer_thread = None
        if self.consumer:
            self.consumer.close()
            self.consumer = None
        logger.info("Stopped Kafka consumer")
        
    def _create_consumer(self):
        """Create a new Kafka consumer instance"""
        config = {
            'bootstrap.servers': self.bootstrap_servers,
            'group.id': self.group_id,
            'auto.offset.reset': 'earliest',
            'enable.auto.commit': True,
        }
        return Consumer(config)
        
    def _consume_loop(self):
        """Main consumer loop"""
        try:
            self.consumer = self._create_consumer()
            self.consumer.subscribe([self.topic])
            
            while self.running:
                msg = self.consumer.poll(timeout=1.0)
                
                if msg is None:
                    continue
                    
                if msg.error():
                    if msg.error().code() == KafkaError._PARTITION_EOF:
                        logger.debug(f"Reached end of partition {msg.partition()}")
                    else:
                        logger.error(f"Kafka error: {msg.error()}")
                    continue
                    
                try:
                    self._process_message(msg.value())
                except Exception as e:
                    self.error_count += 1
                    error_msg = str(e)
                    self.last_errors.append(error_msg)
                    # Keep only the last N errors
                    if len(self.last_errors) > self.max_errors_to_track:
                        self.last_errors.pop(0)
                    logger.error(f"Error processing message: {e}")
                    
        except KafkaException as e:
            logger.error(f"Kafka exception: {e}")
        finally:
            if self.consumer:
                self.consumer.close()
                
    def _process_message(self, message_bytes: bytes):
        """
        Process a message from Kafka.
        Intentionally uses different field names than the producer to demonstrate deserialization issues.
        """
        try:
            # Check if this is an Avro message (magic byte 0x00)
            if len(message_bytes) > 0 and message_bytes[0] == 0:
                logger.debug("Received Avro message, skipping in JSON consumer")
                return

            # First try to deserialize as JSON
            try:
                # Attempt to decode as JSON
                message_str = message_bytes.decode('utf-8')
                order_data = json.loads(message_str)
                
                # Intentional field name mismatches for demo purposes
                # The producer uses 'orderId', but we're looking for 'order_id'
                # The producer uses 'userId', but we're looking for 'user_id'
                order_id = self._extract_field(order_data, ['order_id', 'orderId', 'orderid'])
                user_id = self._extract_field(order_data, ['user_id', 'userId', 'userid'])
                
                if not order_id:
                    raise ValueError("Could not find order_id field in message")
                
                # Process items with field name mismatches
                items = self._extract_field(order_data, ['items', 'orderItems', 'order_items'], [])
                
                # Update inventory store
                for item in items:
                    product_id = self._extract_field(item, ['product_id', 'productId', 'productid'])
                    quantity = self._extract_field(item, ['quantity', 'qty', 'amount'])
                    
                    if not product_id or quantity is None:
                        logger.warning(f"Skipping item with missing fields: {item}")
                        continue
                        
                    inventory_entry = {
                        "order_id": order_id,
                        "product_id": product_id,
                        "quantity": quantity,
                        "status": "RESERVED",
                        "user_id": user_id
                    }
                    
                    # Store by order_id for retrieval
                    self.inventory_store[order_id] = inventory_entry
                    logger.info(f"Updated inventory for order {order_id}, product {product_id}")
                
            except (UnicodeDecodeError, json.JSONDecodeError) as e:
                # If JSON deserialization fails, try to handle as Java serialized object
                # This will fail, but we want to show the error for demo purposes
                logger.error(f"Failed to deserialize message as JSON: {e}")
                logger.error("Received a message that appears to be Java serialized - cannot deserialize")
                raise ValueError("Received a message that appears to be Java serialized - cannot deserialize")
                
        except Exception as e:
            logger.error(f"Error processing message: {e}")
            raise
            
    def _extract_field(self, data: Dict[str, Any], possible_names: list, default=None) -> Optional[Any]:
        """
        Try to extract a field from the data using multiple possible field names.
        This is to demonstrate field name mismatch issues.
        """
        for name in possible_names:
            if name in data:
                return data[name]
        return default
        
    def get_error_count(self) -> int:
        """Get the number of errors encountered"""
        return self.error_count
    
    def get_last_errors(self) -> list:
        """Get the list of last error messages"""
        return self.last_errors.copy()
