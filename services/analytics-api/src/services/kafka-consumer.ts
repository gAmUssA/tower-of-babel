import { Kafka, Consumer, KafkaMessage } from 'kafkajs';
import { EventEmitter } from 'events';
import { Order } from '../models/order';

/**
 * Kafka consumer service with intentional type inconsistency issues
 * This demonstrates the problems that occur when services use different types
 */
export class KafkaConsumerService {
  private consumer: Consumer;
  private eventEmitter: EventEmitter;
  private running: boolean = false;
  private errorCount: number = 0;
  private lastErrors: string[] = [];
  private maxErrorsToTrack: number = 10;
  
  constructor(
    private readonly brokers: string[],
    private readonly topic: string,
    private readonly groupId: string
  ) {
    const kafka = new Kafka({
      clientId: 'analytics-api',
      brokers: this.brokers
    });
    
    this.consumer = kafka.consumer({ groupId: this.groupId });
    this.eventEmitter = new EventEmitter();
  }
  
  /**
   * Start consuming messages from Kafka
   */
  async start(): Promise<void> {
    if (this.running) {
      console.log('Kafka consumer already running');
      return;
    }
    
    try {
      await this.consumer.connect();
      await this.consumer.subscribe({ topic: this.topic, fromBeginning: true });
      
      await this.consumer.run({
        eachMessage: async ({ topic, partition, message }) => {
          try {
            this.processMessage(message);
          } catch (error: any) {
            this.trackError(`Error processing message: ${error.message || 'Unknown error'}`);
            console.error('Error processing message:', error);
          }
        }
      });
      
      this.running = true;
      console.log(`Started Kafka consumer for topic ${this.topic}`);
    } catch (error) {
      console.error('Failed to start Kafka consumer:', error);
      throw error;
    }
  }
  
  /**
   * Stop consuming messages from Kafka
   */
  async stop(): Promise<void> {
    if (!this.running) {
      return;
    }
    
    try {
      await this.consumer.disconnect();
      this.running = false;
      console.log('Stopped Kafka consumer');
    } catch (error) {
      console.error('Error stopping Kafka consumer:', error);
      throw error;
    }
  }
  
  /**
   * Process a message from Kafka
   * This has intentional type conversion issues for demo purposes
   */
  private processMessage(message: KafkaMessage): void {
    if (!message.value) {
      this.trackError('Received empty message');
      return;
    }

    // Check if this is an Avro message (magic byte 0x00)
    if (message.value[0] === 0) {
      console.debug('Received Avro message, skipping in JSON consumer');
      return;
    }

    try {
      // First try to parse as JSON
      const messageStr = message.value.toString();
      const data = JSON.parse(messageStr);
      
      // Preserve types to match source data and Avro schema
      const order: Order = {
        orderId: data.orderId || '',
        // Preserve userId as string to match Avro schema and source data type
        userId: data.userId || '',
        // Type inconsistency: Convert BigDecimal to string
        amount: data.amount ? data.amount.toString() : '0',
        status: data.status || 'UNKNOWN',
        items: data.items || [],
        createdAt: data.createdAt || new Date().toISOString()
      };
      
      // Process items with type inconsistencies
      if (order.items && Array.isArray(order.items)) {
        order.items = order.items.map(item => ({
          // Type inconsistency: Convert string to number
          productId: parseInt(item.productId || '0'),
          quantity: item.quantity || 0,
          // Type inconsistency: Convert BigDecimal to number
          price: parseFloat(item.price || '0')
        }));
      }
      
      // Emit the processed order
      this.eventEmitter.emit('order', order);
      console.log(`Processed order: ${order.orderId}`);
      
    } catch (error: any) {
      // If JSON parsing fails, it might be Java serialized
      if (error instanceof SyntaxError) {
        this.trackError(`Failed to parse message as JSON: ${error.message}`);
        this.trackError('Received a message that appears to be Java serialized - cannot deserialize');
        console.error('Received a message that appears to be Java serialized - cannot deserialize');
      } else {
        this.trackError(`Error processing message: ${error.message}`);
        console.error('Error processing message:', error);
      }
      
      throw error;
    }
  }
  
  /**
   * Register a listener for order events
   */
  onOrder(listener: (order: Order) => void): void {
    this.eventEmitter.on('order', listener);
  }
  
  /**
   * Track an error message
   */
  private trackError(message: string): void {
    this.errorCount++;
    
    if (this.lastErrors.length >= this.maxErrorsToTrack) {
      this.lastErrors.shift();
    }
    
    this.lastErrors.push(message);
  }
  
  /**
   * Get the number of errors encountered
   */
  getErrorCount(): number {
    return this.errorCount;
  }
  
  /**
   * Get the last error messages
   */
  getLastErrors(): string[] {
    return [...this.lastErrors];
  }
}
