# Scripts Directory

This directory contains all scripts for the Tower of Babel demo project, organized by purpose.

## Directory Structure

```
scripts/
├── demo/           # User-facing demonstration scripts
├── test/           # Automated test suites
├── utils/          # Utility scripts for infrastructure management
└── *.sh            # Service management scripts
```

## Quick Start

### Run All Demos in Sequence

```bash
# 1. Show the problems (Tower of Babel)
./scripts/demo/demo-1-tower-of-babel.sh

# 2. Show the solution (Babel Fish)
./scripts/demo/demo-2-babel-fish.sh

# 3. Show safe evolution
./scripts/demo/demo-3-safe-evolution.sh

# 4. Show protection from disasters
./scripts/demo/demo-4-breaking-change-blocked.sh
```

### Run All Tests

```bash
./scripts/test/test-1-serialization-failures.sh
./scripts/test/test-2-avro-integration.sh
./scripts/test/test-3-schema-evolution.sh
./scripts/test/test-4-compatibility-checks.sh
```

## Subdirectories

### [demo/](demo/README.md)

User-facing demonstration scripts that showcase the four main scenarios:
1. Tower of Babel - Serialization chaos
2. Babel Fish - Schema Registry solution
3. Safe Evolution - Schema compatibility
4. Prevented Disasters - Breaking change prevention

### [test/](test/README.md)

Automated test suites for validating each scenario:
- Serialization failure tests
- Avro integration tests
- Schema evolution tests
- Compatibility check tests

### [utils/](utils/README.md)

Utility scripts for infrastructure management:
- Schema Registry management
- Kafka topic management
- Service health checks
- Schema evolution helpers

## Service Management Scripts

Located in the root `scripts/` directory:

**start-avro-services.sh**
- Starts all services with Avro serialization enabled
- Usage: `./scripts/start-avro-services.sh`

**start-broken-services.sh**
- Starts services with broken serialization (for demos)
- Usage: `./scripts/start-broken-services.sh`

**stop-broken-services.sh**
- Stops broken services
- Usage: `./scripts/stop-broken-services.sh`

**setup-cloud-config.sh**
- Configures services for Confluent Cloud
- Usage: `./scripts/setup-cloud-config.sh`

## Prerequisites

Before running any scripts:

1. **Start infrastructure:**
   ```bash
   make run-kafka  # Starts Kafka + Schema Registry
   ```

2. **Start services:**
   ```bash
   make run-order-service      # Java/Spring Boot
   make run-inventory-service  # Python/FastAPI
   make run-analytics-api      # Node.js/Express
   ```

3. **Verify status:**
   ```bash
   make status
   ```

## Common Workflows

### Demo Presentation

```bash
# 1. Start infrastructure
make run-kafka

# 2. Start services
make run-order-service
make run-inventory-service
make run-analytics-api

# 3. Run demos in sequence
./scripts/demo/demo-1-tower-of-babel.sh
./scripts/demo/demo-2-babel-fish.sh
./scripts/demo/demo-3-safe-evolution.sh
./scripts/demo/demo-4-breaking-change-blocked.sh
```

### Development Testing

```bash
# Run specific test
./scripts/test/test-2-avro-integration.sh

# Run all tests
for test in scripts/test/test-*.sh; do $test; done
```

### Environment Reset

```bash
# Clean up everything
./scripts/utils/cleanup-topics.sh
./scripts/utils/cleanup-schemas.sh

# Re-register schemas
./scripts/utils/register-schemas.sh
```

## Script Naming Convention

All scripts follow a consistent naming pattern:

- **Demo scripts:** `demo-{number}-{scenario-name}.sh`
  - Example: `demo-1-tower-of-babel.sh`
  
- **Test scripts:** `test-{number}-{test-suite-name}.sh`
  - Example: `test-2-avro-integration.sh`
  
- **Utility scripts:** `{action}-{resource}.sh`
  - Example: `cleanup-schemas.sh`

## Exit Codes

All scripts follow standard exit code conventions:
- `0` - Success
- `1` - Failure or error

## Troubleshooting

**Services not responding:**
```bash
make status  # Check service health
make logs    # View service logs
```

**Schema Registry issues:**
```bash
curl http://localhost:8081/subjects  # List schemas
./scripts/utils/cleanup-schemas.sh   # Clean up
```

**Kafka issues:**
```bash
./scripts/utils/cleanup-topics.sh  # Clean up topics
make restart-kafka                 # Restart Kafka
```

## Related Documentation

- [Project README](../README.md)
- [Demo Scripts](demo/README.md)
- [Test Scripts](test/README.md)
- [Utility Scripts](utils/README.md)
