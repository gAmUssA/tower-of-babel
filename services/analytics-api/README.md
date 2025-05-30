# Analytics API

A Node.js/TypeScript service for the Tower of Babel Kafka Schema Registry demo.

## Description

This service provides analytics capabilities by consuming events from Kafka and exposing them via a REST API.

## Features

- Express.js REST API
- Kafka integration with KafkaJS
- Avro schema-based data validation
- Automatic TypeScript interface generation from Avro schemas

## Development

The service uses a schema-first approach, generating TypeScript interfaces from Avro schemas.
