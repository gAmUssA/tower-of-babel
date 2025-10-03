---
trigger: model_decision
description: Apply when working with Avro schemas, Schema Registry, or schema evolution
globs: 
---

# Schema Evolution Guidelines

## Adding New Schema

1. Create schema in `schemas/v1/`:

```bash
cat > schemas/v1/new-event.avsc << 'EOF'
{
  "type": "record",
  "name": "NewEvent",
  "namespace": "com.company.events",
  "fields": [
    {"name": "id", "type": "string"},
    {"name": "timestamp", "type": "long"}
  ]
}
EOF
```

2. Generate code: `make generate`
3. Implement producers/consumers using generated types

## Evolving Existing Schema

1. Copy to new version: `cp schemas/v1/order-event.avsc schemas/v2/order-event.avsc`

2. Add fields with defaults (backward compatible):
```json
{"name": "orderTimestamp", "type": ["null", "long"], "default": null}
{"name": "metadata", "type": ["null", {"type": "map", "values": "string"}], "default": null}
```

3. Regenerate code: `make generate`
4. Test with both versions

## Compatibility Rules

ALWAYS follow Avro backward compatibility:
- Add new fields with default values
- Use union types with null for optional fields: `["null", "type"]`
- Enable decimal logical types for precision

NEVER:
- Remove required fields
- Change field types
- Rename fields without aliases
- Deploy without compatibility testing

## Code Generation Workflow

Each service generates from central schema repo:

```bash
# All services
make generate

# Per service
cd services/order-service && ./gradlew generateAvroJava
cd services/inventory-service && python3 scripts/generate_classes.py  
cd services/analytics-api && npm run generate-types
```

CRITICAL: Always regenerate after schema changes. Build process copies schemas from `schemas/v1/` before generation.

## Testing Schema Compatibility

Test consumer handles both old and new schemas:
- Deserialize v1 messages with v2 consumer
- Deserialize v2 messages with v1 consumer
- Verify default values populate correctly
- Check null handling for new optional fields