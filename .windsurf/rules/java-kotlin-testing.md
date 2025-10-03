---
trigger: glob
description: 
globs: **/*.java, **/*.kt
---

# Java/Kotlin Testing Standards

## Test Framework Configuration

- Use JUnit 5 (Jupiter) for all tests
- Build system: Gradle with Kotlin DSL
- Test location: `src/test/kotlin/com/company/orders/`
- Test naming: `*Test.kt` or `*Test.java`

## Running Tests

```bash
cd services/order-service
./gradlew test                           # Run all tests
./gradlew test --tests "ClassName"       # Run specific test class
./gradlew test --info                    # Verbose output
```

## Test Structure Pattern

Use Kotlin backtick syntax for descriptive test names with Given-When-Then:

```kotlin
package com.company.orders.model

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.Assertions.*

class OrderTest {
    @Test
    fun `should create order with required fields`() {
        // Given
        val userId = "user123"
        
        // When
        val order = Order(userId = userId, amount = BigDecimal("99.99"), status = "PENDING")
        
        // Then
        assertNotNull(order.orderId)
        assertEquals(userId, order.userId)
    }
}
```

## Kafka Integration Testing

ALWAYS use Testcontainers for Kafka tests:

```kotlin
@Testcontainers
class KafkaProducerTest {
    
    @Container
    private val kafka = KafkaContainer(DockerImageName.parse("confluentinc/cp-kafka:7.9.2"))
    
    @Test
    fun `should produce order event to Kafka`() {
        // Test implementation with real Kafka container
    }
}
```

## Test Organization

- Place unit tests in `src/test/kotlin/[package]/`
- Integration tests in `src/test/kotlin/[package]/integration/`
- Use `@BeforeEach` and `@AfterEach` for setup/cleanup
- Clean up Kafka resources in `@AfterEach` methods

## Code Coverage

- Minimum 80% coverage for service layer
- 100% coverage for critical business logic
- Use JaCoCo for coverage reporting
- Exclude generated Avro classes from coverage

## NEVER

- Use blocking Kafka clients in async contexts
- Test against real Schema Registry in unit tests
- Hardcode ports or broker addresses in tests
- Skip cleanup in @AfterEach (causes test pollution)