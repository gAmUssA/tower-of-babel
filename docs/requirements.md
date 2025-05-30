# Demo Technical Requirements - PRD
## From Tower of Babel to Babel Fish: Schema Registry Demo

---

## 1. Executive Summary

### Objective
Create a live coding demonstration showcasing the evolution from chaotic polyglot Kafka architecture to Schema Registry-managed data contracts. The demo prioritizes **concept clarity over realism** and must reliably illustrate schema-related failures and their resolution within a 20-minute timeframe.

### Success Criteria
- Demonstrate clear "before/after" scenarios showing Schema Registry value
- Execute within strict timing constraints (20 minutes total)
- Provide simple, educational examples that highlight core concepts
- Enable audience members to replicate the demo via GitHub repository
- Support both local Docker and Confluent Cloud deployments

---

## 2. System Architecture

### 2.1 Overall Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Order Service │    │ Inventory Svc   │    │ Analytics API   │
│   (Java/Spring) │    │ (Python/FastAPI)│    │ (Node.js/Express│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │ Kafka + Schema  │
                    │    Registry     │
                    └─────────────────┘
```

### 2.2 Component Requirements

#### Infrastructure Services
| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| Kafka | Confluent Platform (KRaft) | 7.9.1 | Message broker (no Zookeeper) |
| Schema Registry | Confluent Platform | 7.9.1 | Schema management |
| Kafka UI | Optional | latest | Lightweight monitoring |

#### Deployment Options
- **Local**: Docker Compose with Confluent Platform (KRaft mode)
- **Cloud**: Confluent Cloud with local applications

#### Application Services
| Service | Technology | Port | Purpose |
|---------|------------|------|---------|
| Order Service | Java 17 + Spring Boot 3.x | 9080 | Order event producer |
| Inventory Service | Python 3.9+ + FastAPI | 9000 | Order event consumer |
| Analytics API | Node.js 18+ + Express | 9300 | Analytics consumer + Web UI |

#### Port Allocation Strategy
- **Infrastructure**: Default ports (8081 for Schema Registry, 29092 for Kafka external)
- **Applications**: 9xxx ports to avoid conflicts
- **Monitoring**: 8080 for Kafka UI

---

## 3. Functional Requirements

### 3.1 Core Demo Scenarios

#### Scenario 1: "Tower of Babel" - Serialization Chaos
**User Story**: As a developer, I need to see how different serialization approaches fail across languages.

**Acceptance Criteria**:
- Order Service (Java) uses Java Object Serialization → Python service cannot deserialize
- Inventory Service switches to JSON → Field naming inconsistencies cause failures
- Analytics Service expects different JSON structure → Silent data corruption
- Clear error messages show cross-platform serialization issues
- Demonstrate lack of schema evolution with JSON

**Demo Progression**:
1. **Java Serialization**: Show binary format incompatibility
2. **JSON without Schema**: Show field name mismatches (`userId` vs `user_id`)
3. **Type Inconsistencies**: Show string vs number confusion

#### Scenario 2: "Babel Fish" - Schema Registry Solution
**User Story**: As a developer, I want to see how Schema Registry enables code generation and type safety.

**Acceptance Criteria**:
- Schema Registry hosts centralized Avro schemas
- Java POJOs generated from schemas via Maven/Gradle plugin
- Python dataclasses generated from schemas
- TypeScript interfaces generated for Node.js
- All services use generated code (no manual class definition)
- Type safety enforced at compile time
- Schema evolution automatically updates generated code

#### Scenario 3: "Safe Evolution" - Schema Changes
**User Story**: As a developer, I need to see how schemas can evolve without breaking existing consumers.

**Acceptance Criteria**:
- Add optional field to existing schema
- Compatibility check passes in Schema Registry
- Old consumers continue working with new data
- New consumers can access new fields

#### Scenario 4: "Prevented Disasters" - Breaking Changes Blocked
**User Story**: As a developer, I want to see how Schema Registry prevents dangerous schema changes.

**Acceptance Criteria**:
- Attempt to register incompatible schema change
- Schema Registry rejects the change with clear error message
- Production services remain unaffected
- Error message explains why change is incompatible

### 3.2 Schema-First Development Model

#### Central Schema Definition
```json
// schemas/order-event.avsc - Single source of truth
{
  "type": "record",
  "name": "OrderEvent",
  "namespace": "com.company.orders",
  "doc": "Represents an order event in the system",
  "fields": [
    {"name": "orderId", "type": "string", "doc": "Unique order identifier"},
    {"name": "userId", "type": "string", "doc": "Customer identifier"},
    {"name": "amount", "type": "double", "doc": "Order total amount"},
    {"name": "status", "type": "string", "doc": "Order status"}
  ]
}
```

#### Generated Artifacts
```java
// Generated Java POJO (target/generated-sources/)
@AvroGenerated
public class OrderEvent extends SpecificRecordBase implements SpecificRecord {
    public String orderId;
    public String userId;
    public Double amount;
    public String status;
    // Generated getters, setters, schema methods...
}
```

```python
# Generated Python dataclass (src/generated/)
from dataclasses import dataclass
from typing import Optional

@dataclass
class OrderEvent:
    orderId: str
    userId: str  
    amount: float
    status: str
```

```typescript
// Generated TypeScript interface (src/generated/)
export interface OrderEvent {
  orderId: string;
  userId: string;
  amount: number;
  status: string;
}
```

#### Code Generation Workflow
1. **Schema Definition**: Central Avro schema in `schemas/` directory
2. **Build Integration**: Code generation integrated into build process
3. **Type Safety**: Compile-time validation across all languages
4. **Evolution**: Schema changes automatically update generated code

---

## 4. Technical Requirements

### 4.1 Development Environment

#### Host Machine Requirements
- **OS**: macOS, Linux, or Windows with WSL2
- **RAM**: Minimum 8GB, Recommended 16GB
- **Docker**: Version 20.0+
- **Docker Compose**: Version 2.0+
- **Network**: Reliable internet for Docker image pulls
- **Ports**: 8080, 8081, 9000, 9080, 9300, 29092 available

#### Language Runtimes (for local development)
- **Java**: OpenJDK 17+
- **Python**: 3.9+ with uv (modern Python package manager)
- **Node.js**: 18+ with npm
- **Gradle**: 8.0+ with Kotlin DSL (for Java builds)

### 4.2 Docker Configuration

#### docker-compose.yml Requirements
```yaml
version: '3.8'
services:
  kafka:
    image: confluentinc/cp-kafka:7.9.1
    hostname: kafka
    container_name: kafka
    ports:
      - "29092:29092"
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: 'CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT'
      KAFKA_ADVERTISED_LISTENERS: 'PLAINTEXT://kafka:9092,PLAINTEXT_HOST://localhost:29092'
      KAFKA_LISTENERS: 'PLAINTEXT://kafka:9092,CONTROLLER://kafka:9093,PLAINTEXT_HOST://0.0.0.0:29092'
      KAFKA_INTER_BROKER_LISTENER_NAME: 'PLAINTEXT'
      KAFKA_CONTROLLER_LISTENER_NAMES: 'CONTROLLER'
      KAFKA_CONTROLLER_QUORUM_VOTERS: '1@kafka:9093'
      KAFKA_PROCESS_ROLES: 'broker,controller'
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_LOG_DIRS: '/tmp/kraft-combined-logs'
      CLUSTER_ID: 'MkU3OEVBNTcwNTJENDM2Qk'
    healthcheck:
      test: ["CMD", "kafka-topics", "--bootstrap-server", "kafka:9092", "--list"]
      interval: 10s
      timeout: 5s
      retries: 10

  schema-registry:
    image: confluentinc/cp-schema-registry:7.9.1
    hostname: schema-registry
    container_name: schema-registry
    depends_on:
      kafka:
        condition: service_healthy
    ports:
      - "8081:8081"
    environment:
      SCHEMA_REGISTRY_HOST_NAME: schema-registry
      SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: 'kafka:9092'
      SCHEMA_REGISTRY_LISTENERS: http://0.0.0.0:8081

  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    container_name: kafka-ui
    depends_on:
      - kafka
      - schema-registry
    ports:
      - "8080:8080"
    environment:
      KAFKA_CLUSTERS_0_NAME: local
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:9092
      KAFKA_CLUSTERS_0_SCHEMAREGISTRY: http://schema-registry:8081
```

#### Application Configuration
```properties
# Applications connect to localhost:29092 (external listener)
# Internal services use kafka:9092 (internal listener)

# Java application.properties
spring.kafka.bootstrap-servers=localhost:29092
spring.kafka.properties.schema.registry.url=http://localhost:8081
server.port=9080

# Python .env
KAFKA_BOOTSTRAP_SERVERS=localhost:29092
SCHEMA_REGISTRY_URL=http://localhost:8081
SERVER_PORT=9000

# Node.js config
KAFKA_BROKERS=localhost:29092
SCHEMA_REGISTRY_URL=http://localhost:8081
PORT=9300
```

#### Confluent Cloud Configuration
```properties
# .env file for cloud deployment
CONFLUENT_CLOUD_BOOTSTRAP_SERVERS=pkc-xxxxx.us-east-2.aws.confluent.cloud:9092
CONFLUENT_CLOUD_SCHEMA_REGISTRY_URL=https://psrc-xxxxx.us-east-2.aws.confluent.cloud
CONFLUENT_CLOUD_API_KEY=your-api-key
CONFLUENT_CLOUD_API_SECRET=your-api-secret
CONFLUENT_CLOUD_SR_API_KEY=your-sr-api-key
CONFLUENT_CLOUD_SR_API_SECRET=your-sr-api-secret
```

### 4.3 Application Dependencies

#### Java Order Service
```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
        <version>3.2.0</version>
    </dependency>
    <dependency>
        <groupId>org.springframework.kafka</groupId>
        <artifactId>spring-kafka</artifactId>
        <version>3.1.0</version>
    </dependency>
    <dependency>
        <groupId>io.confluent</groupId>
        <artifactId>kafka-avro-serializer</artifactId>
        <version>7.9.1</version>
    </dependency>
    <dependency>
        <groupId>org.apache.avro</groupId>
        <artifactId>avro</artifactId>
        <version>1.11.3</version>
    </dependency>
    
    <!-- Test Dependencies -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <version>3.2.0</version>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>junit-jupiter</artifactId>
        <version>1.19.0</version>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>kafka</artifactId>
        <version>1.19.0</version>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.springframework.kafka</groupId>
        <artifactId>spring-kafka-test</artifactId>
        <version>3.1.0</version>
        <scope>test</scope>
    </dependency>
</dependencies>
```

#### Python Inventory Service
```toml
# pyproject.toml (managed by uv)
[project]
name = "inventory-service"
version = "0.1.0"
description = "Kafka consumer for order processing"
requires-python = ">=3.9"
dependencies = [
    "fastapi==0.104.0",
    "uvicorn==0.24.0",
    "confluent-kafka[avro]==2.3.0",
    "requests==2.31.0",
    "pydantic==2.5.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.uv]
dev-dependencies = [
    "pytest>=7.0.0",
    "black>=23.0.0",
    "ruff>=0.1.0",
    "testcontainers[kafka]>=4.0.0",
    "pytest-asyncio>=0.21.0",
    "avro-python3>=1.11.3",
    "dataclasses-avroschema>=0.60.0",  # Schema → Python classes generation
]

# Code generation setup
[tool.avro-codegen]
schema-dir = "schemas/"
output-dir = "src/generated/"
```

```bash
# Setup commands for Python service
uv venv
uv pip install -e .
uv run uvicorn main:app --host 0.0.0.0 --port 9000
```

#### Node.js Analytics API
```json
{
  "dependencies": {
    "express": "^4.18.2",
    "kafkajs": "^2.2.4",
    "@kafkajs/confluent-schema-registry": "^3.3.0",
    "avsc": "^5.7.7",
    "ws": "^8.14.0"
  },
  "devDependencies": {
    "jest": "^29.7.0",
    "testcontainers": "^10.2.0",
    "@testcontainers/kafka": "^10.2.0",
    "supertest": "^6.3.3",
    "avro-typescript": "^1.0.4"
  },
  "scripts": {
    "generate-types": "avro-typescript --input schemas/ --output src/generated/",
    "prebuild": "npm run generate-types"
  }
}
```

#### Code Generation Configuration
```bash
# Generate TypeScript interfaces from Avro schemas
npm run generate-types

# Generated files structure:
# src/generated/
#   ├── OrderEvent.ts
#   ├── UserEvent.ts
#   └── index.ts
```

---

## 5. Non-Functional Requirements

### 5.1 Performance Requirements
- **Startup Time**: Complete stack startup < 3 minutes
- **Demo Reset**: Full reset between demo runs < 30 seconds
- **Message Latency**: End-to-end message processing < 1 second
- **UI Responsiveness**: Web dashboards load < 2 seconds

### 5.2 Reliability Requirements
- **Demo Success Rate**: 95% successful executions
- **Error Recovery**: Automatic service restart on failure
- **State Management**: Clean state between demo runs
- **Network Resilience**: Continue operating with intermittent connectivity

### 5.3 Usability Requirements
- **Setup Time**: Complete environment setup < 10 minutes
- **Documentation**: Step-by-step setup guide
- **Error Messages**: Clear, actionable error descriptions
- **Monitoring**: Real-time visibility into service health

---

## 6. Implementation Plan

### 6.1 Development Phases

#### Phase 1: Infrastructure Setup (Week 1)
- **Deliverables**: Docker Compose configuration, basic Kafka setup
- **Acceptance**: All infrastructure services start successfully
- **Testing**: Validate service connectivity and health checks

#### Phase 2: Schema-First Foundation (Week 2)
- **Deliverables**: Central schema definitions, code generation pipeline
- **Acceptance**: Generated code artifacts for all three languages
- **Testing**: Verify build integration and generated class validity

#### Phase 3: Broken Services (Week 3)
- **Deliverables**: Services with intentional serialization incompatibilities
- **Acceptance**: Clear demonstration of manual class mismatches
- **Testing**: Verify errors are reproducible and educational

#### Phase 4: Schema Registry Integration (Week 4)
- **Deliverables**: Avro-enabled services using generated code
- **Acceptance**: All services communicate via generated classes
- **Testing**: Validate end-to-end message flow with generated artifacts

#### Phase 5: Evolution & Code Generation Demo (Week 5)
- **Deliverables**: Schema evolution with automatic code regeneration
- **Acceptance**: Schema changes automatically update all language bindings
- **Testing**: Comprehensive compatibility testing across generated code

#### Phase 6: Demo Polish & Automation (Week 6)
- **Deliverables**: Makefile automation, documentation, backup plans
- **Acceptance**: Ready for production presentation with code generation showcase
- **Testing**: Full dress rehearsal with schema-first development demonstration

### 6.2 Deployment Strategy

#### Local Development
```makefile
# Makefile with emoji and colors for better readability
.PHONY: help setup demo-* clean

# Colors
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

help: ## 📋 Show this help message
	@echo "$(GREEN)🚀 Kafka Schema Registry Demo$(NC)"
	@echo "$(YELLOW)Available commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $1, $2}'

setup: ## 🏗️  Setup local environment with Docker
	@echo "$(GREEN)🏗️  Setting up local Kafka environment...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)⏳ Waiting for services to be ready...$(NC)"
	./scripts/wait-for-services.sh
	@echo "$(GREEN)✅ Environment ready!$(NC)"

setup-cloud: ## ☁️  Setup for Confluent Cloud
	@echo "$(GREEN)☁️  Configuring for Confluent Cloud...$(NC)"
	./scripts/setup-cloud-config.sh
	@echo "$(GREEN)✅ Cloud configuration ready!$(NC)"

demo-broken: ## 💥 Start demo with broken serialization
	@echo "$(RED)💥 Starting broken demo (Java serialization + JSON mismatches)...$(NC)"
	./scripts/start-broken-services.sh
	@echo "$(RED)🔥 Services are now failing! Check logs for errors.$(NC)"

demo-fixed: ## ✅ Switch to Schema Registry solution
	@echo "$(GREEN)✅ Switching to Schema Registry solution...$(NC)"
	./scripts/stop-broken-services.sh
	./scripts/start-avro-services.sh
	@echo "$(GREEN)🎉 All services now working with Avro!$(NC)"

generate: ## 🔧 Generate code from schemas
	@echo "$(GREEN)🔧 Generating code from Avro schemas...$(NC)"
	@echo "$(YELLOW)Java POJOs (Gradle + Kotlin DSL):$(NC)"
	cd services/order-service && ./gradlew generateAvroJava
	@echo "$(YELLOW)Python dataclasses:$(NC)"
	cd services/inventory-service && uv run python scripts/generate_classes.py
	@echo "$(YELLOW)TypeScript interfaces:$(NC)"
	cd services/analytics-api && npm run generate-types
	@echo "$(GREEN)✅ Code generation complete!$(NC)"

build: ## 🏗️  Build all services
	@echo "$(GREEN)🏗️  Building all services...$(NC)"
	@echo "$(YELLOW)Java service (Gradle):$(NC)"
	cd services/order-service && ./gradlew build
	@echo "$(YELLOW)Python service (uv):$(NC)"
	cd services/inventory-service && uv run python -m pytest --tb=short
	@echo "$(YELLOW)Node.js service:$(NC)"
	cd services/analytics-api && npm run build
	@echo "$(GREEN)✅ All builds successful!$(NC)"

demo-codegen: ## 🎭 Demo schema-first development
	@echo "$(GREEN)🎭 Demonstrating schema-first development...$(NC)"
	@echo "$(YELLOW)1. Show schema definition$(NC)"
	cat schemas/order-event.avsc
	@echo "$(YELLOW)2. Generate code artifacts$(NC)"
	make generate
	@echo "$(YELLOW)3. Show generated classes$(NC)"
	@echo "$(GREEN)Java (generated by Gradle):$(NC)"
	find services/order-service/build/generated-main-avro-java -name "*.java" | head -3
	@echo "$(GREEN)Python (generated):$(NC)"
	find services/inventory-service/src/generated -name "*.py" | head -3
	@echo "$(GREEN)TypeScript (generated):$(NC)"
	find services/analytics-api/src/generated -name "*.ts" | head -3
	@echo "$(GREEN)🎉 Schema drives code generation!$(NC)"
	@echo "$(YELLOW)🔄 Demonstrating schema evolution...$(NC)"
	./scripts/evolve-schema.sh
	@echo "$(GREEN)📈 Schema evolved successfully!$(NC)"

demo-evolution: ## 🔄 Show schema evolution
	@echo "$(YELLOW)🔄 Resetting demo state...$(NC)"
	./scripts/cleanup-topics.sh
	./scripts/cleanup-schemas.sh
	docker-compose restart
	@echo "$(GREEN)✨ Demo reset complete!$(NC)"

clean: ## 🧹 Clean up everything
	@echo "$(RED)🧹 Cleaning up everything...$(NC)"
	docker-compose down -v
	docker system prune -f
	@echo "$(GREEN)✨ Cleanup complete!$(NC)"

status: ## 📊 Check service status
	@echo "$(YELLOW)📜 Showing service logs...$(NC)"
	docker-compose logs -f

test: ## 🧪 Run integration tests with testcontainers
	@echo "$(YELLOW)🧪 Running integration tests...$(NC)"
	@echo "$(GREEN)Java tests (Gradle):$(NC)"
	cd services/order-service && ./gradlew test
	@echo "$(GREEN)Python tests (uv):$(NC)"
	cd services/inventory-service && uv run pytest
	@echo "$(GREEN)Node.js tests:$(NC)"
	cd services/analytics-api && npm test
	@echo "$(GREEN)✅ All tests passed!$(NC)"
	@echo "$(GREEN)📊 Service Status:$(NC)"
	@echo "$(YELLOW)Docker services:$(NC)"
	docker-compose ps
	@echo "$(YELLOW)Kafka topics:$(NC)"
	docker-compose exec kafka kafka-topics --bootstrap-server kafka:9092 --list
	@echo "$(YELLOW)Schema Registry subjects:$(NC)"
	curl -s http://localhost:8081/subjects | jq .
```

#### Presentation Environment
- **Primary**: Local Docker with Makefile automation
- **Backup**: Confluent Cloud fallback
- **Reset**: Single command demo reset (`make demo-reset`)
- **GitHub**: Public repository with complete setup

---

## 7. Risk Management

### 7.1 Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|---------|------------|
| Docker startup failure | Medium | High | Health checks, `make setup` retry logic |
| Network connectivity issues | Low | High | Confluent Cloud fallback, offline mode |
| Live demo typing errors | High | Medium | Makefile automation, no live coding |
| Service crash during demo | Medium | High | `make demo-reset`, backup terminals |
| Schema Registry connectivity | Low | High | Local + cloud dual setup |

### 7.2 Backup Plans

#### Level 1: Makefile Automation
- All demo steps automated via Makefile commands
- No live typing of complex commands
- Single command reset between demo runs
- Color-coded status feedback

#### Level 2: Dual Infrastructure  
- Local Docker as primary
- Confluent Cloud as backup
- Environment switching via `make setup-cloud`
- Pre-configured connection profiles

#### Level 3: Simplified Fallback
- Core concepts via slides if all infrastructure fails
- Pre-recorded terminal sessions
- Simplified single-service examples

---

## 8. Testing Strategy

### 8.1 Unit Testing
- **Schema validation**: Test Avro schema compatibility
- **Service integration**: Mock Kafka interactions
- **Error scenarios**: Validate failure modes

### 8.2 Integration Testing with Testcontainers
- **Kafka Integration**: Spin up real Kafka cluster for tests
- **Schema Registry Testing**: Test schema evolution scenarios
- **Multi-service Communication**: End-to-end message flow testing
- **Cross-platform Serialization**: Validate Java ↔ Python ↔ Node.js compatibility

#### Sample Integration Test Structure
```python
# Python example with testcontainers
import pytest
from testcontainers.kafka import KafkaContainer
from testcontainers.compose import DockerCompose

@pytest.fixture(scope="session")
def kafka_cluster():
    with DockerCompose(".", compose_file_name="docker-compose.test.yml") as compose:
        kafka_host = compose.get_service_host("kafka", 29092)
        kafka_port = compose.get_service_port("kafka", 29092)
        yield f"{kafka_host}:{kafka_port}"

def test_schema_evolution(kafka_cluster):
    # Test schema compatibility
    # Send messages with different schema versions
    # Verify consumers handle evolution correctly
    pass
```

```javascript
// Node.js example with testcontainers
const { KafkaContainer } = require('@testcontainers/kafka');
const { SchemaRegistry } = require('@kafkajs/confluent-schema-registry');

describe('Schema Registry Integration', () => {
  let kafkaContainer;
  let schemaRegistry;

  beforeAll(async () => {
    kafkaContainer = await new KafkaContainer().start();
    // Setup schema registry with testcontainer
  });

  test('should handle schema evolution', async () => {
    // Test schema compatibility scenarios
  });
});
```

### 8.3 Demo Rehearsal Testing
- **Timing validation**: Complete demo within 20 minutes
- **Failure injection**: Test error scenarios and recovery
- **Audience interaction**: Practice Q&A scenarios

---

## 9. Documentation Requirements

### 9.1 Setup Documentation
- **README.md**: Quick start guide with prerequisites
- **SETUP.md**: Detailed installation instructions
- **TROUBLESHOOTING.md**: Common issues and solutions

### 9.2 Demo Script Documentation
- **DEMO_SCRIPT.md**: Step-by-step demo execution guide
- **TIMING_GUIDE.md**: Checkpoint timing for each demo section
- **BACKUP_PLANS.md**: Alternative approaches for common failures

### 9.3 Code Documentation
- **Inline comments**: Explain demo-specific code choices
- **API documentation**: Service endpoints and schemas
- **Configuration guide**: Environment variables and settings

---

## 10. Success Metrics

### 10.1 Technical Metrics
- **Demo completion rate**: >95% successful runs
- **Setup time**: <10 minutes average
- **Error recovery time**: <30 seconds average
- **Audience engagement**: Interactive participation during demo

### 10.2 Educational Metrics
- **Concept clarity**: Audience understands Schema Registry value proposition
- **Practical application**: Audience can replicate demo locally
- **Q&A quality**: Questions indicate deep understanding vs confusion

---

## Appendix A: Makefile Commands Reference

```makefile
# Quick reference for demo execution
make help            # 📋 Show all available commands
make setup           # 🏗️  Local Docker environment  
make setup-cloud     # ☁️  Confluent Cloud environment
make demo-broken     # 💥 Start with serialization failures
make demo-fixed      # ✅ Switch to Schema Registry
make demo-evolution  # 🔄 Show schema evolution
make demo-reset      # 🔄 Reset for next demo run
make clean          # 🧹 Full cleanup
make status         # 📊 Check service health
make logs           # 📜 Show service logs
```

## Appendix B: GitHub Repository Structure

```
kafka-schema-demo/
├── 📁 services/
│   ├── 📁 order-service/         (Java/Spring Boot + Gradle/Kotlin)
│   │   ├── build.gradle.kts      (Kotlin DSL build script)
│   │   ├── gradle/wrapper/       (Gradle wrapper)
│   │   ├── gradlew              (Gradle wrapper script)
│   │   └── src/main/avro/       (Avro schema sources)
│   ├── 📁 inventory-service/     (Python/FastAPI + uv)
│   │   ├── pyproject.toml       (uv project file)
│   │   └── scripts/generate_classes.py
│   └── 📁 analytics-api/         (Node.js/Express + TypeScript)
│       ├── package.json
│       └── src/generated/       (Generated TypeScript interfaces)
├── 📁 scripts/
│   ├── wait-for-services.sh
│   ├── start-broken-services.sh
│   ├── start-avro-services.sh
│   └── cleanup-*.sh
├── 📁 schemas/                   (Central schema repository)
│   ├── order-event.avsc
│   ├── user-event.avsc
│   └── payment-event.avsc
├── 📁 docs/
│   ├── SETUP.md
│   ├── DEMO_SCRIPT.md
│   ├── GRADLE_GUIDE.md          (Gradle + Kotlin DSL guide)
│   └── TROUBLESHOOTING.md
├── docker-compose.yml
├── docker-compose.cloud.yml
├── Makefile                     (Uses gradlew for Java builds)
└── README.md
```

## Appendix B: Emergency Contacts

- **Infrastructure Support**: Viktor Gamov (primary presenter)
- **Backup Presenter**: [TBD]
- **Technical Support**: Conference IT team