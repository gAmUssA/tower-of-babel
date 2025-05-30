# Tower of Babel to Babel Fish Demo

A demonstration project showcasing the evolution from chaotic polyglot Kafka architecture to Schema Registry-managed data contracts.

## 🚀 Project Overview

This demo illustrates how Schema Registry solves cross-language serialization challenges in a distributed system. It demonstrates:

1. **Tower of Babel** - Serialization chaos across languages
2. **Babel Fish** - Schema Registry solution with code generation
3. **Safe Evolution** - Schema compatibility management
4. **Prevented Disasters** - Blocking incompatible changes

## 🏗️ System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Order Service │    │ Inventory Svc   │    │ Analytics API   │
│   (Java/Spring) │    │ (Python/FastAPI)│    │ (Node.js/Express│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │ Kafka + Schema  │
                    │    Registry     │
                    └─────────────────┘
```

## 🛠️ Technology Stack

- **Kafka**: Confluent Platform 7.9.0 (KRaft mode, no Zookeeper)
- **Schema Registry**: Confluent Platform 7.9.0
- **Order Service**: Java 17 + Spring Boot 3.x + Gradle/Kotlin DSL
- **Inventory Service**: Python 3.9+ + FastAPI + uv
- **Analytics API**: Node.js 18+ + Express + TypeScript

## 🚀 Getting Started

### Prerequisites

- Docker and Docker Compose
- Java 17+
- Python 3.9+
- Node.js 18+
- Make

### Quick Start

```bash
# Set up local environment
make setup

# Check service status
make status

# Clean up everything
make clean
```

## 📊 Demo Scenarios

### 1. Tower of Babel (Serialization Chaos)

Demonstrates cross-language serialization failures:
- Java Object Serialization → Python can't deserialize
- JSON field naming inconsistencies
- Type mismatches between languages

### 2. Babel Fish (Schema Registry Solution)

Shows how Schema Registry enables:
- Centralized schema management
- Automatic code generation
- Type safety across languages

### 3. Safe Evolution (Schema Compatibility)

Demonstrates how Schema Registry enables:
- Adding optional fields safely
- Backward/forward compatibility
- Automatic code regeneration

### 4. Prevented Disasters (Breaking Changes)

Shows how Schema Registry prevents:
- Removing required fields
- Incompatible type changes
- Other breaking schema modifications

## 📁 Project Structure

```
tower-of-babel/
├── docker-compose.yml          # Local Kafka + Schema Registry
├── docker-compose.cloud.yml    # Confluent Cloud configuration
├── Makefile                    # Automation with emoji/colors
├── schemas/                    # Central Avro schema repository
├── services/
│   ├── order-service/          # Java/Spring Boot
│   ├── inventory-service/      # Python/FastAPI
│   └── analytics-api/          # Node.js/Express
├── scripts/                    # Utility scripts
└── docs/                       # Documentation
```

## 📝 Documentation

- [Requirements](docs/requirements.md)
- [Implementation Plan](docs/plan.md)
- [Task List](docs/tasks.md)

## 🧪 Development Status

- ✅ Phase 1: Infrastructure Foundation
- ⏳ Phase 2: Schema-First Development
- 🔜 Phase 3: Broken Services Implementation
- 🔜 Phase 4: Schema Registry Integration
- 🔜 Phase 5: Evolution and Automation
- 🔜 Phase 6: Polish and Testing
