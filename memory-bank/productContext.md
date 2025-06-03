# Tower of Babel Project Context

## Project Overview
Tower of Babel is a project that demonstrates serialization and deserialization issues across different programming languages and services. It showcases how data format mismatches can lead to failures when services written in different languages (Java, Python, Node.js) communicate with each other.

## Components
1. **Order Service (Java/Kotlin)**: Handles order processing and uses Kafka for message publishing.
2. **Inventory Service (Python)**: Processes inventory updates based on orders received via Kafka.
3. **Analytics API (Node.js/TypeScript)**: Collects and analyzes order data, providing real-time updates and error reporting.

## Organization
- **Services**: Contains the three microservices (order-service, inventory-service, analytics-api)
- **Scripts**: Contains demo scripts to trigger various failure scenarios
- **Schemas**: Contains schema definitions for data exchange
- **Docs**: Project documentation

## Standards
- **Kafka**: Used for message passing between services (localhost:29092)
- **Docker Compose**: Used for containerization and service orchestration
- **Gradle with Kotlin DSL**: Used for Java/Kotlin build configuration
- **Environment Variables**: Used for configuration across services
- **Makefiles**: Used for running commands with emoji and ASCII colors for readability

## Phase 3 Implementation
The current focus is on Phase 3, which demonstrates serialization and deserialization failures across different languages:
1. Java native serialization failures
2. JSON field name mismatch failures
3. Type inconsistency failures

[2025-06-03 11:29:00] - Initial project context created
