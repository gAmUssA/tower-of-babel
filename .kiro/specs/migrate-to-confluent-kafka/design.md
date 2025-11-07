# Design Document

## Overview

This design document outlines the migration strategy for transitioning the analytics-api from kafkajs to Confluent's official `@confluentinc/kafka-javascript` client. The migration leverages Confluent's KafkaJS compatibility layer to minimize code changes while gaining the benefits of the official client implementation.

## Architecture

### Current Architecture

```
┌─────────────────────────────────────────┐
│         Analytics API Service          │
├─────────────────────────────────────────┤
│  KafkaConsumerService                   │
│  - Uses: kafkajs                        │
│  - Processes: JSON messages             │
├─────────────────────────────────────────┤
│  AvroKafkaConsumerService               │
│  - Uses: kafkajs +                      │
│    @kafkajs/confluent-schema-registry   │
│  - Processes: Avro messages             │
└─────────────────────────────────────────┘
```

### Target Architecture

```
┌─────────────────────────────────────────┐
│         Analytics API Service          │
├─────────────────────────────────────────┤
│  KafkaConsumerService                   │
│  - Uses: @confluentinc/kafka-javascript │
│  - Processes: JSON messages             │
├─────────────────────────────────────────┤
│  AvroKafkaConsumerService               │
│  - Uses: @confluentinc/kafka-javascript │
│    + @confluentinc/schemaregistry       │
│  - Processes: Avro messages             │
└─────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Package Dependencies

**Changes Required:**

- **Remove:** `kafkajs` (current: ^2.2.4)
- **Remove:** `@kafkajs/confluent-schema-registry` (current: ^3.3.0)
- **Add:** `@confluentinc/kafka-javascript` (latest stable)
- **Add:** `@confluentinc/schemaregistry` (latest stable)

**Rationale:** The Confluent packages provide official support and better integration with Confluent Platform features.

### 2. KafkaConsumerService

**File:** `services/analytics-api/src/services/kafka-consumer.ts`

**Import Changes:**

```typescript
// Before
import { Kafka, Consumer, KafkaMessage } from 'kafkajs';

// After
import { Kafka, Consumer, KafkaMessage } from '@confluentinc/kafka-javascript';
const { Kafka: KafkaClient } = require('@confluentinc/kafka-javascript').KafkaJS;
```

**Implementation Strategy:**

1. Use the KafkaJS compatibility layer from Confluent's client
2. The compatibility layer provides the same API surface as kafkajs
3. Minimal code changes required - primarily import statements
4. Consumer initialization pattern remains the same:
   ```typescript
   const kafka = new Kafka({
     kafkaJS: {
       clientId: 'analytics-api',
       brokers: this.brokers
     }
   });
   ```

**Key Design Decisions:**

- **Use KafkaJS Compatibility Mode:** Confluent provides a `KafkaJS` export that mimics the kafkajs API, allowing for minimal code changes
- **Preserve EventEmitter Pattern:** The existing event-driven architecture for order processing remains unchanged
- **Maintain Error Tracking:** All error tracking logic (errorCount, lastErrors) stays the same
- **Keep Message Processing Logic:** The processMessage() method logic is preserved, including type conversions and JSON parsing

### 3. AvroKafkaConsumerService

**File:** `services/analytics-api/src/services/avro-kafka-consumer.ts`

**Import Changes:**

```typescript
// Before
import { Kafka, Consumer, KafkaMessage } from 'kafkajs';
import { SchemaRegistry } from '@kafkajs/confluent-schema-registry';

// After
import { Kafka, Consumer, KafkaMessage } from '@confluentinc/kafka-javascript';
const { Kafka: KafkaClient } = require('@confluentinc/kafka-javascript').KafkaJS;
import { SchemaRegistryClient, AvroDeserializer, SerdeType } from '@confluentinc/schemaregistry';
```

**Implementation Strategy:**

1. Replace SchemaRegistry with SchemaRegistryClient from Confluent's package
2. Use AvroDeserializer for message deserialization
3. Update the decode() method call to use the new API
4. Maintain the same message transformation logic

**Schema Registry Integration:**

```typescript
// Initialization
this.schemaRegistry = new SchemaRegistryClient({ 
  baseURLs: [this.schemaRegistryUrl] 
});

// Create deserializer
this.deserializer = new AvroDeserializer(
  this.schemaRegistry, 
  SerdeType.VALUE, 
  {}
);

// Decode message
const decodedMessage = await this.deserializer.deserialize(
  this.topic,
  message.value
);
```

**Key Design Decisions:**

- **Use AvroDeserializer:** Provides better performance and type safety compared to generic decode()
- **Initialize Deserializer Once:** Create the deserializer during service initialization for better performance
- **Preserve Message Transformation:** The Order model transformation logic remains unchanged
- **Handle Non-Avro Messages:** Continue to skip non-Avro messages gracefully

## Data Models

### Order Model

**No changes required** - The Order interface remains the same:

```typescript
interface Order {
  orderId: string;
  userId: string;
  amount: string;
  status: string;
  items: Array<{
    productId: number;
    quantity: number;
    price: number;
  }>;
  createdAt: string;
  source?: string;
}
```

### Consumer Configuration

**Enhanced configuration options** available with Confluent client:

```typescript
interface ConsumerConfig {
  kafkaJS: {
    groupId: string;
    brokers: string[];
    clientId?: string;
    fromBeginning?: boolean;
  };
  // Additional Confluent-specific options can be added:
  'session.timeout.ms'?: number;
  'heartbeat.interval.ms'?: number;
  'enable.auto.commit'?: boolean;
}
```

## Error Handling

### Error Categories

1. **Connection Errors**
   - Handled during connect() phase
   - Logged and thrown to caller
   - No change from current implementation

2. **Message Processing Errors**
   - Caught in eachMessage callback
   - Tracked using trackError() method
   - Logged to console
   - No change from current implementation

3. **Avro Decoding Errors**
   - Caught during deserialize() call
   - Non-Avro messages skipped silently
   - Schema errors tracked and logged
   - No change from current implementation

### Error Tracking

The existing error tracking mechanism is preserved:

```typescript
private trackError(message: string): void {
  this.errorCount++;
  if (this.lastErrors.length >= this.maxErrorsToTrack) {
    this.lastErrors.shift();
  }
  this.lastErrors.push(message);
}
```

## Testing Strategy

### Unit Testing

1. **Consumer Initialization Tests**
   - Verify Kafka client is created with correct configuration
   - Test consumer group ID and broker configuration
   - Validate Schema Registry client initialization

2. **Message Processing Tests**
   - Test JSON message parsing and transformation
   - Test Avro message deserialization
   - Verify Order model transformation
   - Test error handling for malformed messages

3. **Error Tracking Tests**
   - Verify error count increments correctly
   - Test lastErrors array management
   - Validate maxErrorsToTrack limit

### Integration Testing

1. **Kafka Connection Tests**
   - Test successful connection to Kafka brokers
   - Verify subscription to topics
   - Test graceful disconnection

2. **Schema Registry Integration Tests**
   - Test Avro message deserialization with Schema Registry
   - Verify schema evolution handling
   - Test fallback for non-Avro messages

3. **End-to-End Tests**
   - Produce test messages and verify consumption
   - Test both JSON and Avro message flows
   - Verify EventEmitter notifications

### Migration Validation

1. **Backward Compatibility Tests**
   - Verify existing message formats are processed correctly
   - Test that Order events are emitted with same structure
   - Validate error tracking behavior matches previous implementation

2. **Performance Tests**
   - Compare message throughput before and after migration
   - Monitor memory usage
   - Verify no message loss during processing

## Migration Approach

### Phase 1: Dependency Update
1. Update package.json with new dependencies
2. Remove old dependencies
3. Run npm install and verify no conflicts

### Phase 2: Code Migration
1. Update KafkaConsumerService imports and initialization
2. Update AvroKafkaConsumerService imports and Schema Registry integration
3. Verify TypeScript compilation succeeds

### Phase 3: Testing
1. Run unit tests
2. Run integration tests with local Kafka
3. Verify both JSON and Avro consumers work correctly

### Phase 4: Validation
1. Test with existing demo scripts
2. Verify analytics dashboard continues to work
3. Monitor error logs for any issues

## Rollback Plan

If issues are encountered:

1. **Immediate Rollback:** Revert package.json changes and reinstall dependencies
2. **Code Rollback:** Git revert the consumer service changes
3. **Validation:** Run existing tests to verify rollback success

The migration is designed to be low-risk due to:
- Use of KafkaJS compatibility layer
- Minimal code changes required
- Preservation of existing logic and error handling
- Comprehensive testing strategy
