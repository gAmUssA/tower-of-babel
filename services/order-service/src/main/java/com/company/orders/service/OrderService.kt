package com.company.orders.service

import com.company.orders.model.Order
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
    @Value("\${kafka.bootstrap-servers:localhost:29092}")
    private val bootstrapServers: String,
    
    @Value("\${kafka.topic.orders:orders}")
    private val ordersTopic: String
) {
    private val logger = LoggerFactory.getLogger(OrderService::class.java)
    private val orderStore = ConcurrentHashMap<UUID, Order>()
    
    // Kafka template for JSON serialization
    private val kafkaTemplate = createKafkaTemplate()
    
    // Kafka template for Java serialization (broken)
    private val javaSerializationKafkaTemplate = createJavaSerializationKafkaTemplate()
    
    fun getAllOrders(): List<Order> {
        return orderStore.values.toList()
    }
    
    fun getOrder(orderId: UUID): Order? {
        return orderStore[orderId]
    }
    
    fun saveOrder(order: Order): Order {
        orderStore[order.orderId] = order
        
        // Send to Kafka using JSON serialization
        val future = kafkaTemplate.send(ordersTopic, order.orderId.toString(), order)
        future.whenComplete { _, ex -> 
            if (ex == null) {
                logger.info("Order sent to Kafka: ${order.orderId}")
            } else {
                logger.error("Failed to send order to Kafka: ${order.orderId}", ex)
            }
        }
        
        return order
    }
    
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
}
