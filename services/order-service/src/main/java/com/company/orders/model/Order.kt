package com.company.orders.model

import java.io.Serializable
import java.math.BigDecimal
import java.time.Instant
import java.util.UUID

/**
 * Order model for Java serialization (intentionally different from Avro schema)
 * This class will be used for the "broken" serialization demo
 */
data class Order(
    val orderId: UUID = UUID.randomUUID(),
    val userId: String,
    val amount: BigDecimal,
    val status: String,
    val items: List<OrderItem> = emptyList(),
    val createdAt: Instant = Instant.now()
) : Serializable

/**
 * Order item for Java serialization
 */
data class OrderItem(
    val productId: String,
    val quantity: Int,
    val price: BigDecimal
) : Serializable
