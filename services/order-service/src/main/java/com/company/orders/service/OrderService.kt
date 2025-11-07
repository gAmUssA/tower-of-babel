package com.company.orders.service

import com.company.orders.OrderEvent
import com.company.orders.model.Order
import io.confluent.kafka.serializers.KafkaAvroSerializer
import io.confluent.kafka.serializers.KafkaAvroSerializerConfig
import org.apache.kafka.clients.producer.ProducerConfig
import org.apache.kafka.clients.producer.ProducerRecord
import org.apache.kafka.common.serialization.StringSerializer
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.kafka.core.DefaultKafkaProducerFactory
import org.springframework.kafka.core.KafkaTemplate
import org.springframework.stereotype.Service
import java.io.ByteArrayOutputStream
import java.io.ObjectOutputStream
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

@Service
class OrderService(
    @param:Value("\${kafka.bootstrap-servers:localhost:29092}")
    private val bootstrapServers: String,
    
    @param:Value("\${kafka.topic.orders:orders}")
    private val ordersTopic: String,
    
    @param:Value("\${spring.kafka.properties.schema.registry.url:http://localhost:8081}")
    private val schemaRegistryUrl: String
) {
    private val logger = LoggerFactory.getLogger(OrderService::class.java)
    private val orderStore = ConcurrentHashMap<UUID, Order>()
    
    // Kafka template for JSON serialization (broken serialization for Phase 3 demo)
    private val kafkaTemplate = createKafkaTemplate()
    
    // Kafka template for Java serialization (broken serialization for Phase 3 demo)
    private val javaSerializationKafkaTemplate = createJavaSerializationKafkaTemplate()
    
    // Kafka template for Avro serialization (proper serialization for Phase 4 demo)
    private val avroSerializationKafkaTemplate = createAvroSerializationKafkaTemplate()
    
    fun getAllOrders(): List<Order> {
        return orderStore.values.toList()
    }
    
    fun getOrder(orderId: UUID): Order? {
        return orderStore[orderId]
    }
    
    // Phase 3: JSON serialization (will be kept for demo purposes)
    fun saveOrder(order: Order): Order {
        orderStore[order.orderId] = order
        
        // Send to Kafka using JSON serialization
        val future = kafkaTemplate.send(ordersTopic, order.orderId.toString(), order)
        future.whenComplete { _, ex -> 
            if (ex == null) {
                logger.info("Order sent to Kafka using JSON serialization: ${order.orderId}")
            } else {
                logger.error("Failed to send order to Kafka using JSON serialization: ${order.orderId}", ex)
            }
        }
        
        return order
    }
    
    // Phase 3: Java serialization (will be kept for demo purposes)
    fun saveOrderWithJavaSerialization(order: Order): Order {
        orderStore[order.orderId] = order
        
        // Send to Kafka using Java serialization (this will cause deserialization issues)
        val serializedOrder = serializeOrderToByteArray(order)
        val record = ProducerRecord<String, ByteArray>(ordersTopic, order.orderId.toString(), serializedOrder)
        
        val future = javaSerializationKafkaTemplate.send(record)
        future.whenComplete { _, ex -> 
            if (ex == null) {
                logger.info("Order sent to Kafka using Java serialization: ${order.orderId}")
            } else {
                logger.error("Failed to send order to Kafka using Java serialization: ${order.orderId}", ex)
            }
        }
        
        return order
    }
    
    // Phase 4: Avro serialization with Schema Registry
    fun saveOrderWithAvroSerialization(order: Order): Order {
        orderStore[order.orderId] = order
        
        // Convert our Order model to the Avro-generated OrderEvent
        val orderEvent = OrderEvent.newBuilder()
            .setOrderId(order.orderId.toString())
            .setUserId(order.userId)
            .setAmount(order.amount.toDouble())
            .setStatus(order.status)
            .build()
        
        // Send to Kafka using Avro serialization
        val future = avroSerializationKafkaTemplate.send(ordersTopic, order.orderId.toString(), orderEvent)
        future.whenComplete { _, ex -> 
            if (ex == null) {
                logger.info("Order sent to Kafka using Avro serialization: ${order.orderId}")
            } else {
                logger.error("Failed to send order to Kafka using Avro serialization: ${order.orderId}", ex)
            }
        }
        
        return order
    }
    
    private fun serializeOrderToByteArray(order: Order): ByteArray {
        ByteArrayOutputStream().use { byteStream ->
            ObjectOutputStream(byteStream).use { objectStream ->
                objectStream.writeObject(order)
                return byteStream.toByteArray()
            }
        }
    }
    
    private fun createKafkaTemplate(): KafkaTemplate<String, Order> {
        val props = mapOf(
            ProducerConfig.BOOTSTRAP_SERVERS_CONFIG to bootstrapServers,
            ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG to StringSerializer::class.java,
            ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG to org.springframework.kafka.support.serializer.JsonSerializer::class.java
        )
        
        val producerFactory = DefaultKafkaProducerFactory<String, Order>(props)
        return KafkaTemplate(producerFactory)
    }
    
    private fun createJavaSerializationKafkaTemplate(): KafkaTemplate<String, ByteArray> {
        val props = mapOf(
            ProducerConfig.BOOTSTRAP_SERVERS_CONFIG to bootstrapServers,
            ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG to StringSerializer::class.java,
            ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG to org.apache.kafka.common.serialization.ByteArraySerializer::class.java
        )
        
        val producerFactory = DefaultKafkaProducerFactory<String, ByteArray>(props)
        return KafkaTemplate(producerFactory)
    }
    
    private fun createAvroSerializationKafkaTemplate(): KafkaTemplate<String, OrderEvent> {
        val props = mapOf(
            ProducerConfig.BOOTSTRAP_SERVERS_CONFIG to bootstrapServers,
            ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG to StringSerializer::class.java,
            ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG to KafkaAvroSerializer::class.java,
            KafkaAvroSerializerConfig.SCHEMA_REGISTRY_URL_CONFIG to schemaRegistryUrl,
            // Use specific Avro record classes instead of GenericRecord
            "specific.avro.reader" to true
        )
        
        val producerFactory = DefaultKafkaProducerFactory<String, OrderEvent>(props)
        return KafkaTemplate(producerFactory)
    }
}
