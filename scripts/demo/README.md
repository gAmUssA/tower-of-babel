# Demo Scripts

This directory contains demonstration scripts that showcase the evolution from chaotic polyglot Kafka architecture to Schema Registry-managed data contracts.

## Demo Scenarios

### Demo 1: Tower of Babel - Serialization Chaos

**Script:** `demo-1-tower-of-babel.sh`

Demonstrates cross-language serialization failures without Schema Registry:
- Java Object Serialization → Python/Node.js deserialization failures
- JSON field naming inconsistencies (camelCase vs snake_case)
- Type mismatches between languages

**Usage:**
```bash
./scripts/demo/demo-1-tower-of-babel.sh [all|java|json|type]
```

**Options:**
- `all` - Run all chaos scenarios (default)
- `java` - Java serialization failure only
- `json` - JSON field name mismatch only
- `type` - Type inconsistency only

### Demo 2: Babel Fish - Schema Registry Solution

**Scripts:**
- `demo-2-babel-fish.sh` - Simple demonstration
- `demo-2-babel-fish-comprehensive.sh` - Comprehensive test with detailed checks

Shows how Schema Registry enables:
- Centralized schema management
- Automatic code generation
- Type safety across languages (Java, Python, Node.js)

**Usage:**
```bash
./scripts/demo/demo-2-babel-fish.sh
# or
./scripts/demo/demo-2-babel-fish-comprehensive.sh
```

### Demo 3: Safe Evolution - Schema Compatibility

**Script:** `demo-3-safe-evolution.sh`

Demonstrates how Schema Registry enables safe schema evolution:
- Adding optional fields safely
- Backward/forward compatibility checks
- Automatic code regeneration
- No service downtime required

**Usage:**
```bash
./scripts/demo/demo-3-safe-evolution.sh
```

### Demo 4: Prevented Disasters - Breaking Changes Blocked

**Script:** `demo-4-breaking-change-blocked.sh`

Shows how Schema Registry prevents incompatible changes:
- Removing required fields (blocked)
- Incompatible type changes (blocked)
- Field renaming (blocked)
- Compatibility enforcement

**Usage:**
```bash
./scripts/demo/demo-4-breaking-change-blocked.sh
```

## Prerequisites

Before running demos, ensure:

1. **Infrastructure is running:**
   ```bash
   make run-kafka  # Starts Kafka + Schema Registry
   ```

2. **Services are running:**
   ```bash
   make run-order-service      # Java/Spring Boot
   make run-inventory-service  # Python/FastAPI
   make run-analytics-api      # Node.js/Express
   ```

3. **Check status:**
   ```bash
   make status
   ```

## Running All Demos in Sequence

To see the complete story from chaos to solution:

```bash
# 1. Show the problems
./scripts/demo/demo-1-tower-of-babel.sh

# 2. Show the solution
./scripts/demo/demo-2-babel-fish.sh

# 3. Show safe evolution
./scripts/demo/demo-3-safe-evolution.sh

# 4. Show protection from disasters
./scripts/demo/demo-4-breaking-change-blocked.sh
```

## Legacy Scripts (Deprecated)

The following scripts are kept for backward compatibility but are superseded by the new demo scripts:

- `trigger-java-serialization-failure.sh` → Use `demo-1-tower-of-babel.sh java`
- `trigger-json-mismatch-failure.sh` → Use `demo-1-tower-of-babel.sh json`
- `trigger-type-inconsistency-failure.sh` → Use `demo-1-tower-of-babel.sh type`
- `trigger-normal-flow.sh` → Use `demo-2-babel-fish.sh`

## Troubleshooting

**Services not responding:**
```bash
make status  # Check service health
make logs    # View service logs
```

**Schema Registry issues:**
```bash
curl http://localhost:8081/subjects  # List registered schemas
./scripts/utils/cleanup-schemas.sh   # Clean up schemas
```

**Kafka issues:**
```bash
./scripts/utils/cleanup-topics.sh  # Clean up topics
make restart-kafka                 # Restart Kafka
```

## Related Documentation

- [Project README](../../README.md)
- [Requirements](../../docs/requirements.md)
- [Implementation Plan](../../docs/plan.md)
