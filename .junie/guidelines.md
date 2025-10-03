# Tower of Babel - Development Guidelines

This document contains project-specific development information for the Tower of Babel Kafka Schema Registry demo project.

## Project Overview

Multi-language microservices demo showcasing Schema Registry integration with:
- **Order Service**: Java 17 + Spring Boot 3.x + Kotlin (port 9080)
- **Inventory Service**: Python 3.9+ + FastAPI (port 9000)
- **Analytics API**: Node.js 18+ + Express + TypeScript (port 9300)
- **Infrastructure**: Kafka + Schema Registry (Confluent Platform 7.9.x, KRaft mode)

## Build & Configuration

### Prerequisites
- Docker and Docker Compose
- Java 17+
- Python 3.9+ (project uses Python 3.12)
- Node.js 18+
- Make

### Initial Setup

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

### Infrastructure Management

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

**Important**: The project uses KRaft mode (no Zookeeper). Kafka is accessible at `localhost:29092` (external) and Schema Registry at `http://localhost:8081`.

## Schema Management

### Central Schema Repository

Schemas are stored in the `schemas/` directory with versioning:
- `schemas/v1/` - Initial schema versions
- `schemas/v2/` - Evolved schemas (backward compatible)
- `schemas/incompatible/` - Breaking changes for demo purposes

### Schema Evolution Pattern

When evolving schemas, follow Avro backward compatibility rules:
- Add new fields with default values
- Use union types with null for optional fields
- Never remove required fields or change field types

Example from `schemas/v2/order-event.avsc`:
```json
{"name": "orderTimestamp", "type": ["null", "long"], "default": null}
{"name": "metadata", "type": ["null", {"type": "map", "values": "string"}], "default": null}
```

### Code Generation Workflow

Each service generates code from the central schema repository:

```bash
# Generate code for all services
make generate

# Or per service:
cd services/order-service && ./gradlew generateAvroJava
cd services/inventory-service && python3 scripts/generate_classes.py
cd services/analytics-api && npm run generate-types
```

**Critical**: Always regenerate code after schema changes. The build process automatically copies schemas from `schemas/v1/` to each service before generation.

## Testing

### Java/Kotlin (Order Service)

**Build System**: Gradle with Kotlin DSL

**Test Framework**: JUnit 5 (Jupiter)

**Running Tests**:
```bash
cd services/order-service
./gradlew test                    # Run all tests
./gradlew test --tests "ClassName"  # Run specific test class
./gradlew test --info             # Verbose output
```

**Test Location**: `src/test/kotlin/com/company/orders/`

**Example Test Structure**:
```kotlin
package com.company.orders.model

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.Assertions.*

class OrderTest {
    @Test
    fun `should create order with required fields`() {
        // Given
        val userId = "user123"
        
        // When
        val order = Order(userId = userId, amount = BigDecimal("99.99"), status = "PENDING")
        
        // Then
        assertNotNull(order.orderId)
        assertEquals(userId, order.userId)
    }
}
```

**Key Points**:
- Uses Kotlin backtick syntax for descriptive test names
- Follows Given-When-Then pattern
- JUnit Platform configured in `build.gradle.kts`

### Python (Inventory Service)

**Build System**: pip with virtual environment

**Test Framework**: pytest 7.4.4

**Running Tests**:
```bash
cd services/inventory-service
source .venv/bin/activate          # Activate virtual environment
python -m pytest                   # Run all tests
python -m pytest tests/test_utils.py  # Run specific file
python -m pytest -v                # Verbose output
python -m pytest -k "test_name"    # Run tests matching pattern
```

**Test Location**: `tests/` directory (separate from package)

**Example Test Structure**:
```python
import pytest
from inventory_service.utils import validate_order_data

class TestValidateOrderData:
    """Tests for validate_order_data function"""
    
    def test_valid_order_data(self):
        """Test validation with all required fields"""
        order_data = {
            'orderId': '123',
            'userId': 'user456',
            'amount': 99.99,
            'status': 'PENDING'
        }
        assert validate_order_data(order_data) is True
    
    def test_missing_required_field(self):
        """Test validation with missing required field"""
        order_data = {'orderId': '123', 'userId': 'user456'}
        assert validate_order_data(order_data) is False
```

**Key Points**:
- Always use virtual environment (`.venv`)
- Test files must start with `test_` or end with `_test.py`
- Use class-based organization for related tests
- Pytest automatically discovers tests

**Virtual Environment Setup**:
```bash
cd services/inventory-service
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Node.js/TypeScript (Analytics API)

**Build System**: npm with TypeScript

**Test Framework**: Jest 29.7.0 with ts-jest

**Running Tests**:
```bash
cd services/analytics-api
npm test                          # Run all tests
npm test -- order-utils           # Run tests matching pattern
npm test -- --coverage            # Run with coverage report
npm test -- --verbose             # Verbose output
```

**Test Location**: Co-located with source files (`.test.ts` suffix)

**Example Test Structure**:
```typescript
import { validateOrderData, formatOrderId } from './order-utils';

describe('validateOrderData', () => {
  it('should return true for valid order data', () => {
    const orderData = {
      orderId: '123',
      userId: 'user456',
      amount: 99.99,
      status: 'PENDING'
    };
    expect(validateOrderData(orderData)).toBe(true);
  });

  it('should return false for missing required field', () => {
    const orderData = { orderId: '123', userId: 'user456' };
    expect(validateOrderData(orderData)).toBe(false);
  });
});
```

**Jest Configuration** (`jest.config.js`):
```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/__tests__/**/*.ts', '**/?(*.)+(spec|test).ts'],
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.test.ts',
    '!src/generated/**',  // Exclude generated code
  ],
};
```

**Key Points**:
- Tests use `.test.ts` or `.spec.ts` suffix
- Co-located with source files for better organization
- ts-jest handles TypeScript compilation
- Generated code excluded from coverage
- Use `describe` blocks for grouping related tests

**Building TypeScript**:
```bash
npm run build    # Compiles to dist/
npm run dev      # Development mode with auto-reload
npm start        # Run compiled code
```

## Service-Specific Build Details

### Order Service (Java/Kotlin)

**Gradle Configuration** (`build.gradle.kts`):
- Spring Boot 3.5.5
- Kotlin 1.9.25
- Avro Gradle Plugin 1.9.1
- Confluent Kafka Avro Serializer 7.9.2

**Custom Gradle Tasks**:
- `copySchemas` - Copies schemas from `schemas/v1/` to `src/main/avro/`
- `generateAvroJava` - Generates Java POJOs from Avro schemas
- Build automatically depends on code generation

**Avro Configuration**:
```kotlin
avro {
    isCreateSetters.set(true)
    fieldVisibility.set("PRIVATE")
    stringType.set("String")
    isEnableDecimalLogicalType.set(true)
}
```

**Running the Service**:
```bash
./gradlew bootRun    # Port 9080
```

### Inventory Service (Python)

**Dependencies** (`requirements.txt`):
- FastAPI 0.115.12
- Uvicorn 0.35.0 (ASGI server)
- confluent-kafka 2.11.0
- avro-python3 1.10.2
- pytest 7.4.4

**Project Structure**:
```
inventory_service/
├── inventory_service/     # Main package
│   ├── consumer/         # Kafka consumer logic
│   ├── generated/        # Generated Avro classes
│   └── main.py          # Application entry point
├── tests/               # Test files
├── scripts/             # Utility scripts
└── requirements.txt
```

**Code Generation**:
```bash
python3 scripts/generate_classes.py
```

**Running the Service**:
```bash
source .venv/bin/activate
python -m inventory_service.main    # Port 9000
```

### Analytics API (Node.js/TypeScript)

**Dependencies** (`package.json`):
- Express 5.1.0
- KafkaJS 2.2.4
- @kafkajs/confluent-schema-registry 3.3.0
- TypeScript 5.3.2
- Socket.IO 4.7.2 (real-time updates)

**NPM Scripts**:
```json
{
  "build": "tsc && npm run copy-public",
  "start": "node dist/index.js",
  "dev": "ts-node-dev --respawn --transpile-only src/index.ts",
  "test": "jest",
  "generate-types": "node src/scripts/generate-types.js"
}
```

**TypeScript Configuration** (`tsconfig.json`):
- Target: ES2020
- Module: CommonJS
- Strict mode enabled
- Output: `dist/`

**Running the Service**:
```bash
npm run dev      # Development mode
npm start        # Production mode (port 9300)
```

## Code Style & Conventions

### General Principles
- Schema-first development: Always define schemas before implementing services
- Type safety: Leverage generated types from Avro schemas
- Backward compatibility: Never break existing consumers when evolving schemas

### Kotlin (Order Service)
- Use data classes for models
- Prefer immutability (`val` over `var`)
- Use backtick syntax for descriptive test names
- Follow Spring Boot conventions for controllers/services

### Python (Inventory Service)
- Follow PEP 8 style guide
- Use type hints for function signatures
- Docstrings for public functions (Google style)
- Class-based test organization with pytest

### TypeScript (Analytics API)
- Strict TypeScript mode enabled
- Use interfaces for data structures
- Prefer `const` over `let`
- Export types alongside functions
- Co-locate tests with source files

## Common Development Tasks

### Adding a New Schema

1. Create schema in `schemas/v1/`:
```bash
cat > schemas/v1/new-event.avsc << 'EOF'
{
  "type": "record",
  "name": "NewEvent",
  "namespace": "com.company.events",
  "fields": [
    {"name": "id", "type": "string"},
    {"name": "timestamp", "type": "long"}
  ]
}
EOF
```

2. Generate code for all services:
```bash
make generate
```

3. Implement producers/consumers using generated types

### Evolving an Existing Schema

1. Copy current schema to new version:
```bash
cp schemas/v1/order-event.avsc schemas/v2/order-event.avsc
```

2. Add new fields with defaults (backward compatible):
```json
{"name": "newField", "type": ["null", "string"], "default": null}
```

3. Regenerate code and test compatibility

### Running Demo Scenarios

```bash
# Phase 3: Serialization chaos (broken scenarios)
make phase3-java-serialization
make phase3-json-mismatch
make phase3-type-inconsistency

# Phase 4: Schema Registry solution
make phase4-demo
make phase4-test
```

## Debugging Tips

### Kafka Issues
- Check Kafka logs: `docker-compose logs kafka`
- List topics: `docker-compose exec kafka kafka-topics --bootstrap-server kafka:9092 --list`
- Consume messages: `docker-compose exec kafka kafka-console-consumer --bootstrap-server kafka:9092 --topic orders --from-beginning`

### Schema Registry Issues
- Check registered schemas: `curl http://localhost:8081/subjects`
- Get schema versions: `curl http://localhost:8081/subjects/orders-value/versions`
- View specific schema: `curl http://localhost:8081/subjects/orders-value/versions/1`

### Service Issues
- Check service logs in `services/logs/`
- Verify ports are not in use: `lsof -i :9080,9000,9300`
- Ensure infrastructure is running: `make status`

## Port Allocation

- **9080**: Order Service (Java/Spring Boot)
- **9000**: Inventory Service (Python/FastAPI)
- **9300**: Analytics API (Node.js/Express)
- **8081**: Schema Registry
- **29092**: Kafka (external access)
- **9092**: Kafka (internal Docker network)
- **8080**: Kafka UI (optional)

## Environment Variables

Services can be configured via environment variables or `.env` files:

- `KAFKA_BOOTSTRAP_SERVERS`: Kafka broker address (default: `localhost:29092`)
- `SCHEMA_REGISTRY_URL`: Schema Registry URL (default: `http://localhost:8081`)
- `SERVICE_PORT`: Override default service port

For Confluent Cloud deployment, see `docker-compose.cloud.yml` and `.env.example`.

## Troubleshooting

### Build Failures

**Gradle (Java)**:
- Clear Gradle cache: `./gradlew clean --refresh-dependencies`
- Check Java version: `java -version` (must be 17+)

**Python**:
- Recreate virtual environment: `rm -rf .venv && python3.12 -m venv .venv`
- Verify Python version: `python --version` (must be 3.9+)

**Node.js**:
- Clear node_modules: `rm -rf node_modules package-lock.json && npm install`
- Check Node version: `node --version` (must be 18+)

### Test Failures

- Ensure dependencies are installed: `make install-deps`
- Verify code generation is up to date: `make generate`
- Check for port conflicts if integration tests fail
- Review test output for specific error messages

### Schema Compatibility Issues

- Use Schema Registry compatibility checker before deploying
- Test with both old and new schema versions
- Verify default values are provided for new fields
- Check union types include null for optional fields

## Additional Resources

- [Avro Specification](https://avro.apache.org/docs/current/spec.html)
- [Confluent Schema Registry Documentation](https://docs.confluent.io/platform/current/schema-registry/index.html)
- [Schema Evolution Best Practices](https://docs.confluent.io/platform/current/schema-registry/avro.html#schema-evolution)
- Project documentation: `docs/requirements.md`, `docs/plan.md`
