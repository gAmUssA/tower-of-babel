---
trigger: always_on
description: 
globs: 
---

# Kafka & Schema Registry Core Patterns

This is a multi-language Kafka Schema Registry demonstration with three microservices:
- **Order Service**: Java 17 + Spring Boot 3.x + Kotlin (port 9080)
- **Inventory Service**: Python 3.9+ + FastAPI (port 9000)  
- **Analytics API**: Node.js 18+ + Express + TypeScript (port 9300)
- **Infrastructure**: Kafka + Schema Registry (Confluent Platform 7.9.x, KRaft mode)

## Infrastructure Configuration

- Kafka broker: `localhost:29092` (external), `kafka:9092` (internal Docker)
- Schema Registry: `http://localhost:8081`
- Project uses KRaft mode (NO Zookeeper)
- Start infrastructure: `docker-compose up -d` then `./scripts/wait-for-services.sh`

## Schema Management Principles

ALWAYS:
- Define schemas in `schemas/` directory before implementing services
- Use backward-compatible evolution when adding fields
- Include default values for all new optional fields
- Version schemas: v1/ for initial, v2/ for evolved versions
- Regenerate code after schema changes: `make generate`

NEVER:
- Modify generated Avro classes directly
- Remove required fields from existing schemas
- Change field types in published schemas
- Commit Schema Registry credentials to repository

## Schema Evolution Pattern

When evolving schemas:
```json
// Add new fields with union types and defaults
{"name": "newField", "type": ["null", "string"], "default": null}
{"name": "metadata", "type": ["null", {"type": "map", "values": "string"}], "default": null}
```

## Kafka Topic Naming

- Use lowercase with hyphens: `order-events`, `inventory-updates`
- Prefix test topics: `test-[topic-name]`
- Avoid underscores in topic names

## Error Handling

- Route malformed messages to dead letter queue topics: `[topic-name]-dlq`
- Include correlation IDs in all inter-service messages
- Log Schema Registry errors with schema subject and version info
- Implement circuit breaker for Schema Registry unavailability	