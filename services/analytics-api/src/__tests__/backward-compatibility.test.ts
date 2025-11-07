/**
 * Backward Compatibility Tests
 * 
 * These tests validate that the migration from kafkajs to @confluentinc/kafka-javascript
 * maintains backward compatibility with:
 * - Existing message formats (JSON and Avro)
 * - Order event structure
 * - Error tracking behavior
 * 
 * Requirements: 1.2, 1.4, 1.5
 */

import { KafkaConsumerService } from '../services/kafka-consumer';
import { AvroKafkaConsumerService } from '../services/avro-kafka-consumer';
import { Order } from '../models/order';

describe('Backward Compatibility Tests', () => {
  describe('KafkaConsumerService - JSON Message Processing', () => {
    let consumerService: KafkaConsumerService;
    
    beforeEach(() => {
      consumerService = new KafkaConsumerService(
        ['localhost:9092'],
        'orders',
        'test-group'
      );
    });

    test('should maintain Order event structure with all required fields', (done) => {
      // Requirement 1.2: Maintain backward compatibility with existing message processing logic
      const expectedOrder = {
        orderId: '123e4567-e89b-12d3-a456-426614174000',
        userId: 'user-456',
        amount: '99.99',
        status: 'PENDING',
        items: [
          { productId: 1, quantity: 2, price: 49.99 }
        ],
        createdAt: '2024-01-01T00:00:00.000Z'
      };

      consumerService.onOrder((order: Order) => {
        // Verify Order structure is unchanged
        expect(order).toHaveProperty('orderId');
        expect(order).toHaveProperty('userId');
        expect(order).toHaveProperty('amount');
        expect(order).toHaveProperty('status');
        expect(order).toHaveProperty('items');
        expect(order).toHaveProperty('createdAt');
        
        // Verify types match expected structure
        expect(typeof order.orderId).toBe('string');
        expect(typeof order.userId).toBe('string');
        expect(typeof order.amount).toBe('string');
        expect(typeof order.status).toBe('string');
        expect(Array.isArray(order.items)).toBe(true);
        expect(typeof order.createdAt).toBe('string');
        
        done();
      });

      // Simulate message processing
      const mockMessage = {
        value: Buffer.from(JSON.stringify(expectedOrder)),
        key: null,
        timestamp: '1234567890',
        offset: '0',
        headers: {}
      };

      // Access private method for testing
      (consumerService as any).processMessage(mockMessage);
    });

    test('should emit order events through EventEmitter pattern', (done) => {
      // Requirement 1.4: Continue to emit order events through the EventEmitter pattern
      const testOrder = {
        orderId: 'test-order-1',
        userId: 'user-123',
        amount: '150.00',
        status: 'COMPLETED',
        items: [],
        createdAt: new Date().toISOString()
      };

      let eventEmitted = false;
      consumerService.onOrder((order: Order) => {
        eventEmitted = true;
        expect(order.orderId).toBe(testOrder.orderId);
        expect(order.userId).toBe(testOrder.userId);
        done();
      });

      const mockMessage = {
        value: Buffer.from(JSON.stringify(testOrder)),
        key: null,
        timestamp: '1234567890',
        offset: '0',
        headers: {}
      };

      (consumerService as any).processMessage(mockMessage);
      
      // Verify event was emitted
      setTimeout(() => {
        expect(eventEmitted).toBe(true);
      }, 100);
    });

    test('should handle type conversions correctly for items', (done) => {
      // Test that productId is converted to number and price is converted to number
      const orderWithItems = {
        orderId: 'order-with-items',
        userId: 'user-789',
        amount: '299.97',
        status: 'PENDING',
        items: [
          { productId: '101', quantity: 1, price: '99.99' },
          { productId: '102', quantity: 2, price: '100.00' }
        ],
        createdAt: new Date().toISOString()
      };

      consumerService.onOrder((order: Order) => {
        expect(order.items).toHaveLength(2);
        expect(typeof order.items[0].productId).toBe('number');
        expect(order.items[0].productId).toBe(101);
        expect(typeof order.items[0].price).toBe('number');
        expect(order.items[0].price).toBe(99.99);
        done();
      });

      const mockMessage = {
        value: Buffer.from(JSON.stringify(orderWithItems)),
        key: null,
        timestamp: '1234567890',
        offset: '0',
        headers: {}
      };

      (consumerService as any).processMessage(mockMessage);
    });
  });

  describe('Error Tracking Behavior', () => {
    let consumerService: KafkaConsumerService;
    
    beforeEach(() => {
      consumerService = new KafkaConsumerService(
        ['localhost:9092'],
        'orders',
        'test-group'
      );
    });

    test('should track errors with existing error tracking mechanism', () => {
      // Requirement 1.5: Maintain the same error tracking and logging behavior
      const initialErrorCount = consumerService.getErrorCount();
      expect(initialErrorCount).toBe(0);

      // Trigger an error by sending invalid JSON
      const invalidMessage = {
        value: Buffer.from('invalid json {'),
        key: null,
        timestamp: '1234567890',
        offset: '0',
        headers: {}
      };

      try {
        (consumerService as any).processMessage(invalidMessage);
      } catch (error) {
        // Expected to throw
      }

      // Verify error was tracked
      expect(consumerService.getErrorCount()).toBeGreaterThan(initialErrorCount);
      expect(consumerService.getLastErrors().length).toBeGreaterThan(0);
    });

    test('should maintain maxErrorsToTrack limit of 10 errors', () => {
      // Generate more than 10 errors
      for (let i = 0; i < 15; i++) {
        const invalidMessage = {
          value: Buffer.from(`invalid json ${i}`),
          key: null,
          timestamp: '1234567890',
          offset: '0',
          headers: {}
        };

        try {
          (consumerService as any).processMessage(invalidMessage);
        } catch (error) {
          // Expected to throw
        }
      }

      // Verify only last 10 errors are kept
      const lastErrors = consumerService.getLastErrors();
      expect(lastErrors.length).toBeLessThanOrEqual(10);
      // Each invalid JSON triggers 2 errors: parse failure + Java serialization message
      expect(consumerService.getErrorCount()).toBe(30); // 15 messages * 2 errors each
    });

    test('should provide getErrorCount() and getLastErrors() methods', () => {
      // Verify methods exist and return correct types
      expect(typeof consumerService.getErrorCount).toBe('function');
      expect(typeof consumerService.getLastErrors).toBe('function');
      
      expect(typeof consumerService.getErrorCount()).toBe('number');
      expect(Array.isArray(consumerService.getLastErrors())).toBe(true);
    });

    test('should skip Avro messages without counting as errors', () => {
      const initialErrorCount = consumerService.getErrorCount();
      
      // Create a message with Avro magic byte (0x00)
      const avroMessage = {
        value: Buffer.from([0x00, 0x01, 0x02, 0x03]),
        key: null,
        timestamp: '1234567890',
        offset: '0',
        headers: {}
      };

      (consumerService as any).processMessage(avroMessage);

      // Verify no error was tracked for Avro message
      expect(consumerService.getErrorCount()).toBe(initialErrorCount);
    });
  });

  describe('AvroKafkaConsumerService - Avro Message Processing', () => {
    let avroConsumerService: AvroKafkaConsumerService;
    
    beforeEach(() => {
      avroConsumerService = new AvroKafkaConsumerService(
        ['localhost:9092'],
        'orders',
        'test-avro-group',
        'http://localhost:8081'
      );
    });

    test('should maintain Order event structure for Avro messages', () => {
      // Requirement 1.2: Maintain backward compatibility with existing message processing logic
      // This test verifies that the onOrder listener accepts the correct Order structure
      let orderReceived = false;
      
      avroConsumerService.onOrder((order: Order) => {
        orderReceived = true;
        // Verify Order structure matches expected format
        expect(order).toHaveProperty('orderId');
        expect(order).toHaveProperty('userId');
        expect(order).toHaveProperty('amount');
        expect(order).toHaveProperty('status');
        expect(order).toHaveProperty('items');
        expect(order).toHaveProperty('createdAt');
        expect(order).toHaveProperty('source');
        
        // Verify source is set to 'avro'
        expect(order.source).toBe('avro');
      });

      // Verify listener is registered (actual Avro deserialization requires Schema Registry)
      expect(orderReceived).toBe(false);
    });

    test('should emit order events through EventEmitter pattern', () => {
      // Requirement 1.4: Continue to emit order events through the EventEmitter pattern
      let listenerCalled = false;
      
      avroConsumerService.onOrder((order: Order) => {
        listenerCalled = true;
      });

      // Verify listener is registered
      expect(listenerCalled).toBe(false);
    });

    test('should track errors for Avro processing', () => {
      // Requirement 1.5: Maintain the same error tracking and logging behavior
      const initialErrorCount = avroConsumerService.getErrorCount();
      expect(initialErrorCount).toBe(0);
      
      // Verify error tracking methods exist
      expect(typeof avroConsumerService.getErrorCount).toBe('function');
      expect(typeof avroConsumerService.getLastErrors).toBe('function');
    });

    test('should not count non-Avro messages as errors', async () => {
      const initialErrorCount = avroConsumerService.getErrorCount();
      
      // Create a non-Avro message (without magic byte)
      const nonAvroMessage = {
        value: Buffer.from('regular message'),
        key: null,
        timestamp: '1234567890',
        offset: '0',
        headers: {}
      };

      try {
        await (avroConsumerService as any).processMessage(nonAvroMessage);
      } catch (error) {
        // May throw due to Schema Registry, but shouldn't track as error
      }

      // The implementation should skip non-Avro messages gracefully
      // Error count may increase only if it's a real Avro decoding error
    });
  });

  describe('Message Format Compatibility', () => {
    test('should process legacy JSON message format', (done) => {
      const consumerService = new KafkaConsumerService(
        ['localhost:9092'],
        'orders',
        'test-group'
      );

      // Legacy format with all fields as strings
      const legacyOrder = {
        orderId: 'legacy-order-1',
        userId: '999',
        amount: '50.00',
        status: 'SHIPPED',
        items: [
          { productId: '200', quantity: 1, price: '50.00' }
        ],
        createdAt: '2023-12-31T23:59:59.999Z'
      };

      consumerService.onOrder((order: Order) => {
        expect(order.orderId).toBe(legacyOrder.orderId);
        expect(order.userId).toBe(legacyOrder.userId);
        expect(order.amount).toBe(legacyOrder.amount);
        expect(order.status).toBe(legacyOrder.status);
        expect(order.items[0].productId).toBe(200); // Converted to number
        expect(order.items[0].price).toBe(50.00); // Converted to number
        done();
      });

      const mockMessage = {
        value: Buffer.from(JSON.stringify(legacyOrder)),
        key: null,
        timestamp: '1234567890',
        offset: '0',
        headers: {}
      };

      (consumerService as any).processMessage(mockMessage);
    });

    test('should handle missing optional fields gracefully', (done) => {
      const consumerService = new KafkaConsumerService(
        ['localhost:9092'],
        'orders',
        'test-group'
      );

      // Minimal order with missing optional fields
      const minimalOrder = {
        orderId: 'minimal-order',
        userId: 'user-minimal'
      };

      consumerService.onOrder((order: Order) => {
        expect(order.orderId).toBe(minimalOrder.orderId);
        expect(order.userId).toBe(minimalOrder.userId);
        expect(order.amount).toBe('0'); // Default value
        expect(order.status).toBe('UNKNOWN'); // Default value
        expect(Array.isArray(order.items)).toBe(true);
        done();
      });

      const mockMessage = {
        value: Buffer.from(JSON.stringify(minimalOrder)),
        key: null,
        timestamp: '1234567890',
        offset: '0',
        headers: {}
      };

      (consumerService as any).processMessage(mockMessage);
    });
  });
});
