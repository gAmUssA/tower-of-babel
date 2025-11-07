# Quick Reference Guide

## Demo Scripts - One Command Per Scenario

```bash
# Scenario 1: Tower of Babel (Serialization Chaos)
./scripts/demo/demo-1-tower-of-babel.sh

# Scenario 2: Babel Fish (Schema Registry Solution)
./scripts/demo/demo-2-babel-fish.sh

# Scenario 3: Safe Evolution (Schema Compatibility)
./scripts/demo/demo-3-safe-evolution.sh

# Scenario 4: Prevented Disasters (Breaking Changes)
./scripts/demo/demo-4-breaking-change-blocked.sh
```

## Test Scripts - Validate Each Scenario

```bash
# Test Scenario 1
./scripts/test/test-1-serialization-failures.sh

# Test Scenario 2
./scripts/test/test-2-avro-integration.sh

# Test Scenario 3
./scripts/test/test-3-schema-evolution.sh

# Test Scenario 4
./scripts/test/test-4-compatibility-checks.sh
```

## Utility Scripts - Common Tasks

```bash
# Clean up Schema Registry
./scripts/utils/cleanup-schemas.sh

# Clean up Kafka topics
./scripts/utils/cleanup-topics.sh

# Register schemas
./scripts/utils/register-schemas.sh
```

## Complete Demo Flow

```bash
# 1. Start infrastructure
make run-kafka

# 2. Start services
make run-order-service
make run-inventory-service
make run-analytics-api

# 3. Run all demos
./scripts/demo/demo-1-tower-of-babel.sh
./scripts/demo/demo-2-babel-fish.sh
./scripts/demo/demo-3-safe-evolution.sh
./scripts/demo/demo-4-breaking-change-blocked.sh

# 4. Run all tests
./scripts/test/test-1-serialization-failures.sh
./scripts/test/test-2-avro-integration.sh
./scripts/test/test-3-schema-evolution.sh
./scripts/test/test-4-compatibility-checks.sh
```

## Scenario 1 Options

```bash
# Run all chaos scenarios
./scripts/demo/demo-1-tower-of-babel.sh all

# Run only Java serialization failure
./scripts/demo/demo-1-tower-of-babel.sh java

# Run only JSON field mismatch
./scripts/demo/demo-1-tower-of-babel.sh json

# Run only type inconsistency
./scripts/demo/demo-1-tower-of-babel.sh type
```

## Quick Troubleshooting

```bash
# Check service status
make status

# View logs
make logs

# Reset environment
./scripts/utils/cleanup-topics.sh
./scripts/utils/cleanup-schemas.sh

# Restart Kafka
make restart-kafka
```

## README Locations

- Main: [scripts/README.md](README.md)
- Demos: [scripts/demo/README.md](demo/README.md)
- Tests: [scripts/test/README.md](test/README.md)
- Utils: [scripts/utils/README.md](utils/README.md)
- Migration: [scripts/MIGRATION.md](MIGRATION.md)
