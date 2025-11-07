# Test Scripts

Automated test suites for validating the Tower of Babel demo scenarios.

## Test Suites

### Test 1: Serialization Failures

**Script:** `test-1-serialization-failures.sh`

Tests the Tower of Babel scenarios:
- Java serialization causes deserialization errors
- JSON field name mismatches with guessing
- Type inconsistencies

**Usage:**
```bash
./scripts/test/test-1-serialization-failures.sh
```

### Test 2: Avro Integration

**Script:** `test-2-avro-integration.sh`

Comprehensive tests for Avro serialization with Schema Registry:
- Schema registration
- Order creation with Avro
- Python deserialization (Inventory Service)
- TypeScript deserialization (Analytics API)
- Error detection
- Schema validation

**Usage:**
```bash
./scripts/test/test-2-avro-integration.sh
```

### Test 3: Schema Evolution

**Script:** `test-3-schema-evolution.sh`

Tests safe schema evolution:
- v2 schema compatibility with v1
- Schema registration
- Multiple version management

**Usage:**
```bash
./scripts/test/test-3-schema-evolution.sh
```

### Test 4: Compatibility Checks

**Script:** `test-4-compatibility-checks.sh`

Tests breaking change prevention:
- Removing required fields (should be rejected)
- Changing field types (should be rejected)
- Adding optional fields (should be allowed)

**Usage:**
```bash
./scripts/test/test-4-compatibility-checks.sh
```

## Running All Tests

```bash
# Run all test suites
for test in scripts/test/test-*.sh; do
    echo "Running $test..."
    $test
    echo ""
done
```

Or create a test runner:

```bash
#!/bin/bash
PASSED=0
FAILED=0

for test in scripts/test/test-*.sh; do
    if $test; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi
done

echo "Total: $((PASSED + FAILED)) tests"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
```

## Prerequisites

All services must be running:

```bash
make run-kafka              # Kafka + Schema Registry
make run-order-service      # Java/Spring Boot
make run-inventory-service  # Python/FastAPI
make run-analytics-api      # Node.js/Express
```

## Exit Codes

- `0` - All tests passed
- `1` - One or more tests failed

## CI/CD Integration

These tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Run integration tests
  run: |
    ./scripts/test/test-1-serialization-failures.sh
    ./scripts/test/test-2-avro-integration.sh
    ./scripts/test/test-3-schema-evolution.sh
    ./scripts/test/test-4-compatibility-checks.sh
```

## Troubleshooting

**Tests failing unexpectedly:**
1. Check service health: `make status`
2. View logs: `make logs`
3. Reset environment: `./scripts/utils/cleanup-topics.sh && ./scripts/utils/cleanup-schemas.sh`
4. Restart services

**Schema Registry issues:**
```bash
curl http://localhost:8081/subjects  # Check registered schemas
./scripts/utils/cleanup-schemas.sh   # Clean up if needed
```
