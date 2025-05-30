# Inventory Service

A Python FastAPI service for the Tower of Babel Kafka Schema Registry demo.

## Description

This service handles inventory management operations using Avro schemas for data serialization and deserialization.

## Features

- FastAPI REST API
- Kafka integration with Confluent Kafka client
- Avro schema-based data validation
- Automatic Python class generation from Avro schemas

## Development

The service uses a schema-first approach, generating Python dataclasses from Avro schemas.
