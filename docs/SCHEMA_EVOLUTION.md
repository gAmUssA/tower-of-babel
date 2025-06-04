# Schema Evolution Demo Guide

This document describes the schema evolution scenarios implemented in Phase 5 and how to demonstrate them.

## Overview

Schema evolution demonstrates how Schema Registry enables safe changes to data formats over time while maintaining compatibility between producers and consumers using different schema versions.

## Evolution Scenarios

### 1. Backward Compatibility (V1 → V2)

**Scenario**: Adding optional fields to an existing schema
**Schema**: `schemas/v1/order-event.avsc` → `schemas/v2/order-event.avsc`

**V1 Schema (Original)**:
```json
{
  "type": "record",
  "name": "OrderEvent",
  "namespace": "com.company.orders",
  "fields": [
    {"name": "orderId", "type": "string"},
    {"name": "userId", "type": "string"},
    {"name": "amount", "type": "double"},
    {"name": "status", "type": "string"}
  ]
}
```

**V2 Schema (Enhanced)**:
```json
{
  "type": "record",
  "name": "OrderEvent",
  "namespace": "com.company.orders",
  "fields": [
    {"name": "orderId", "type": "string"},
    {"name": "userId", "type": "string"},
    {"name": "amount", "type": "double"},
    {"name": "status", "type": "string"},
    {"name": "orderTimestamp", "type": ["null", "long"], "default": null},
    {"name": "metadata", "type": ["null", {"type": "map", "values": "string"}], "default": null}
  ]
}
```

**Key Changes**:
- Added `orderTimestamp` as optional field with null default
- Added `metadata` as optional map with null default

**Compatibility**: ✅ **BACKWARD COMPATIBLE**
- Old consumers (V1) can read messages produced by new producers (V2)
- New optional fields are ignored by old consumers
- Default values ensure no data corruption

### 2. Forward Compatibility (V2 → V1)

**Scenario**: New consumers reading old data
**Result**: ✅ **FORWARD COMPATIBLE**
- New consumers (V2) can read messages produced by old producers (V1)
- Missing optional fields use their default values (null)
- No data loss occurs

### 3. Incompatible Changes (V3)

**Scenario**: Removing required fields or breaking changes
**Schema**: `schemas/incompatible/order-event.avsc`

```json
{
  "type": "record",
  "name": "OrderEvent",
  "namespace": "com.company.orders",
  "fields": [
    {"name": "orderId", "type": "string"},
    {"name": "amount", "type": "double"},
    {"name": "status", "type": "string"},
    {"name": "orderTimestamp", "type": "long"}
  ]
}
```

**Breaking Changes**:
- Removed required field `userId`
- Made `orderTimestamp` required (non-nullable)

**Compatibility**: ❌ **NOT COMPATIBLE**
- Schema Registry will reject this schema
- Demonstrates protection against breaking changes

## Demo Commands

### Run Complete Evolution Demo
```bash
make demo-evolution
```

### Step-by-Step Manual Demo

1. **Setup Environment**:
   ```bash
   make setup
   ```

2. **Register V1 Schema**:
   ```bash
   curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
     --data '{"schema":"'$(cat schemas/v1/order-event.avsc | jq -c tostring)'"}" \
     http://localhost:8081/subjects/orders-value/versions
   ```

3. **Test V2 Compatibility**:
   ```bash
   curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
     --data '{"schema":"'$(cat schemas/v2/order-event.avsc | jq -c tostring)'"}" \
     http://localhost:8081/compatibility/subjects/orders-value/versions/latest
   ```

4. **Register V2 Schema**:
   ```bash
   curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
     --data '{"schema":"'$(cat schemas/v2/order-event.avsc | jq -c tostring)'"}" \
     http://localhost:8081/subjects/orders-value/versions
   ```

5. **Test Incompatible Schema**:
   ```bash
   curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
     --data '{"schema":"'$(cat schemas/incompatible/order-event.avsc | jq -c tostring)'"}" \
     http://localhost:8081/compatibility/subjects/orders-value/versions/latest
   ```

## Code Generation Impact

When schemas evolve, code generation automatically adapts:

### Java (Gradle + Kotlin DSL)
```bash
cd services/order-service
./gradlew generateAvroJava
```
Generated POJOs reflect the latest schema with:
- New optional fields as nullable types
- Default value handling
- Backward compatibility methods

### Python (FastAPI)
```bash
cd services/inventory-service
python scripts/generate_classes.py
```
Generated dataclasses include:
- Optional fields with default values
- Type hints for better IDE support
- Backward compatibility support

### TypeScript (Node.js)
```bash
cd services/analytics-api
npm run generate-types
```
Generated interfaces provide:
- Optional properties for new fields
- Type safety across schema versions
- IntelliSense support

## Testing Scenarios

### Backward Compatibility Test
1. Start services with V1 schema
2. Produce messages with V1 format
3. Upgrade producer to V2 schema
4. Verify old consumers still work
5. Verify new fields are handled correctly

### Forward Compatibility Test
1. Start services with V2 schema
2. Simulate receiving V1 messages
3. Verify new consumers handle missing fields
4. Verify default values are applied

### Incompatible Change Test
1. Try to register incompatible schema
2. Verify Schema Registry rejects it
3. Demonstrate protection mechanism

## Expected Results

| Test Case | Expected Result | Verification |
|-----------|----------------|--------------|
| V1 → V2 Registration | ✅ Success | Schema ID returned |
| V2 Compatibility Check | ✅ Compatible | `is_compatible: true` |
| V1 Consumer + V2 Producer | ✅ Works | No errors, new fields ignored |
| V2 Consumer + V1 Producer | ✅ Works | Default values used |
| Incompatible Registration | ❌ Rejected | Error response |
| Incompatible Compatibility | ❌ Not Compatible | `is_compatible: false` |

## Demo Talking Points

1. **Schema-First Development**:
   - Schemas define the contract
   - Code generation ensures consistency
   - Compile-time safety across languages

2. **Safe Evolution**:
   - Add optional fields safely
   - Remove fields with care
   - Schema Registry enforces rules

3. **Cross-Language Support**:
   - Java, Python, and TypeScript
   - Same schema, different implementations
   - Type safety maintained

4. **Production Readiness**:
   - Gradual rollouts possible
   - No service downtime required
   - Automatic compatibility checking

## Troubleshooting

### Schema Registry Not Available
```bash
# Check if running
curl http://localhost:8081/subjects

# Restart if needed
make setup
```

### Compatibility Errors
- Check schema syntax with `jq .` validation
- Verify required fields are not removed
- Ensure new fields have default values

### Code Generation Issues
```bash
# Clean and regenerate
make clean
make generate
```
