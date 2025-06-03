# Inventory Service

A Python FastAPI service for the Tower of Babel Kafka Schema Registry demo.

## Description

This service demonstrates JSON deserialization issues when consuming messages from Kafka. It's part of the Phase 3 implementation showing cross-language serialization failures.

## Features

- FastAPI REST API
- Kafka integration with Confluent Kafka client
- Intentional JSON field name mismatch handling
- Error tracking and reporting
- Health check endpoint

## Project Structure

```
inventory_service/
├── __init__.py
├── consumer/
│   ├── __init__.py
│   └── kafka_consumer.py  # Kafka consumer with JSON deserialization
└── main.py               # FastAPI application
```

## Setup and Development

### Prerequisites
- Python 3.8+
- Virtual environment (.venv)
- Kafka running on localhost:29092

### Installation

```bash
# Create and activate virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Running the Service

```bash
# Using the Makefile from the project root
make run-inventory-service

# Or directly with Python
python -m inventory_service.main
```

### Environment Variables

- `KAFKA_BOOTSTRAP_SERVERS`: Kafka broker addresses (default: localhost:29092)
- `KAFKA_TOPIC`: Kafka topic to consume from (default: orders)
- `KAFKA_GROUP_ID`: Consumer group ID (default: inventory-service)

## Diagnostic Tools

- `check_env.py`: Script to verify Python environment and package availability
