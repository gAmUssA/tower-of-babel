# Demo 1c: Type Inconsistency - Demonstration Guide

## Overview

This scenario demonstrates what happens when data types don't match between services, causing parsing errors and data inconsistencies.

## What It Demonstrates

### The Problem

Different languages and services have different type expectations:
- **Java Order Service**: Uses `BigDecimal` for amounts, `UUID` for IDs
- **TypeScript Analytics API**: Expects `number` for amounts, specific string formats for IDs
- **Without schema enforcement**: Type mismatches cause runtime errors

### Examples of Type Mismatches

1. **String instead of Number**
   - Sent: `amount: "not-a-number"`
   - Expected: `amount: 99.99`
   - Result: Parsing error in Analytics API

2. **Invalid String Format**
   - Sent: `userId: "user-with-@-symbols"`
   - Expected: `userId: "user123"` (alphanumeric)
   - Result: Validation or processing errors

3. **Type Coercion Failures**
   - JavaScript tries to coerce types automatically
   - Sometimes succeeds with unexpected results
   - Sometimes fails with errors

## How to Run

### Option 1: Run Only Type Inconsistency Scenario

```bash
./scripts/demo/demo-1-tower-of-babel.sh type
```

Or using Make:
```bash
make demo-1-type
```

### Option 2: Run All Chaos Scenarios

```bash
./scripts/demo/demo-1-tower-of-babel.sh all
```

Or:
```bash
make demo-1
```

## What to Look For

### 1. Error Count Increase

The script shows:
```
Analytics API Errors: 2 new errors
```

This indicates type conversion failures occurred.

### 2. Error Messages

The script displays recent error messages:
```
📋 Recent error messages from Analytics API:
  • 14:23:45: Failed to parse amount: expected number, got string
  • 14:23:46: Invalid userId format
```

### 3. Visual Comparison

The script shows what was sent vs what was expected:
```
Example 1: amount as string instead of number
  Sent:     amount: "not-a-number" (string)
  Expected: amount: 99.99 (number)
```

## Viewing Detailed Results

### Analytics Dashboard

Visit the Analytics Dashboard to see:
- Error logs with timestamps
- Failed message processing
- Type conversion issues

```bash
open http://localhost:9300/analytics/dashboard
```

### Error API Endpoint

Get detailed error information:
```bash
curl http://localhost:9300/api/errors | jq .
```

Example output:
```json
{
  "errorCount": 5,
  "recentErrors": [
    {
      "timestamp": "2024-01-15T14:23:45.123Z",
      "message": "Failed to parse amount: expected number, got string 'not-a-number'",
      "orderId": "abc-123",
      "field": "amount",
      "receivedType": "string",
      "expectedType": "number"
    }
  ]
}
```

### Recent Messages

See what messages were received:
```bash
curl http://localhost:9300/api/messages/recent | jq .
```

## Understanding the Output

### Success Case (No Errors)

If you see:
```
⚠️  No errors detected - service handled gracefully
💡 The Analytics API may have type coercion or validation that prevented errors
```

This means:
- The service has defensive programming
- Type coercion succeeded (but may have unexpected results)
- Validation rejected the message before processing

### Failure Case (Errors Detected)

If you see:
```
❌ Type conversion failures detected (expected)
```

This means:
- Type mismatches caused runtime errors
- Data could not be processed correctly
- This is the expected behavior for the demo

## The Problem This Demonstrates

### Without Schema Registry

1. **No Type Enforcement**: Services can send any type
2. **Runtime Errors**: Type mismatches discovered at runtime
3. **Data Inconsistency**: Different services interpret data differently
4. **Debugging Difficulty**: Hard to trace where type mismatch originated

### Example Scenarios

**Scenario A: Silent Failure**
```javascript
// JavaScript coerces "123" to 123
const amount = "123" * 1.1;  // Works, but wrong!
```

**Scenario B: Runtime Error**
```javascript
// JavaScript cannot coerce "not-a-number"
const amount = "not-a-number" * 1.1;  // NaN - breaks calculations
```

**Scenario C: Validation Error**
```javascript
// TypeScript type checking catches it
const amount: number = "not-a-number";  // Compile error
```

## The Solution (Preview)

Schema Registry with Avro solves this by:

1. **Enforced Types**: Schema defines exact types
2. **Compile-Time Checking**: Code generation provides type safety
3. **Runtime Validation**: Serialization validates types
4. **Clear Contracts**: All services use same type definitions

See Demo 2 (`make demo-2`) to see the solution in action.

## Troubleshooting

### No Errors Shown

If you don't see errors:

1. **Check if Analytics API is running:**
   ```bash
   curl http://localhost:9300/health
   ```

2. **Check error endpoint directly:**
   ```bash
   curl http://localhost:9300/api/errors
   ```

3. **View Analytics API logs:**
   ```bash
   # If running in terminal
   # Check the terminal where you ran: make run-analytics-api
   ```

4. **Reset and try again:**
   ```bash
   make demo-reset
   ./scripts/demo/demo-1-tower-of-babel.sh type
   ```

### Services Not Running

Ensure all services are running:
```bash
make status

# Start services if needed
make run-order-service      # Terminal 1
make run-inventory-service  # Terminal 2
make run-analytics-api      # Terminal 3
```

## Next Steps

After seeing the type inconsistency problems:

1. **Run Demo 2** to see how Avro solves this:
   ```bash
   make demo-2
   ```

2. **Run the test suite** to verify behavior:
   ```bash
   make test-1
   ```

3. **Explore the Analytics Dashboard** to see detailed errors:
   ```bash
   open http://localhost:9300/analytics/dashboard
   ```

## Key Takeaways

- ✅ Type mismatches cause runtime errors
- ✅ Different languages handle types differently
- ✅ Without schemas, type safety is not guaranteed
- ✅ Debugging type issues is difficult in distributed systems
- ✅ Schema Registry with Avro enforces type safety across languages
