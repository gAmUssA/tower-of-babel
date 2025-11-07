# Incompatible Schema Examples

This directory contains examples of **breaking schema changes** that violate backward compatibility rules. These schemas are used in Demo 4 to demonstrate how Schema Registry prevents incompatible changes.

## Breaking Change Examples

### 1. order-event.avsc - Removed Required Field
**Breaking Change**: Removed the required `userId` field

**Why it's incompatible**: 
- Old consumers expect `userId` to be present in every message
- If this schema is used, old consumers will fail when trying to read the field
- Violates BACKWARD compatibility

**Demo 4 Test 1**: Attempts to remove `userId` field

---

### 2. order-event-type-change.avsc - Changed Field Type
**Breaking Change**: Changed `amount` from `double` to `string`

**Why it's incompatible**:
- Old consumers expect `amount` to be a numeric double value
- Type changes are not compatible in Avro
- Consumers will fail to deserialize the field
- Violates BACKWARD compatibility

**Demo 4 Test 2**: Attempts to change `amount` type from double → string

---

### 3. order-event-field-rename.avsc - Renamed Field
**Breaking Change**: Renamed `orderId` to `id`

**Why it's incompatible**:
- Avro treats this as removing `orderId` and adding `id`
- Old consumers looking for `orderId` will not find it
- Field renames require aliases to maintain compatibility
- Violates BACKWARD compatibility

**Demo 4 Test 3**: Attempts to rename `orderId` → `id`

---

## How Schema Registry Protects Against These

When you attempt to register any of these schemas:

1. **Compatibility Check**: Schema Registry compares against existing versions
2. **Validation Fails**: Detects the breaking change
3. **Registration Blocked**: Returns HTTP 409 error
4. **Error Message**: Explains why the schema is incompatible

This prevents producers from using incompatible schemas, protecting all consumers from breaking changes.

## Compatibility Modes

Schema Registry supports different compatibility modes:

- **BACKWARD** (default): New schema can read old data
- **FORWARD**: Old schema can read new data  
- **FULL**: Both backward and forward compatible
- **NONE**: No compatibility checks (not recommended)

All examples in this directory violate BACKWARD compatibility.

## Safe Alternatives

Instead of these breaking changes, use safe evolution patterns:

- **Don't remove fields**: Mark as deprecated instead
- **Don't change types**: Add new field with new type
- **Don't rename fields**: Use Avro aliases or add new field
- **Add optional fields**: Use union types with null default

See `schemas/v2/order-event.avsc` for examples of safe schema evolution.
