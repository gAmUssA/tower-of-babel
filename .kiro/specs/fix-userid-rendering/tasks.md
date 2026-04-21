# Implementation Plan

- [x] 1. Update TypeScript Order model to use string type for userId
  - Modify the Order interface in `services/analytics-api/src/models/order.ts`
  - Change `userId: number` to `userId: string`
  - Update the comment to reflect that this now matches the Avro schema
  - _Requirements: 1.3, 2.1_

- [x] 2. Fix Avro consumer to preserve userId as string
  - Modify the `processMessage` method in `services/analytics-api/src/services/avro-kafka-consumer.ts`
  - Remove the `parseInt()` call on userId extraction
  - Change from `parseInt(decodedMessage.userId?.toString() || '0')` to `decodedMessage.userId?.toString() || ''`
  - _Requirements: 1.4, 2.3_

- [x] 3. Fix JSON consumer to preserve userId as string
  - Modify the `processMessage` method in `services/analytics-api/src/services/kafka-consumer.ts`
  - Remove the `parseInt()` call on userId extraction
  - Change from `parseInt(data.userId || '0')` to `data.userId || ''`
  - Update the comment to reflect that this matches the source data type
  - _Requirements: 1.4, 2.3_

- [x] 4. Verify TypeScript compilation and check for type errors
  - Run TypeScript compiler to ensure no type errors
  - Check that all references to Order.userId are compatible with string type
  - _Requirements: 2.1, 2.2_

- [x] 5. Test the fix with sample data
  - Start the analytics-api service
  - Send test orders with non-numeric userId values (e.g., "user-123")
  - Verify the dashboard displays userId correctly
  - Verify Active Users count works correctly
  - Test both JSON and Avro message paths
  - _Requirements: 1.1, 1.2_
