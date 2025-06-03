#!/usr/bin/env python3
"""
Smoke test for inventory service - validates critical dependencies and functionality
"""

import os
import sys
import importlib
import json
import io
from pathlib import Path

# Add the parent directory to sys.path to import inventory_service modules
parent_dir = str(Path(__file__).parent.parent)
sys.path.insert(0, parent_dir)

# ANSI colors for better readability
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
RED = '\033[0;31m'
CYAN = '\033[0;36m'
NC = '\033[0m'  # No Color
CHECK = '✅'
CROSS = '❌'
WARNING = '⚠️'


def print_header(message):
    print(f"\n{CYAN}{'=' * 60}{NC}")
    print(f"{YELLOW}{message}{NC}")
    print(f"{CYAN}{'=' * 60}{NC}")


def print_result(test_name, success, message=""):
    status = f"{GREEN}{CHECK} PASS{NC}" if success else f"{RED}{CROSS} FAIL{NC}"
    print(f"{test_name:<50} {status}")
    if message and not success:
        print(f"  {YELLOW}{WARNING} {message}{NC}")


def check_dependency(module_name):
    """Test importing a dependency"""
    try:
        importlib.import_module(module_name)
        return True, ""
    except ImportError as e:
        return False, str(e)


def test_confluent_kafka():
    """Test the confluent_kafka package functionality"""
    try:
        from confluent_kafka import Consumer, KafkaError, KafkaException
        
        # Check for dummy/mock implementation
        consumer = Consumer({'group.id': 'smoke-test', 'client.id': 'smoke-test'})
        
        # If this is a mock, it would likely not have these attributes
        has_attributes = all(
            hasattr(consumer, attr) for attr in 
            ['subscribe', 'unsubscribe', 'poll', 'close']
        )
        
        # Check KafkaError has expected constants
        # Real implementation should have these error codes
        has_error_codes = hasattr(KafkaError, '_PARTITION_EOF')
        
        if not has_attributes or not has_error_codes:
            return False, "confluent_kafka appears to be a mock implementation"
            
        return True, ""
    except Exception as e:
        return False, str(e)


def test_avro():
    """Test avro-python3 package functionality"""
    try:
        import avro.schema
        import avro.io
        
        # Create simple schema
        schema_json = '''
        {
            "namespace": "test.avro",
            "type": "record", 
            "name": "TestMsg",
            "fields": [
                {"name": "id", "type": "string"},
                {"name": "value", "type": "int"}
            ]
        }
        '''
        
        # Parse schema
        schema = avro.schema.parse(schema_json)
        
        # Create writer and serialize data
        writer = avro.io.DatumWriter(schema)
        bytes_writer = io.BytesIO()
        encoder = avro.io.BinaryEncoder(bytes_writer)
        writer.write({"id": "test123", "value": 42}, encoder)
        raw_bytes = bytes_writer.getvalue()
        
        # Deserialize data
        reader = avro.io.DatumReader(schema)
        bytes_reader = io.BytesIO(raw_bytes)
        decoder = avro.io.BinaryDecoder(bytes_reader)
        result = reader.read(decoder)
        
        # Verify result 
        if result["id"] != "test123" or result["value"] != 42:
            return False, "Avro serialization/deserialization result doesn't match input"
        
        return True, ""
    except Exception as e:
        return False, str(e)


def test_avro_kafka_consumer():
    """Test that the AvroKafkaConsumer class can be imported and instantiated"""
    try:
        from inventory_service.consumer.avro_kafka_consumer import AvroOrderKafkaConsumer
        
        # Create a test inventory store
        inventory_store = {}
        
        # Try to instantiate the consumer (but don't start it)
        consumer = AvroOrderKafkaConsumer(
            bootstrap_servers="localhost:9092",
            topic="test-topic",
            group_id="smoke-test",
            schema_registry_url="http://localhost:8081",
            inventory_store=inventory_store
        )
        
        # Check for essential methods
        has_methods = all(
            hasattr(consumer, method) for method in 
            ['start', 'stop', '_process_message', '_get_schema']
        )
        
        if not has_methods:
            return False, "AvroOrderKafkaConsumer is missing essential methods"
            
        return True, ""
    except Exception as e:
        return False, str(e)


def test_all_core_modules_importable():
    """Test that all core inventory service modules can be imported"""
    core_modules = [
        "inventory_service.main",
        "inventory_service.consumer.kafka_consumer",
        "inventory_service.consumer.avro_kafka_consumer"
    ]
    
    all_success = True
    failed_modules = []
    
    for module in core_modules:
        try:
            importlib.import_module(module)
        except ImportError as e:
            all_success = False
            failed_modules.append(f"{module}: {str(e)}")
    
    if not all_success:
        return False, "Failed to import modules: " + ", ".join(failed_modules)
        
    return True, ""


def main():
    """Run all smoke tests"""
    print_header("🔍 Running Inventory Service Smoke Tests")
    
    # Track overall result
    all_passed = True
    
    # Test critical dependencies
    dependencies = [
        "fastapi", 
        "uvicorn", 
        "pydantic", 
        "confluent_kafka", 
        "avro", 
        "requests", 
        "dotenv"
    ]
    
    print("\n🧪 Testing critical dependencies:")
    for dep in dependencies:
        success, message = check_dependency(dep)
        all_passed = all_passed and success
        print_result(f"Import {dep}", success, message)
    
    # Test confluent_kafka functionality
    print("\n🧪 Testing confluent_kafka implementation:")
    success, message = test_confluent_kafka()
    all_passed = all_passed and success
    print_result("confluent_kafka real implementation", success, message)
    
    # Test avro functionality
    print("\n🧪 Testing avro serialization/deserialization:")
    success, message = test_avro()
    all_passed = all_passed and success
    print_result("avro-python3 functionality", success, message)
    
    # Test AvroKafkaConsumer
    print("\n🧪 Testing AvroKafkaConsumer:")
    success, message = test_avro_kafka_consumer()
    all_passed = all_passed and success
    print_result("AvroKafkaConsumer imports and instantiates", success, message)
    
    # Test all core modules
    print("\n🧪 Testing core modules:")
    success, message = test_all_core_modules_importable()
    all_passed = all_passed and success
    print_result("All core modules importable", success, message)
    
    # Print summary
    print("\n" + "=" * 60)
    if all_passed:
        print(f"{GREEN}🎉 All smoke tests PASSED! The inventory service dependencies look good.{NC}")
    else:
        print(f"{RED}❌ Some smoke tests FAILED! Check the details above.{NC}")
    print("=" * 60)
    
    return 0 if all_passed else 1


if __name__ == "__main__":
    sys.exit(main())
