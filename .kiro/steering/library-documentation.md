# Library and API Documentation

## Always Consult Up-to-Date Documentation

When writing code that uses external libraries, frameworks, or APIs, **always consult Context7 or Exa MCP** to get the most current documentation and best practices.

## When to Use These Tools

Use Context7 or Exa MCP when:
- Implementing features with Spring Boot, Spring Kafka, or other Java frameworks
- Working with Python libraries like FastAPI, confluent-kafka, or pydantic
- Using Node.js/TypeScript libraries like Express, KafkaJS, or Schema Registry clients
- Integrating with Kafka, Schema Registry, or Avro serialization
- Learning about API endpoints, configuration options, or usage patterns
- Troubleshooting library-specific issues or errors
- Understanding breaking changes between versions

## How to Use

**Context7** - For official library documentation:
1. First resolve the library ID: `resolve-library-id` with the library name
2. Then fetch docs: `get-library-docs` with the resolved ID and relevant topic

**Exa MCP** - For code examples and implementation patterns:
- Use `get_code_context_exa` with specific queries like:
  - "Spring Kafka Avro serializer configuration"
  - "FastAPI async Kafka consumer example"
  - "Express TypeScript WebSocket integration"

## Why This Matters

- Libraries evolve rapidly with breaking changes
- Official documentation is more reliable than LLM training data
- Avoids deprecated patterns and outdated APIs
- Ensures compatibility with the specific versions used in this project

## Project-Specific Libraries to Watch

- **Confluent Platform** (8.1.0) - Kafka and Schema Registry APIs
- **Spring Boot** (3.5.7) - Configuration and dependency injection patterns
- **FastAPI** (0.121.0) - Async patterns and dependency injection
- **@confluentinc/kafka-javascript** (1.6.0) - Node.js Kafka client
- **@confluentinc/schemaregistry** (1.6.0) - Schema Registry client for Node.js

Always verify current best practices before implementing new features or refactoring existing code.
