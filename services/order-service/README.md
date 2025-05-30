# Order Service

A Java Spring Boot service for the Tower of Babel Kafka Schema Registry demo.

## Description

This service handles order processing operations using Avro schemas for data serialization and deserialization.

## Features

- Spring Boot REST API
- Kafka integration with Spring Kafka
- Avro schema-based data validation
- Automatic Java class generation from Avro schemas using Gradle

## Development

The service uses a schema-first approach, generating Java classes from Avro schemas during the build process.
