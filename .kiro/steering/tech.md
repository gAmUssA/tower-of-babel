# Technology Stack

## Infrastructure

- **Kafka**: Confluent Platform 8.1.0 (KRaft mode, no Zookeeper)
- **Schema Registry**: Confluent Platform 8.1.0
- **Kafka UI**: kafbat/kafka-ui (optional monitoring)
- **Docker Compose**: For local development

## Services

### Order Service (Java/Kotlin)
- **Language**: Java 17 + Kotlin 2.2.21
- **Framework**: Spring Boot 3.5.7
- **Build Tool**: Gradle 8.x with Kotlin DSL
- **Kafka Client**: Spring Kafka 3.x
- **Serialization**: Confluent Kafka Avro Serializer 8.1.0
- **Code Generation**: gradle-avro-plugin 1.9.1
- **Port**: 9080

### Inventory Service (Python)
- **Language**: Python 3.9+ (tested with 3.12)
- **Framework**: FastAPI 0.121.0
- **Package Manager**: pip with venv
- **Kafka Client**: confluent-kafka 2.12.1
- **Serialization**: avro-python3 1.10.2
- **Code Generation**: Custom script using avro-python3
- **Port**: 9000

### Analytics API (Node.js/TypeScript)
- **Language**: Node.js 18+ with TypeScript 5.9.3
- **Framework**: Express 5.1.0
- **Package Manager**: npm
- **Kafka Client**: @confluentinc/kafka-javascript 1.6.0
- **Schema Registry Client**: @confluentinc/schemaregistry 1.6.0
- **Code Generation**: avro-typescript 1.0.4
- **Port**: 9300

## Build System

### Makefile Commands

**Setup & Infrastructure:**
- `make setup` - Start local Kafka + Schema Registry with Docker
- `make setup-cloud` - Configure for Confluent Cloud
- `make clean` - Clean up all containers, volumes, and build artifacts
- `make status` - Check service health and list topics/schemas

**Development:**
- `make install-deps` - Install all service dependencies
- `make generate` - Generate code from Avro schemas for all services
- `make build` - Build all services (includes dependency install and code generation)

**Running Services:**
- `make run-order-service` - Start Java Order Service
- `make run-inventory-service` - Start Python Inventory Service
- `make run-analytics-api` - Start Node.js Analytics API

**Demos:**
- `make demo-1` - Tower of Babel (serialization chaos)
- `make demo-2` - Babel Fish (Schema Registry solution)
- `make demo-3` - Safe Evolution (schema compatibility)
- `make demo-4` - Prevented Disasters (breaking changes blocked)
- `make demo-all` - Run all demos in sequence
- `make demo-workflow` - Show recommended demo workflow

**Testing:**
- `make test-1` - Test serialization failures
- `make test-2` - Test Avro integration
- `make test-3` - Test schema evolution
- `make test-4` - Test compatibility checks
- `make test-all` - Run all automated tests

**Utilities:**
- `make demo-reset` - Reset demo environment between runs

### Service-Specific Build Commands

**Java (Order Service):**
```bash
cd services/order-service
./gradlew build              # Build with tests
./gradlew generateAvroJava   # Generate Java classes from Avro schemas
./gradlew bootRun            # Run the service
```

**Python (Inventory Service):**
```bash
cd services/inventory-service
python3 -m venv .venv                    # Create virtual environment
source .venv/bin/activate                # Activate venv
pip install -r requirements.txt          # Install dependencies
python scripts/generate_classes.py      # Generate Python classes
python -m inventory_service.main         # Run the service
pytest                                   # Run tests
```

**Node.js (Analytics API):**
```bash
cd services/analytics-api
npm ci                       # Install dependencies
npm run generate-types       # Generate TypeScript interfaces
npm run build                # Compile TypeScript
npm start                    # Run the service
npm test                     # Run tests
```

## Code Generation

All services use schema-first development with automatic code generation from central Avro schemas in `schemas/` directory.

**Java**: Gradle plugin generates POJOs at build time into `build/generated-main-avro-java/`
**Python**: Custom script generates dataclasses into `src/generated/`
**TypeScript**: npm script generates interfaces into `src/generated/`

## Port Allocation

- **8080**: Kafka UI
- **8081**: Schema Registry
- **9000**: Inventory Service (Python)
- **9080**: Order Service (Java)
- **9300**: Analytics API (Node.js)
- **29092**: Kafka external listener

## Configuration

Services connect to:
- Kafka: `localhost:29092`
- Schema Registry: `http://localhost:8081`

Environment variables can be configured via `.env` files in each service directory.
