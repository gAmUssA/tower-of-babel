import express from 'express';
import http from 'http';
import { Server } from 'socket.io';
import path from 'path';
import dotenv from 'dotenv';
import { KafkaConsumerService } from './services/kafka-consumer';
import { AvroKafkaConsumerService } from './services/avro-kafka-consumer';
import { AnalyticsService } from './services/analytics-service';
import { Order } from './models/order';

// Load environment variables
dotenv.config();

// Kafka configuration
const KAFKA_BROKERS = (process.env.KAFKA_BROKERS || 'localhost:29092').split(',');
const KAFKA_TOPIC = process.env.KAFKA_TOPIC || 'orders';
const KAFKA_GROUP_ID = process.env.KAFKA_GROUP_ID || 'analytics-api';
const SCHEMA_REGISTRY_URL = process.env.SCHEMA_REGISTRY_URL || 'http://localhost:8081';

// Create services
const analyticsService = new AnalyticsService();
const kafkaConsumer = new KafkaConsumerService(
  KAFKA_BROKERS,
  KAFKA_TOPIC,
  KAFKA_GROUP_ID
);

// Create Avro Kafka consumer with a different group ID to get all messages
const avroKafkaConsumer = new AvroKafkaConsumerService(
  KAFKA_BROKERS,
  KAFKA_TOPIC,
  `${KAFKA_GROUP_ID}-avro`,
  SCHEMA_REGISTRY_URL
);

// Create Express app
const app = express();
const server = http.createServer(app);
const io = new Server(server);

// Set port
const PORT = process.env.PORT || 9300;

// Middleware
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Routes
app.get('/', (req, res) => {
  res.send('Analytics API is running');
});

app.get('/health', (req, res) => {
  const kafkaStatus = kafkaConsumer ? 'connected' : 'disconnected';
  const avroKafkaStatus = avroKafkaConsumer ? 'connected' : 'disconnected';
  res.json({
    status: 'healthy',
    kafka: kafkaStatus,
    avroKafka: avroKafkaStatus,
    errorCount: {
      json: kafkaConsumer.getErrorCount(),
      avro: avroKafkaConsumer.getErrorCount()
    }
  });
});

app.get('/analytics/dashboard', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

app.get('/api/analytics', (req, res) => {
  const analytics = analyticsService.getAnalytics();
  res.json(analytics);
});

app.get('/api/messages/avro', (req, res) => {
  const recentOrders = analyticsService.getRecentOrders(10).filter(order => order.source === 'avro');
  res.json({
    messages: recentOrders
  });
});

app.get('/api/messages/recent', (req, res) => {
  const recentOrders = analyticsService.getRecentOrders(10);
  res.json({
    messages: recentOrders
  });
});

app.get('/api/errors', (req, res) => {
  res.json({
    json: {
      errorCount: kafkaConsumer.getErrorCount(),
      lastErrors: kafkaConsumer.getLastErrors()
    },
    avro: {
      errorCount: avroKafkaConsumer.getErrorCount(),
      lastErrors: avroKafkaConsumer.getLastErrors()
    }
  });
});

// Socket.io for real-time updates
io.on('connection', (socket) => {
  console.log('A client connected');
  
  // Send current analytics data to the new client
  socket.emit('analytics', analyticsService.getAnalytics());
  
  socket.on('disconnect', () => {
    console.log('A client disconnected');
  });
});

// Setup Kafka consumer event handling
kafkaConsumer.onOrder((order: Order) => {
  console.log(`Received order via JSON: ${order.orderId}`);
  // Add source information
  order.source = 'json';
  analyticsService.addOrder(order);
  
  // Broadcast updated analytics to all connected clients
  io.emit('analytics', analyticsService.getAnalytics());
  io.emit('newOrder', order);
});

// Setup Avro Kafka consumer event handling
avroKafkaConsumer.onOrder((order: Order) => {
  console.log(`Received order via Avro: ${order.orderId}`);
  // Source is already set to 'avro' in the consumer
  analyticsService.addOrder(order);
  
  // Broadcast updated analytics to all connected clients
  io.emit('analytics', analyticsService.getAnalytics());
  io.emit('newOrder', order);
});

// Start Kafka consumers
kafkaConsumer.start().catch(error => {
  console.error('Failed to start Kafka JSON consumer:', error);
  // Continue running the API even if Kafka connection fails
});

avroKafkaConsumer.start().catch(error => {
  console.error('Failed to start Avro Kafka consumer:', error);
  // Continue running the API even if Kafka connection fails
});

// Start server
server.listen(PORT, () => {
  console.log(`Analytics API running on http://localhost:${PORT}`);
  console.log(`Dashboard available at http://localhost:${PORT}/analytics/dashboard`);
  console.log(`JSON Kafka consumer group: ${KAFKA_GROUP_ID}`);
  console.log(`Avro Kafka consumer group: ${KAFKA_GROUP_ID}-avro`);
  console.log(`Schema Registry URL: ${SCHEMA_REGISTRY_URL}`);
});
