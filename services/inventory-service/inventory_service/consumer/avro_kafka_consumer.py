"""
Kafka consumer for inventory service using Avro deserialization with Schema Registry
"""

import io
import json
import logging
import threading
import avro.schema
import avro.io
import requests
from typing import Dict, Any, Optional

from confluent_kafka import Consumer, KafkaError, KafkaException

logger = logging.getLogger(__name__)


class AvroOrderKafkaConsumer:
    """
    Kafka consumer for order events using Avro deserialization with Schema Registry.
    This consumer properly deserializes messages using the schema from Schema Registry.
    """
    
    def __init__(
        self, 
        bootstrap_servers: str, 
        topic: str, 
        group_id: str,
        schema_registry_url: str,
        inventory_store: Dict[str, Dict]
    ):
        self.bootstrap_servers = bootstrap_servers
        self.topic = topic
        self.group_id = group_id
        self.schema_registry_url = schema_registry_url
        self.inventory_store = inventory_store
        self.consumer = None
        self.running = False
        self.consumer_thread = None
        self.error_count = 0
        self.last_errors = []
        self.max_errors_to_track = 10
        self.schema_cache = {}
        
    def start(self):
        """Start the Kafka consumer in a separate thread"""
        if self.running:
            logger.warning("Kafka consumer already running")
            return
            
        self.running = True
        self.consumer_thread = threading.Thread(target=self._consume_loop)
        self.consumer_thread.daemon = True
        self.consumer_thread.start()
        logger.info(f"Started Avro Kafka consumer for topic {self.topic}")
        
    def stop(self):
        """Stop the Kafka consumer"""
        self.running = False
        if self.consumer_thread:
            self.consumer_thread.join(timeout=5.0)
            self.consumer_thread = None
        if self.consumer:
            self.consumer.close()
            self.consumer = None
        logger.info("Stopped Avro Kafka consumer")
        
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
        Process an Avro message from Kafka using Schema Registry.
        """
        try:
            # Avro messages from Confluent Schema Registry have a magic byte and schema ID prefix
            if len(message_bytes) <= 5:
                raise ValueError("Message too short to contain Avro data")
                
            # Check magic byte (should be 0)
            magic_byte = message_bytes[0]
            if magic_byte != 0:
                logger.debug(f"Received non-Avro message (magic byte: {magic_byte}), skipping")
                return
                
            # Extract schema ID (4 bytes after magic byte)
            schema_id = int.from_bytes(message_bytes[1:5], byteorder='big')
            
            # Get the actual message content (everything after the header)
            message_content = message_bytes[5:]
            
            # Fetch schema from Schema Registry or cache
            schema = self._get_schema(schema_id)
            
            # Deserialize message using Avro and schema
            reader = avro.io.DatumReader(schema)
            bytes_reader = io.BytesIO(message_content)
            decoder = avro.io.BinaryDecoder(bytes_reader)
            order_data = reader.read(decoder)
            
            # Now process the properly deserialized data
            order_id = order_data.get('orderId')
            user_id = order_data.get('userId')
            amount = order_data.get('amount')
            status = order_data.get('status')
            
            if not order_id:
                raise ValueError("Missing orderId field in Avro message")
                
            # For the demo, store the order information with consistent field names
            # Note: Avro schema doesn't have product_id or quantity, so we use placeholders
            inventory_entry = {
                "order_id": order_id,
                "user_id": user_id,
                "product_id": f"avro-order-{order_id[:8]}",  # Generate a placeholder product_id
                "quantity": int(amount) if amount else 1,  # Convert amount to quantity (simplified)
                "status": status if status else "PROCESSED",
                "source": "avro"
            }
            
            # Store by order_id for retrieval
            self.inventory_store[order_id] = inventory_entry
            logger.info(f"Updated inventory for order {order_id} from Avro message")
                
        except Exception as e:
            logger.error(f"Error processing Avro message: {e}")
            raise
            
    def _get_schema(self, schema_id: int) -> avro.schema.Schema:
        """
        Get the Avro schema from Schema Registry or cache.
        """
        if schema_id in self.schema_cache:
            return self.schema_cache[schema_id]
            
        try:
            # Get schema from Schema Registry
            url = f"{self.schema_registry_url}/schemas/ids/{schema_id}"
            response = requests.get(url)
            
            if response.status_code != 200:
                raise ValueError(f"Failed to fetch schema from Schema Registry: {response.status_code}")
                
            schema_data = response.json()
            schema_str = schema_data.get('schema')
            
            if not schema_str:
                raise ValueError("Schema not found in Schema Registry response")
                
            # Parse the schema
            schema = avro.schema.parse(schema_str)
            
            # Cache the schema
            self.schema_cache[schema_id] = schema
            
            return schema
            
        except Exception as e:
            logger.error(f"Error fetching schema: {e}")
            raise
        
    def get_error_count(self) -> int:
        """Get the number of errors encountered"""
        return self.error_count
    
    def get_last_errors(self) -> list:
        """Get the list of last error messages"""
        return self.last_errors.copy()
