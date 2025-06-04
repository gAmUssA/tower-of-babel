# Implementation Task List: Tower of Babel to Babel Fish Demo

This task list is derived from the implementation plan in `docs/plan.md` and organized by development phases.

---

## Phase 1: Infrastructure Foundation (Week 1)

### 1.1 Docker Environment Setup
- [x] 1.1.1 Create `docker-compose.yml` with Kafka KRaft configuration
- [x] 1.1.2 Configure Kafka service (confluentinc/cp-kafka:7.9.0)
  - [x] Set up KRaft mode (no Zookeeper)
  - [x] Configure internal listener (kafka:9092)
  - [x] Configure external listener (localhost:29092)
  - [x] Set up environment variables for KRaft
- [x] 1.1.3 Configure Schema Registry service (confluentinc/cp-schema-registry:7.9.0)
  - [x] Set up Schema Registry on port 8081
  - [x] Configure connection to Kafka
  - [x] Set up proper dependencies and health checks
- [x] 1.1.4 Configure Kafka UI service (provectuslabs/kafka-ui:latest)
  - [x] Set up Kafka UI on port 8080
  - [x] Configure connection to Kafka and Schema Registry
  - [x] Set up environment variables

### 1.2 Service Health Checks
- [x] 1.2.1 Implement Kafka health check script
- [x] 1.2.2 Implement Schema Registry health check script
- [x] 1.2.3 Create `scripts/wait-for-services.sh` script
- [x] 1.2.4 Test complete stack startup (target: <3 minutes)

### 1.3 Network and Port Configuration
- [x] 1.3.1 Validate port allocation strategy (8080, 8081, 9000, 9080, 9300, 29092)
- [x] 1.3.2 Test external connectivity to Kafka (localhost:29092)
- [x] 1.3.3 Test Schema Registry API access (localhost:8081)
- [x] 1.3.4 Verify Kafka UI access (localhost:8080)

### 1.4 Alternative Deployment Options
- [x] 1.4.1 Create `docker-compose.cloud.yml` for Confluent Cloud
- [x] 1.4.2 Document environment variables for cloud deployment
- [x] 1.4.3 Create `.env.example` file with configuration templates

---

## Phase 2: Schema-First Development (Week 2)

### 2.1 Central Schema Repository
- [x] 2.1.1 Create `schemas/` directory structure
- [x] 2.1.2 Design `schemas/order-event.avsc` (V1)
  - [x] Define basic fields: orderId, userId, amount, status
  - [x] Add proper documentation and namespaces
  - [x] Validate Avro schema syntax
- [x] 2.1.3 Design `schemas/user-event.avsc`
- [x] 2.1.4 Design `schemas/payment-event.avsc`
- [x] 2.1.5 Plan schema evolution scenarios (V2, V3 versions)

### 2.2 Java Code Generation (Gradle + Kotlin DSL)
- [x] 2.2.1 Create `services/order-service/` directory structure
- [x] 2.2.2 Set up `build.gradle.kts` with Kotlin DSL
- [x] 2.2.3 Configure Gradle Avro plugin
- [x] 2.2.4 Set up code generation from `schemas/` directory
- [x] 2.2.5 Configure generated code output to `build/generated-main-avro-java/`
- [x] 2.2.6 Test code generation with `./gradlew generateAvroJava`
- [x] 2.2.7 Integrate code generation into build process

### 2.3 Python Code Generation (uv + FastAPI)
- [x] 2.3.1 Create `services/inventory-service/` directory structure
- [x] 2.3.2 Set up `pyproject.toml` with uv configuration
- [x] 2.3.3 Create `scripts/generate_classes.py` for Avro code generation
- [x] 2.3.4 Configure output to `src/generated/` directory
- [x] 2.3.5 Test Python dataclass generation
- [x] 2.3.6 Integrate generation into uv workflow

### 2.4 Node.js/TypeScript Code Generation
- [x] 2.4.1 Create `services/analytics-api/` directory structure
- [x] 2.4.2 Set up `package.json` with TypeScript configuration
- [x] 2.4.3 Create custom TypeScript code generation script
- [x] 2.4.4 Configure code generation scripts
- [x] 2.4.5 Set up output to `src/generated/` directory
- [x] 2.4.6 Test TypeScript interface generation
- [x] 2.4.7 Integrate into npm build process

### 2.5 Cross-Language Validation
- [x] 2.5.1 Generate code for all languages from same schema
- [x] 2.5.2 Validate field name consistency across languages
- [x] 2.5.3 Validate type mapping correctness
- [x] 2.5.4 Test schema changes trigger regeneration in all languages

---

## Phase 3: Broken Services Implementation (Week 3)

### 3.1 Order Service - Java Serialization Failures
- [x] 3.1.1 Implement basic Spring Boot application structure
- [x] 3.1.2 Create `OrderController` with REST endpoints
- [x] 3.1.3 Implement Java Object Serialization producer
- [x] 3.1.4 Add configuration for different serialization modes
- [x] 3.1.5 Create `/orders/broken` endpoint for intentional failures
- [x] 3.1.6 Add health check endpoint
- [x] 3.1.7 Configure application port 9080

### 3.2 Inventory Service - JSON Deserialization Issues
- [x] 3.2.1 Implement basic FastAPI application structure
- [x] 3.2.2 Create Kafka consumer for order events
- [x] 3.2.3 Implement JSON deserializer with field name mismatches
- [x] 3.2.4 Create API endpoints for inventory status
- [x] 3.2.5 Add error handling for deserialization failures
- [x] 3.2.6 Configure service port 9000
- [x] 3.2.7 Add health check endpoint

### 3.3 Analytics API - Type Inconsistency Failures
- [x] 3.3.1 Implement basic Express + TypeScript application
- [x] 3.3.2 Create Kafka consumer for analytics events
- [x] 3.3.3 Implement type mismatch scenarios (string vs number)
- [x] 3.3.4 Create analytics dashboard endpoints
- [x] 3.3.5 Add real-time data visualization
- [x] 3.3.6 Configure service port 9300
- [x] 3.3.7 Add health check endpoint

### 3.4 Failure Scenario Testing
- [x] 3.4.1 Test Java serialization → Python deserialization failure
- [x] 3.4.2 Test JSON field name mismatch failures
- [x] 3.4.3 Test type inconsistency failures
- [x] 3.4.4 Ensure error messages are educational
- [x] 3.4.5 Create scripts to trigger specific failure scenarios
- [x] 3.4.6 Document expected vs actual behavior for demo

---

## Phase 4: Schema Registry Integration (Week 4) ✅

### 4.1 Avro Producer Implementation ✅
- [x] 4.1.1 Replace Java serialization with Avro serialization in Order Service
- [x] 4.1.2 Configure Confluent Avro serializer
- [x] 4.1.3 Use generated POJOs instead of manual classes
- [x] 4.1.4 Add Schema Registry URL configuration
- [x] 4.1.5 Test message production with Avro format

### 4.2 Avro Consumer Implementation ✅
- [x] 4.2.1 Replace JSON deserializer with Avro in Inventory Service
- [x] 4.2.2 Configure Confluent Avro deserializer
- [x] 4.2.3 Use generated Python dataclasses
- [x] 4.2.4 Add Schema Registry configuration
- [x] 4.2.5 Test message consumption with Avro format

### 4.3 Analytics Service Avro Integration ✅
- [x] 4.3.1 Replace manual types with generated TypeScript interfaces
- [x] 4.3.2 Configure Avro deserializer for Node.js
- [x] 4.3.3 Update dashboard to use generated types
- [x] 4.3.4 Test end-to-end Avro message flow

### 4.4 End-to-End Validation ✅
- [x] 4.4.1 Test complete message flow: Java → Python → Node.js
- [x] 4.4.2 Validate all services use generated code (no manual classes)
- [x] 4.4.3 Verify type safety at compile time
- [x] 4.4.4 Test Schema Registry subject registration
- [x] 4.4.5 Validate message compatibility across languages

### 4.5 Additional Improvements ✅
- [x] 4.5.1 Fix Inventory Service Avro integration issues with confluent-kafka
- [x] 4.5.2 Create Python smoke test for Inventory Service
- [x] 4.5.3 Integrate smoke test into GitHub Actions workflow
- [x] 4.5.4 Fix Analytics dashboard timestamp parsing issues
- [x] 4.5.5 Enhance phase4-demo.sh script for better reliability

---

## Phase 5: Evolution and Automation (Week 5)

### 5.1 Schema Evolution Implementation
- [x] 5.1.1 Create order-event.avsc V2 with optional fields
- [x] 5.1.2 Test backward compatibility (old consumers, new producers)
- [x] 5.1.3 Test forward compatibility (new consumers, old producers)
- [x] 5.1.4 Create incompatible schema change (V3) for rejection demo
- [x] 5.1.5 Test Schema Registry compatibility validation
- [x] 5.1.6 Document evolution scenarios for demo

### 5.2 Makefile Automation
- [x] 5.2.1 Create Makefile with emoji and color support
- [x] 5.2.2 Implement `make help` with command documentation
- [x] 5.2.3 Implement `make setup` for Docker environment
- [x] 5.2.4 Implement `make setup-cloud` for Confluent Cloud
- [x] 5.2.5 Implement `make demo-broken` to start failure scenarios
- [x] 5.2.6 Implement `make demo-fixed` to switch to Avro
- [x] 5.2.7 Implement `make demo-evolution` for schema changes
- [x] 5.2.8 Implement `make demo-reset` for clean state
- [x] 5.2.9 Implement `make generate` for code generation
- [x] 5.2.10 Implement `make build` for all services
- [x] 5.2.11 Implement `make clean` for cleanup
- [x] 5.2.12 Implement `make status` for service monitoring

### 5.3 Demo State Management
- [x] 5.3.1 Create `scripts/cleanup-topics.sh`
- [x] 5.3.2 Create `scripts/cleanup-schemas.sh`
- [x] 5.3.3 Create `scripts/start-broken-services.sh`
- [x] 5.3.4 Create `scripts/start-avro-services.sh`
- [x] 5.3.5 Create `scripts/stop-broken-services.sh`
- [x] 5.3.6 Create `scripts/evolve-schema.sh`
- [x] 5.3.7 Test demo reset time (target: <30 seconds)

### 5.4 Code Generation Automation
- [x] 5.4.1 Implement `make demo-codegen` command
- [x] 5.4.2 Show schema definition in demo
- [x] 5.4.3 Demonstrate live code generation
- [x] 5.4.4 Show generated artifacts in all languages
- [x] 5.4.5 Demonstrate schema evolution with code regeneration

---

## Phase 6: Polish and Testing (Week 6)

### 6.1 Integration Testing
- [ ] 6.1.1 Set up Testcontainers for Java service tests
- [ ] 6.1.2 Create integration tests for order service
- [ ] 6.1.3 Set up pytest for Python service tests
- [ ] 6.1.4 Create integration tests for inventory service
- [ ] 6.1.5 Set up Jest/Mocha for Node.js service tests
- [ ] 6.1.6 Create integration tests for analytics service
- [ ] 6.1.7 Implement `make test` command for all tests
- [ ] 6.1.8 Create end-to-end integration test suite

### 6.2 Performance Validation
- [ ] 6.2.1 Measure and optimize stack startup time
- [ ] 6.2.2 Measure and optimize demo reset time
- [ ] 6.2.3 Test message latency end-to-end
- [ ] 6.2.4 Validate UI responsiveness
- [ ] 6.2.5 Load test with multiple message scenarios

### 6.3 Demo Script Creation
- [ ] 6.3.1 Create `docs/DEMO_SCRIPT.md` with step-by-step guide
- [ ] 6.3.2 Create `docs/TIMING_GUIDE.md` with checkpoints
- [ ] 6.3.3 Create `docs/BACKUP_PLANS.md` for failure scenarios
- [ ] 6.3.4 Practice demo execution and timing
- [ ] 6.3.5 Create presenter notes and talking points

### 6.4 Documentation Completion
- [ ] 6.4.1 Create `docs/SETUP.md` for environment setup
- [ ] 6.4.2 Create `docs/GRADLE_GUIDE.md` for Gradle + Kotlin DSL
- [ ] 6.4.3 Create `docs/CODE_GENERATION.md` for schema-first development
- [ ] 6.4.4 Create `docs/TROUBLESHOOTING.md` for common issues
- [ ] 6.4.5 Update `README.md` with quick start guide
- [ ] 6.4.6 Add API documentation for all services
- [ ] 6.4.7 Document environment variables and configuration

### 6.5 Repository Organization
- [ ] 6.5.1 Organize final directory structure
- [ ] 6.5.2 Add `.gitignore` files for each service
- [ ] 6.5.3 Add LICENSE file
- [ ] 6.5.4 Create comprehensive README.md
- [ ] 6.5.5 Add example configuration files
- [ ] 6.5.6 Tag repository for stable release

---

## Ongoing Tasks (All Phases)

### Project Management
- [ ] Track progress against timeline
- [ ] Update documentation as implementation evolves
- [ ] Test demo scenarios regularly
- [ ] Maintain task list completion status

### Quality Assurance
- [ ] Code review for all implementations
- [ ] Test error scenarios for educational value
- [ ] Validate cross-platform compatibility
- [ ] Ensure demo reliability (>95% success rate)

### Risk Mitigation
- [ ] Create backup deployment options
- [ ] Test recovery scenarios
- [ ] Prepare alternative demo paths
- [ ] Document troubleshooting procedures

---

## Success Criteria Checklist

### Technical Validation
- [ ] Complete stack starts in <3 minutes
- [ ] Demo reset completes in <30 seconds
- [ ] All services communicate via generated code
- [ ] Schema evolution works correctly
- [ ] Error scenarios are educational and repeatable

### Demo Readiness
- [ ] 20-minute demo timing achieved
- [ ] All scenarios execute reliably
- [ ] Clear before/after value demonstration
- [ ] Audience can replicate locally
- [ ] Backup plans tested and ready

### Documentation Quality
- [ ] Setup instructions are clear and complete
- [ ] Troubleshooting guides cover common issues
- [ ] API documentation is comprehensive
- [ ] Repository structure is intuitive
- [ ] Code examples are educational

---

## Notes
- Mark completed tasks with [x]
- Update this list as implementation progresses
- Add new tasks as requirements evolve
- Track blocked tasks and dependencies
- Document lessons learned and improvements
