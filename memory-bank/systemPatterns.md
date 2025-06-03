# Tower of Babel System Patterns

## Coding Patterns

### Python
- Use virtual environments for dependency management
- Use python-dotenv for environment variable management
- Follow FastAPI patterns for API development

### Java/Kotlin
- Use Gradle with Kotlin DSL for build scripts
- Follow Spring Boot patterns for application development

### Node.js/TypeScript
- Use TypeScript for type safety
- Handle errors with proper typing (use `any` when necessary)

## Architecture Patterns

### Microservices
- Order Service (Java/Kotlin)
- Inventory Service (Python)
- Analytics API (Node.js/TypeScript)

### Messaging
- Use Kafka for inter-service communication
- Use confluent-kafka images in Kraft mode without Zookeeper
- Use port 9092 for internal Kafka listener, 29092 for external (localhost)

### Docker
- Use Docker Compose for container orchestration
- Don't add version attribute for docker-compose.yaml file
- Use Confluent images for Kafka (confluentinc/cp-kafka:7.9.0)
- Use Confluent images for Schema Registry (confluentinc/cp-schema-registry:7.9.0)

## Testing Patterns
- Demo scripts to showcase failure scenarios
- Health checks before running failure scenarios

## Build and Clean Patterns
- Use Makefile with emoji and ASCII colors for better readability
- Service-specific clean tasks to remove all build artifacts:
  - Java: Use Gradle's clean task
  - Python: Remove __pycache__ and .pytest_cache directories
  - Node.js: Remove dist and node_modules directories
- Service-specific build tasks with proper dependency management:
  - Java: Use Gradle build with --info flag
  - Python: Use virtual environments consistently
  - Node.js: Use npm ci for reliable dependency installation
- Generate code from schemas before building services

[2025-06-03 11:31:30] - Initial system patterns created
[2025-06-03 11:48:51] - Added build and clean patterns
