# Implementation Plan

- [x] 1. Update package dependencies
  - Remove kafkajs and @kafkajs/confluent-schema-registry dependencies
  - Add @confluentinc/kafka-javascript and @confluentinc/schemaregistry dependencies
  - Run npm install to verify no dependency conflicts
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 2. Migrate KafkaConsumerService to Confluent client
  - [x] 2.1 Update import statements in kafka-consumer.ts
    - Replace kafkajs imports with @confluentinc/kafka-javascript imports
    - Use KafkaJS compatibility layer from Confluent package
    - _Requirements: 1.1, 4.2_
  
  - [x] 2.2 Update Kafka client initialization
    - Modify Kafka constructor to use kafkaJS configuration wrapper
    - Preserve existing broker and clientId configuration
    - _Requirements: 1.3, 4.1, 4.3_
  
  - [x] 2.3 Verify consumer behavior preservation
    - Ensure consumer.connect(), subscribe(), and run() methods work unchanged
    - Verify eachMessage callback pattern is preserved
    - Confirm EventEmitter pattern for order events remains functional
    - _Requirements: 1.2, 1.4, 4.4_
  
  - [x] 2.4 Validate error handling and tracking
    - Verify trackError() method continues to work
    - Confirm error count and lastErrors tracking is preserved
    - Test getErrorCount() and getLastErrors() methods
    - _Requirements: 1.5, 5.1, 5.2, 5.4, 5.5_

- [x] 3. Migrate AvroKafkaConsumerService to Confluent Schema Registry client
  - [x] 3.1 Update import statements in avro-kafka-consumer.ts
    - Replace kafkajs imports with @confluentinc/kafka-javascript imports
    - Replace @kafkajs/confluent-schema-registry with @confluentinc/schemaregistry
    - Import SchemaRegistryClient, AvroDeserializer, and SerdeType
    - _Requirements: 2.1, 2.2_
  
  - [x] 3.2 Update Schema Registry client initialization
    - Replace SchemaRegistry with SchemaRegistryClient
    - Update constructor to use baseURLs parameter instead of host
    - Initialize AvroDeserializer for message deserialization
    - _Requirements: 2.1, 2.2_
  
  - [x] 3.3 Update message deserialization logic
    - Replace schemaRegistry.decode() with deserializer.deserialize()
    - Pass topic name to deserialize method
    - Preserve Order model transformation logic
    - _Requirements: 2.2, 2.4, 4.5_
  
  - [x] 3.4 Verify Avro message handling
    - Test Avro message decoding with Schema Registry
    - Verify non-Avro messages are skipped without errors
    - Confirm schema evolution compatibility
    - _Requirements: 2.3, 2.5_
  
  - [x] 3.5 Validate error handling for Avro processing
    - Verify Avro decoding errors are tracked correctly
    - Confirm non-Avro messages don't increment error count
    - Test error logging with context
    - _Requirements: 5.3_

- [x] 4. Update TypeScript type definitions
  - Verify KafkaMessage type compatibility with new package
  - Ensure Consumer type definitions are correct
  - Update any type imports that reference kafkajs types
  - _Requirements: 4.5_

- [x] 5. Verify build and compilation
  - Run npm run build to compile TypeScript
  - Fix any TypeScript compilation errors
  - Verify generated JavaScript in dist/ directory
  - _Requirements: 3.5_

- [x] 6. Test migration with existing demo scripts
  - Run demo-1-tower-of-babel.sh to test JSON consumer
  - Run demo-2-babel-fish.sh to test Avro consumer
  - Verify analytics dashboard displays orders correctly
  - Check logs for any unexpected errors
  - _Requirements: 1.2, 2.4_

- [x] 7. Validate backward compatibility
  - Test processing of existing message formats
  - Verify Order event structure is unchanged
  - Confirm error tracking behavior matches previous implementation
  - _Requirements: 1.2, 1.4, 1.5_
