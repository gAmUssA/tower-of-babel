import { KafkaJS } from '@confluentinc/kafka-javascript';
import { SchemaRegistryClient, AvroDeserializer, SerdeType } from '@confluentinc/schemaregistry';
import { EventEmitter } from 'events';
import { Order } from '../models/order';

// Use KafkaJS compatibility layer from Confluent
const { Kafka } = KafkaJS;
type Consumer = KafkaJS.Consumer;
type KafkaMessage = KafkaJS.KafkaMessage;

/**
 * Avro Kafka consumer service with Schema Registry integration
 * This properly handles Avro serialized messages from Schema Registry
 */
export class AvroKafkaConsumerService {
  private consumer: Consumer;
  private schemaRegistry: SchemaRegistryClient;
  private deserializer: AvroDeserializer;
  private eventEmitter: EventEmitter;
  private running: boolean = false;
  private errorCount: number = 0;
  private lastErrors: string[] = [];
  private maxErrorsToTrack: number = 10;
  
  constructor(
    private readonly brokers: string[],
    private readonly topic: string,
    private readonly groupId: string,
    private readonly schemaRegistryUrl: string
  ) {
    const kafka = new Kafka({
      kafkaJS: {
        clientId: 'analytics-api-avro',
        brokers: this.brokers
      }
    });
    
    this.schemaRegistry = new SchemaRegistryClient({ 
      baseURLs: [this.schemaRegistryUrl] 
    });
    
    this.deserializer = new AvroDeserializer(
      this.schemaRegistry,
      SerdeType.VALUE,
      {}
    );
    
    this.consumer = kafka.consumer({ 'group.id': this.groupId });
    this.eventEmitter = new EventEmitter();
  }
  
  /**
   * Start consuming messages from Kafka
   */
  async start(): Promise<void> {
    if (this.running) {
      console.log('Avro Kafka consumer already running');
      return;
    }
    
    try {
      await this.consumer.connect();
      await this.consumer.subscribe({ topics: [this.topic] });
      
      await this.consumer.run({
        eachMessage: async ({ topic, partition, message }: { topic: string; partition: number; message: KafkaMessage }) => {
          try {
            await this.processMessage(message);
          } catch (error: any) {
            this.trackError(`Error processing Avro message: ${error.message || 'Unknown error'}`);
            console.error('Error processing Avro message:', error);
          }
        }
      });
      
      this.running = true;
      console.log(`Started Avro Kafka consumer for topic ${this.topic}`);
    } catch (error) {
      console.error('Failed to start Avro Kafka consumer:', error);
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
      console.log('Stopped Avro Kafka consumer');
    } catch (error) {
      console.error('Error stopping Avro Kafka consumer:', error);
      throw error;
    }
  }
  
  /**
   * Process a message from Kafka using Avro and Schema Registry
   */
  private async processMessage(message: KafkaMessage): Promise<void> {
    if (!message.value) {
      this.trackError('Received empty message');
      return;
    }
    
    try {
      // Decode Avro message using Schema Registry
      const decodedMessage = await this.deserializer.deserialize(
        this.topic,
        message.value
      );
      
      // Convert Avro object to our Order model
      // Get timestamp from message if available
      let timestamp: Date;
      if (decodedMessage.orderTimestamp) {
        // Handle timestamp in milliseconds format
        timestamp = new Date(Number(decodedMessage.orderTimestamp));
      } else if (decodedMessage.createdAt) {
        // Handle string timestamp format if available
        timestamp = new Date(decodedMessage.createdAt);
      } else {
        // Fallback to current time
        timestamp = new Date();
      }
      
      // Ensure we have a valid date, fallback to current time if invalid
      if (isNaN(timestamp.getTime())) {
        console.warn(`Invalid timestamp in message: ${decodedMessage.orderTimestamp || decodedMessage.createdAt}`);
        timestamp = new Date();
      }
      
      const order: Order = {
        orderId: decodedMessage.orderId || '',
        userId: decodedMessage.userId?.toString() || '',
        amount: decodedMessage.amount?.toString() || '0',
        status: decodedMessage.status || 'UNKNOWN',
        items: [],
        createdAt: timestamp.toISOString(),
        source: 'avro'
      };
      
      // Emit the processed order
      this.eventEmitter.emit('order', order);
      console.log(`Processed Avro order: ${order.orderId}`);
      
    } catch (error: any) {
      // Check if this might be a regular JSON or Java serialized message
      if (error.message && error.message.includes('Magic byte')) {
        // Silently skip non-Avro messages - don't count as error
        console.debug('Received non-Avro message, skipping');
        return;
      }

      this.trackError(`Error processing Avro message: ${error.message}`);
      console.error('Error processing Avro message:', error);
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
