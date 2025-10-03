---
trigger: manual
description: 
globs: 
---

# TypeScript/Jest Testing Standards

## Test Framework Configuration

- Framework: Jest 29.7.0 with ts-jest
- Test location: Co-located with source files (`.test.ts` suffix)
- Build: TypeScript 5.3.2, target ES2020

## Running Tests

```bash
cd services/analytics-api
npm test                          # Run all tests
npm test -- order-utils           # Run tests matching pattern
npm test -- --coverage            # Run with coverage report
npm test -- --verbose             # Verbose output
```

## Test Structure Pattern

Use describe blocks with clear expectations:

```typescript
import { validateOrderData, formatOrderId } from './order-utils';

describe('validateOrderData', () => {
  it('should return true for valid order data', () => {
    const orderData = {
      orderId: '123',
      userId: 'user456',
      amount: 99.99,
      status: 'PENDING'
    };
    expect(validateOrderData(orderData)).toBe(true);
  });

  it('should return false for missing required field', () => {
    const orderData = { orderId: '123', userId: 'user456' };
    expect(validateOrderData(orderData)).toBe(false);
  });
});
```

## Jest Configuration

Exclude generated code from coverage:

```javascript
collectCoverageFrom: [
  'src/**/*.ts',
  '!src/**/*.test.ts',
  '!src/generated/**',  // Exclude generated Avro code
]
```

## Test File Patterns

- Unit tests: `*.test.ts` or `*.spec.ts`
- Integration tests: `*.integration.test.ts`
- Co-locate tests with source files

## Kafka Testing with KafkaJS

```typescript
import { Kafka } from 'kafkajs';

describe('Kafka Producer', () => {
  let kafka: Kafka;
  let producer: Producer;

  beforeAll(async () => {
    kafka = new Kafka({ brokers: ['localhost:29092'] });
    producer = kafka.producer();
    await producer.connect();
  });

  afterAll(async () => {
    await producer.disconnect();
  });

  it('should publish order event with schema validation', async () => {
    // Test implementation
  });
});
```

## Building and Running

```bash
npm run build      # Compiles to dist/
npm run dev        # Development mode with auto-reload
npm start          # Run compiled code (port 9300)
```

## NEVER

- Skip type annotations (use strict mode)
- Import from src/generated/ in production code
- Use `any` type without explicit justification
- Leave unused imports or variables