---
trigger: manual
description: 
globs: 
---

# Build and Deployment Commands

## Initial Setup

```bash
# Start infrastructure (Kafka + Schema Registry)
make setup

# Install all service dependencies
make install-deps

# Generate code from Avro schemas  
make generate

# Build all services
make build

# Check service status
make status
```

## Infrastructure Management

```bash
# Start local Kafka + Schema Registry
docker-compose up -d

# Wait for services to be ready
./scripts/wait-for-services.sh

# Clean up everything (containers, volumes, build artifacts)
make clean

# Reset demo state (topics, schemas)
make demo-reset
```

## Service-Specific Commands

### Order Service (Java/Kotlin)
```bash
cd services/order-service
./gradlew clean build
./gradlew bootRun              # Port 9080
./gradlew test
```

### Inventory Service (Python)
```bash
cd services/inventory-service
source .venv/bin/activate
python -m inventory_service.main    # Port 9000
python -m pytest
```

### Analytics API (Node.js/TypeScript)
```bash
cd services/analytics-api
npm run build
npm run dev        # Development mode
npm start          # Production (port 9300)
npm test
```

## Debugging Commands

### Kafka
```bash
# List topics
docker-compose exec kafka kafka-topics --bootstrap-server kafka:9092 --list

# Consume messages
docker-compose exec kafka kafka-console-consumer \
  --bootstrap-server kafka:9092 --topic orders --from-beginning
```

### Schema Registry
```bash
# List registered schemas
curl http://localhost:8081/subjects

# Get schema versions
curl http://localhost:8081/subjects/orders-value/versions

# View specific schema
curl http://localhost:8081/subjects/orders-value/versions/1
```

## Port Allocation

- 9080: Order Service (Java/Spring Boot)
- 9000: Inventory Service (Python/FastAPI)
- 9300: Analytics API (Node.js/Express)
- 8081: Schema Registry
- 29092: Kafka (external access)
- 9092: Kafka (internal Docker network)

## Environment Variables

Configure via `.env` file:
- `KAFKA_BOOTSTRAP_SERVERS`: Kafka broker (default: localhost:29092)
- `SCHEMA_REGISTRY_URL`: Schema Registry (default: http://localhost:8081)
- `SERVICE_PORT`: Override default service port