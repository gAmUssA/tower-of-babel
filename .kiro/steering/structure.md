# Project Structure

## Root Directory

```
tower-of-babel/
├── .devcontainer/          # Dev container configuration
├── .github/                # GitHub workflows and CI/CD
├── .kiro/                  # Kiro AI assistant configuration
├── docker-compose.yml      # Local Kafka + Schema Registry
├── docker-compose.cloud.yml # Confluent Cloud configuration
├── Makefile               # Build automation with emoji/colors
├── schemas/               # Central Avro schema repository
├── services/              # Microservices
├── scripts/               # Utility and demo scripts
└── docs/                  # Documentation
```

## Schema Repository (`schemas/`)

Central source of truth for all Avro schemas. Organized by version:

- `schemas/v1/` - Initial schema versions
- `schemas/v2/` - Evolved schemas
- `schemas/incompatible/` - Examples of breaking changes

Each service copies schemas from here during build process.

## Services Directory (`services/`)

### Order Service (`services/order-service/`)

Java/Spring Boot service with Gradle Kotlin DSL:

```
order-service/
├── build.gradle.kts           # Gradle build with Kotlin DSL
├── settings.gradle.kts        # Gradle settings
├── gradlew                    # Gradle wrapper script
├── gradle/wrapper/            # Gradle wrapper files
└── src/
    ├── main/
    │   ├── avro/             # Copied from central schemas/
    │   ├── java/com/company/orders/
    │   │   ├── OrderServiceApplication.kt
    │   │   ├── controller/   # REST controllers
    │   │   ├── model/        # Domain models
    │   │   └── service/      # Business logic
    │   └── resources/
    │       ├── application.yml
    │       └── application.properties
    └── test/kotlin/          # Kotlin tests
```

Generated code: `build/generated-main-avro-java/`

### Inventory Service (`services/inventory-service/`)

Python/FastAPI service:

```
inventory-service/
├── requirements.txt          # Python dependencies
├── pyproject.toml           # Python project metadata
├── .venv/                   # Virtual environment (created locally)
├── inventory_service/
│   ├── __init__.py
│   ├── main.py              # FastAPI application
│   └── consumer/
│       ├── kafka_consumer.py      # JSON consumer (broken)
│       └── avro_kafka_consumer.py # Avro consumer (working)
├── src/generated/           # Generated Python classes
├── scripts/
│   ├── generate_classes.py # Code generation script
│   └── smoke_test.py       # Smoke tests
└── tests/                   # Pytest tests
```

### Analytics API (`services/analytics-api/`)

Node.js/TypeScript service:

```
analytics-api/
├── package.json             # npm dependencies and scripts
├── tsconfig.json           # TypeScript configuration
├── jest.config.js          # Jest test configuration
├── src/
│   ├── index.ts            # Express application
│   ├── models/             # Domain models
│   ├── services/
│   │   ├── kafka-consumer.ts      # JSON consumer (broken)
│   │   ├── avro-kafka-consumer.ts # Avro consumer (working)
│   │   └── analytics-service.ts   # Business logic
│   ├── generated/          # Generated TypeScript interfaces
│   ├── scripts/
│   │   └── generate-types.js # Code generation script
│   └── public/
│       └── dashboard.html  # Web UI
├── scripts/
│   └── smoke-test.js       # Smoke tests
└── dist/                   # Compiled JavaScript (build output)
```

## Scripts Directory (`scripts/`)

### Demo Scripts (`scripts/demo/`)

Executable demo scenarios:
- `demo-1-tower-of-babel.sh` - Serialization chaos demo
- `demo-2-babel-fish.sh` - Schema Registry solution
- `demo-3-safe-evolution.sh` - Schema compatibility
- `demo-4-breaking-change-blocked.sh` - Breaking change prevention

### Test Scripts (`scripts/test/`)

Automated test scenarios:
- `test-1-serialization-failures.sh`
- `test-2-avro-integration.sh`
- `test-3-schema-evolution.sh`
- `test-4-compatibility-checks.sh`

### Utility Scripts (`scripts/utils/`)

Helper scripts:
- `wait-for-services.sh` - Wait for Kafka/Schema Registry startup
- `register-schemas.sh` - Register schemas with Schema Registry
- `evolve-schema.sh` - Demonstrate schema evolution
- `cleanup-topics.sh` - Clean Kafka topics
- `cleanup-schemas.sh` - Clean Schema Registry subjects

## Documentation (`docs/`)

- `requirements.md` - Detailed technical requirements (PRD)
- `plan.md` - Implementation plan
- `tasks.md` - Task tracking
- `SCHEMA_EVOLUTION.md` - Schema evolution guide
- `*.mmd` - Mermaid diagrams

## Code Generation Pattern

All services follow schema-first development:

1. **Central Schema**: Define in `schemas/v1/order-event.avsc`
2. **Copy to Service**: Build process copies to service-specific location
3. **Generate Code**: Build tool generates language-specific classes
4. **Use Generated Code**: Services import and use generated types

This ensures type safety and consistency across all three languages.

## Logs

Service logs are written to `services/logs/` with `.log` and `.pid` files for each service.

## Configuration Files

- `.env.example` - Template for environment variables
- `.gitignore` - Git ignore patterns
- `renovate.json` - Dependency update automation
