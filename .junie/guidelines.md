# Project Development Guidelines (Tower of Babel → Babel Fish Demo)

This document captures project-specific build, configuration, and testing practices that will accelerate work on this repository. It assumes an advanced developer familiar with Docker, JVM, Python, and Node toolchains.

Last verified on: 2025-10-29


## 1) Build and Configuration Instructions

The repo orchestrates three microservices plus local Kafka + Schema Registry.
- Order Service: Java 17, Spring Boot 3.x, Gradle (Kotlin DSL)
- Inventory Service: Python 3.9+ (tested with 3.12), FastAPI
- Analytics API: Node.js 18+, TypeScript
- Infra: Confluent Platform 7.9.x (Kafka KRaft mode) + Schema Registry

Top-level automation: Makefile. Prefer these over ad‑hoc commands.

- Local infra up (Kafka + SR) and readiness checks:
  - make setup
  - make status (lists topics and SR subjects)
- Confluent Cloud mode:
  - cp .env.example .env and fill in credentials
  - make setup-cloud
- Code generation (Avro → per-language types):
  - make generate
- Full build of all services:
  - make build
- Demos (serialization failures vs Avro fix):
  - make demo-broken, make demo-fixed, make phase3-* and phase4-*

Notes and pitfalls:
- KRaft only; no Zookeeper in docker-compose.yml.
- Default ports: Kafka ext 29092, SR 8081, Inventory API 9000, Order Svc 9080, Analytics 9300.
- Do NOT hand-edit any generated sources; always run make generate after schema edits under schemas/.
- Inventory Service starts Kafka consumers on startup; it tolerates missing Kafka (logs and continues). This is by design and leveraged in tests.


### Service-specific build setup

Java (Order Service)
- Wrapper script present: services/order-service/gradlew.
- Typical tasks: ./gradlew build, ./gradlew test, ./gradlew bootRun.
- Avro codegen: ./gradlew generateAvroJava (also called by make generate).

Python (Inventory Service)
- Recommended venv path: services/inventory-service/.venv
- Installing deps (verified):
  - python3 -m venv services/inventory-service/.venv
  - source services/inventory-service/.venv/bin/activate
  - pip install -r services/inventory-service/requirements.txt
  - Optional dev install (editable): cd services/inventory-service && pip install -e .[dev]
- Run service locally: source .venv/bin/activate && python -m inventory_service.main

Node (Analytics API)
- Install deps: cd services/analytics-api && npm ci
- Build: npm run build; Start: npm start; Types codegen: npm run generate-types

Infrastructure via Docker
- make setup → docker-compose up -d followed by scripts/wait-for-services.sh.
- make demo-reset cleans topics/schemas and restarts containers.


## 2) Testing Information

### Test runners per service
- Java: Gradle (./gradlew test)
- Python: pytest (configured via pyproject.toml → [tool.pytest] testpaths = ["tests"]). Requirements include pytest and httpx already.
- Node: No formal unit tests checked in, but a smoke script exists: services/analytics-api/scripts/smoke-test.js (runnable via make analytics-api-smoke-test).

### Running existing checks and smoke tests
- Python inventory smoke: make inventory-service-smoke-test (imports confluent-kafka, avro, consumer wiring; non-networking checks).
- Phase 4 end-to-end checks: make phase4-test (scripts/test-phase4.sh validates SR and topic flow via curl + CLI).

### Adding and running new tests (Python example)
The inventory-service currently has an empty tests/ directory; pytest is configured. Use FastAPI’s TestClient and rely on the app’s resilience to missing Kafka.

- Create tests under services/inventory-service/tests/ with filenames test_*.py. Example used and VERIFIED on 2025-10-29:

  File: services/inventory-service/tests/test_health.py
  ---
  from fastapi.testclient import TestClient
  from inventory_service.main import app

  def test_health_endpoint_boots_without_kafka():
      with TestClient(app) as client:
          resp = client.get("/health")
          assert resp.status_code == 200
          body = resp.json()
          assert body["status"] == "healthy"
          assert "kafka" in body and "avro_kafka" in body
          assert "error_count" in body and {"json", "avro"}.issubset(body["error_count"].keys())
  ---

- Commands executed to run the test successfully:
  1) python3 -m venv services/inventory-service/.venv
  2) source services/inventory-service/.venv/bin/activate
  3) pip install -r services/inventory-service/requirements.txt
  4) Optional but recommended for test import resolution: cd services/inventory-service && pip install -e .[dev]
  5) Run: PYTHONPATH=services/inventory-service python -m pytest -q services/inventory-service/tests/test_health.py

Rationale: inventory_service.main’s lifespan handler catches Kafka startup errors and still serves HTTP, allowing hermetic HTTP-level tests without Kafka.

### Guidelines for adding tests in other services
- Java (Order Service): Place tests under services/order-service/src/test/java. Use Spring Boot’s @SpringBootTest cautiously—prefer slicing or unit-level tests to avoid Kafka.
- Node (Analytics): If adding Jest tests, prefer to stub Kafka client usage. Keep generated TypeScript types under src/generated/ separate from test fixtures.


## 3) Additional Development Information

Schema-first workflow
- Define/modify Avro in schemas/v*/. Maintain compatibility; prefer adding optional union fields with defaults.
- Regenerate artifacts with make generate. Never edit generated code by hand.

Topic and subject conventions
- Topics: lowercase-with-hyphens; test topics prefixed with test-; DLQ as <topic>-dlq.
- SR subjects: value subjects follow <topic>-value. Keep evolution backward-compatible.

Local debugging tips
- Inventory Service
  - HEALTH: GET http://localhost:9000/health (works even w/o Kafka).
  - Inventory snapshot: GET /inventory?source=avro to see only Avro-processed items (when Kafka present).
  - To avoid Kafka in unit tests, import app and use TestClient as shown; do not start uvicorn.
- Order Service
  - Use ./gradlew bootRun for manual testing; configure Kafka endpoints via application.properties.
  - For schema mismatches, consult logs for subject/version.
- Analytics API
  - Environment variables via .env or process env; keep generated types in src/generated.

Build hygiene
- make clean removes Docker resources and service build artifacts (Gradle, node_modules, __pycache__).
- Keep credentials out of VCS; .env is user-local.


## 4) What was validated in this update
- Python inventory-service test harness works with pytest and FastAPI TestClient.
- The sample health test above PASSED locally on 2025-10-29 with Python 3.12 after installing requirements and performing an editable install.
- No changes were required to service code to enable testing.


## 5) Quick command reference
- Infra up: make setup
- Codegen: make generate
- Build all: make build
- Inventory tests:
  - python3 -m venv services/inventory-service/.venv && source services/inventory-service/.venv/bin/activate
  - pip install -r services/inventory-service/requirements.txt && (cd services/inventory-service && pip install -e .[dev])
  - PYTHONPATH=services/inventory-service python -m pytest -q services/inventory-service/tests
- Smoke tests: make inventory-service-smoke-test, make analytics-api-smoke-test
- E2E checks: make phase4-test
