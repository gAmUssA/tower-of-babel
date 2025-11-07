# Utility Scripts

This directory contains utility scripts for managing Kafka, Schema Registry, and related infrastructure.

## Available Utilities

### Schema Management

**cleanup-schemas.sh**
- Deletes all subjects from Schema Registry
- Useful for resetting demo environment
- Usage: `./scripts/utils/cleanup-schemas.sh`

**register-schemas.sh**
- Registers Avro schemas with Schema Registry
- Supports multiple schema versions
- Usage: `./scripts/utils/register-schemas.sh`

**evolve-schema.sh**
- Helper functions for schema evolution
- Includes `register_schema()` and `test_compatibility()` functions
- Used by demo scripts
- Usage: Source this file in other scripts

### Topic Management

**cleanup-topics.sh**
- Deletes all application topics from Kafka
- Preserves internal topics (__consumer_offsets, _schemas)
- Usage: `./scripts/utils/cleanup-topics.sh`

### Service Management

**wait-for-services.sh**
- Waits for services to become healthy
- Includes health check functions
- Used by demo and test scripts
- Usage: Source this file in other scripts

## Common Workflows

### Reset Demo Environment

```bash
# Clean up everything
./scripts/utils/cleanup-topics.sh
./scripts/utils/cleanup-schemas.sh

# Re-register schemas
./scripts/utils/register-schemas.sh
```

### Check Schema Registry

```bash
# List all subjects
curl http://localhost:8081/subjects | jq .

# Get latest version of a subject
curl http://localhost:8081/subjects/orders-value/versions/latest | jq .

# Check compatibility mode
curl http://localhost:8081/config | jq .
```

### Check Kafka Topics

```bash
# List all topics
docker-compose exec kafka kafka-topics --bootstrap-server kafka:9092 --list

# Describe a topic
docker-compose exec kafka kafka-topics --bootstrap-server kafka:9092 --describe --topic orders
```

## Notes

- These utilities are designed to work with the local Docker Compose environment
- For Confluent Cloud, use the cloud-specific scripts in the root scripts directory
- Always check service health before running utilities
