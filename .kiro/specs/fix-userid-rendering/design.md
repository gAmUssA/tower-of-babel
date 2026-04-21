# Design Document

## Overview

This design addresses the userId rendering issue in the analytics dashboard by aligning the TypeScript data types with the Avro schema definition. The core problem is a type mismatch where the Avro schema and Kotlin service use string for userId, but the TypeScript service attempts to convert it to a number, causing NaN values for non-numeric identifiers.

## Architecture

The fix involves four components in the analytics-api service:

1. **Order Model** (`src/models/order.ts`) - Update the userId type from number to string
2. **Avro Consumer** (`src/services/avro-kafka-consumer.ts`) - Remove the parseInt conversion and preserve userId as string
3. **JSON Consumer** (`src/services/kafka-consumer.ts`) - Remove the parseInt conversion and preserve userId as string
4. **Dashboard** (`src/public/dashboard.html`) - Update the active users tracking to work with string userId values

No changes are required to the Avro schemas or the order-service, as they already correctly use string for userId.

## Components and Interfaces

### Order Model Changes

**File:** `services/analytics-api/src/models/order.ts`

Update the Order interface:
```typescript
export interface Order {
  orderId: string;
  userId: string;  // Changed from: number
  amount: string;
  status: string;
  items: any[];
  createdAt: string;
  source?: string;
}
```

**Rationale:** This aligns with the Avro schema definition where userId is type "string" and matches the Kotlin Order model.

### Avro Consumer Changes

**File:** `services/analytics-api/src/services/avro-kafka-consumer.ts`

In the `processMessage` method, update the userId extraction:
```typescript
const order: Order = {
  orderId: decodedMessage.orderId || '',
  userId: decodedMessage.userId?.toString() || '',  // Changed from: parseInt(decodedMessage.userId?.toString() || '0')
  amount: decodedMessage.amount?.toString() || '0',
  status: decodedMessage.status || 'UNKNOWN',
  items: [],
  createdAt: timestamp.toISOString(),
  source: 'avro'
};
```

**Rationale:** This preserves the userId as a string without attempting numeric conversion, preventing NaN values.

### JSON Consumer Changes

**File:** `services/analytics-api/src/services/kafka-consumer.ts`

In the `processMessage` method, update the userId extraction:
```typescript
const order: Order = {
  orderId: data.orderId || '',
  userId: data.userId || '',  // Changed from: parseInt(data.userId || '0')
  amount: data.amount ? data.amount.toString() : '0',
  status: data.status || 'UNKNOWN',
  items: data.items || [],
  createdAt: data.createdAt || new Date().toISOString()
};
```

**Rationale:** This preserves the userId as a string from the JSON payload, matching the Kotlin service's String type and preventing NaN values for non-numeric identifiers.

### Dashboard Changes

**File:** `services/analytics-api/src/public/dashboard.html`

The dashboard already handles userId correctly with the fallback `order.userId || 'N/A'`. However, the active users tracking uses a Set which works with both string and number types, so no changes are needed there. The Set will correctly track unique string userId values.

## Data Models

### Current Flow (Broken)
```
Order Service (Kotlin)
  userId: String = "user-123"
    ↓
Avro Schema
  userId: string
    ↓
Avro Consumer (TypeScript)
  parseInt("user-123") → NaN
    ↓
Order Model (TypeScript)
  userId: number = NaN
    ↓
Dashboard
  NaN || 'N/A' → displays "N/A"
```

### Fixed Flow
```
Order Service (Kotlin)
  userId: String = "user-123"
    ↓
Avro Schema
  userId: string
    ↓
Avro Consumer (TypeScript)
  "user-123".toString() → "user-123"
    ↓
Order Model (TypeScript)
  userId: string = "user-123"
    ↓
Dashboard
  "user-123" || 'N/A' → displays "user-123"
```

## Error Handling

No additional error handling is required. The current error handling in the Avro consumer will continue to work:
- Empty or missing userId will default to empty string `''`
- The dashboard will display empty string or fall back to 'N/A' if the value is falsy
- The `.toString()` call is safe because it's called on the optional chaining result with a fallback

## Testing Strategy

### Manual Testing

**Avro Serialization Path:**
1. Start the order-service and analytics-api with Avro serialization enabled
2. Create an order with a non-numeric userId (e.g., "user-123")
3. Verify the analytics dashboard displays the userId correctly in the Recent Orders table
4. Verify the Active Users count increments correctly
5. Create multiple orders with different userId values and verify unique counting

**JSON Serialization Path:**
1. Start the order-service and analytics-api with JSON serialization enabled
2. Create an order with a non-numeric userId (e.g., "user-456")
3. Verify the analytics dashboard displays the userId correctly in the Recent Orders table
4. Verify the Active Users count increments correctly
5. Verify both JSON and Avro messages display userId correctly when both consumers are running

### Verification Points
- Dashboard displays userId values instead of "N/A"
- Active Users count reflects unique userId values
- No console errors related to type mismatches
- Orders with numeric userId values (e.g., "12345") still display correctly

### Edge Cases to Test
- Empty string userId
- Null or undefined userId
- Numeric string userId (e.g., "12345")
- Alphanumeric userId (e.g., "user-123")
- UUID-format userId (e.g., "550e8400-e29b-41d4-a716-446655440000")
