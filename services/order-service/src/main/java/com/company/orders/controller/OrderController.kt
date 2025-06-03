package com.company.orders.controller

import com.company.orders.model.Order
import com.company.orders.model.OrderItem
import com.company.orders.service.OrderService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.math.BigDecimal
import java.util.UUID

@RestController
@RequestMapping("/orders")
class OrderController(private val orderService: OrderService) {

    @GetMapping
    fun getAllOrders(): ResponseEntity<List<Order>> {
        return ResponseEntity.ok(orderService.getAllOrders())
    }

    @GetMapping("/{orderId}")
    fun getOrder(@PathVariable orderId: String): ResponseEntity<Order> {
        val order = orderService.getOrder(UUID.fromString(orderId))
        return if (order != null) ResponseEntity.ok(order) else ResponseEntity.notFound().build()
    }

    @PostMapping
    fun createOrder(@RequestBody orderRequest: OrderRequest): ResponseEntity<Order> {
        val order = Order(
            userId = orderRequest.userId,
            amount = orderRequest.amount,
            status = "CREATED",
            items = orderRequest.items.map { 
                OrderItem(
                    productId = it.productId,
                    quantity = it.quantity,
                    price = it.price
                )
            }
        )
        val savedOrder = orderService.saveOrder(order)
        return ResponseEntity.ok(savedOrder)
    }

    @PostMapping("/broken")
    fun createBrokenOrder(@RequestBody orderRequest: OrderRequest): ResponseEntity<Order> {
        val order = Order(
            userId = orderRequest.userId,
            amount = orderRequest.amount,
            status = "CREATED",
            items = orderRequest.items.map { 
                OrderItem(
                    productId = it.productId,
                    quantity = it.quantity,
                    price = it.price
                )
            }
        )
        val savedOrder = orderService.saveOrderWithJavaSerialization(order)
        return ResponseEntity.ok(savedOrder)
    }
    
    @PostMapping("/avro")
    fun createOrderWithAvro(@RequestBody orderRequest: OrderRequest): ResponseEntity<Order> {
        val order = Order(
            userId = orderRequest.userId,
            amount = orderRequest.amount,
            status = "CREATED",
            items = orderRequest.items.map { 
                OrderItem(
                    productId = it.productId,
                    quantity = it.quantity,
                    price = it.price
                )
            }
        )
        val savedOrder = orderService.saveOrderWithAvroSerialization(order)
        return ResponseEntity.ok(savedOrder)
    }
}

data class OrderRequest(
    val userId: String,
    val amount: BigDecimal,
    val items: List<OrderItemRequest>
)

data class OrderItemRequest(
    val productId: String,
    val quantity: Int,
    val price: BigDecimal
)
