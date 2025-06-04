# Tower of Babel Demo Makefile
# Kafka Schema Registry Demo with emoji and colors for better readability

# Colors
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

.PHONY: help setup setup-cloud clean status demo-reset generate build install-deps install-python-deps install-node-deps run-order-service run-inventory-service run-analytics-api phase3-demo phase3-java-serialization phase3-json-mismatch phase3-type-inconsistency phase3-normal-flow phase4-demo phase4-test inventory-service-smoke-test

help: ## 📋 Show this help message
	@echo "$(GREEN)🚀 Kafka Schema Registry Demo$(NC)"
	@echo "$(YELLOW)Available commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

setup: ## 🏗️  Setup local environment with Docker
	@echo "$(GREEN)🏗️  Setting up local Kafka environment...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)⏳ Waiting for services to be ready...$(NC)"
	./scripts/wait-for-services.sh
	@echo "$(GREEN)✅ Environment ready!$(NC)"

setup-cloud: ## ☁️  Setup for Confluent Cloud
	@echo "$(GREEN)☁️  Configuring for Confluent Cloud...$(NC)"
	@if [ ! -f .env ]; then \
		echo "$(RED)❌ .env file not found. Creating from template...$(NC)"; \
		cp .env.example .env; \
		echo "$(YELLOW)⚠️  Please edit .env file with your Confluent Cloud credentials$(NC)"; \
		exit 1; \
	fi
	docker-compose -f docker-compose.cloud.yml up -d
	@echo "$(GREEN)✅ Cloud configuration ready!$(NC)"

clean: ## 🧹 Clean up everything
	@echo "$(RED)🧹 Cleaning up everything...$(NC)"
	@echo "$(YELLOW)🧹 Cleaning Docker containers and volumes...$(NC)"
	docker-compose down -v
	docker system prune -f
	@echo "$(YELLOW)🧹 Cleaning Java Order Service build artifacts...$(NC)"
	cd services/order-service && ./gradlew clean || echo "$(YELLOW)⚠️  No Gradle build to clean$(NC)"
	@echo "$(YELLOW)🧹 Cleaning Python Inventory Service build artifacts...$(NC)"
	rm -rf services/inventory-service/__pycache__ services/inventory-service/.pytest_cache services/inventory-service/inventory_service/__pycache__
	@echo "$(YELLOW)🧹 Cleaning Node.js Analytics API build artifacts...$(NC)"
	rm -rf services/analytics-api/dist services/analytics-api/node_modules
	@echo "$(GREEN)✨ Cleanup complete!$(NC)"

demo-reset: ## 🔄 Reset demo environment
	@echo "$(YELLOW)🔄 Resetting demo state...$(NC)"
	./scripts/cleanup-topics.sh
	./scripts/cleanup-schemas.sh
	docker-compose restart
	@echo "$(GREEN)✨ Demo reset complete!$(NC)"

status: ## 📊 Check service status
	@echo "$(YELLOW)📊 Checking service status...$(NC)"
	@echo "$(YELLOW)Docker services:$(NC)"
	@docker-compose ps
	@echo "$(YELLOW)Kafka topics:$(NC)"
	@docker-compose exec -T kafka kafka-topics --bootstrap-server kafka:9092 --list || echo "$(RED)❌ Kafka not available$(NC)"
	@echo "$(YELLOW)Schema Registry subjects:$(NC)"
	@curl -s http://localhost:8081/subjects | jq . || echo "$(RED)❌ Schema Registry not available$(NC)"

generate: ## 🔧 Generate code from schemas
	@echo "$(GREEN)🔧 Generating code from Avro schemas...$(NC)"
	@echo "$(YELLOW)Java POJOs (Gradle + Kotlin DSL):$(NC)"
	cd services/order-service && ./gradlew generateAvroJava
	@echo "$(YELLOW)Python dataclasses:$(NC)"
	cd services/inventory-service && python3 scripts/generate_classes.py
	@echo "$(YELLOW)TypeScript interfaces:$(NC)"
	cd services/analytics-api && npm run generate-types
	@echo "$(GREEN)✅ Code generation complete!$(NC)"

install-deps: install-python-deps install-node-deps ## 📦 Install all dependencies
	@echo "$(GREEN)✅ All dependencies installed!$(NC)"

install-python-deps: ## 📦 Install Python dependencies
	@echo "$(GREEN)📦 Installing Python dependencies...$(NC)"
	@if [ ! -d services/inventory-service/.venv ]; then \
		echo "$(YELLOW)🔧 Creating Python virtual environment with Python 3.12...$(NC)"; \
		cd services/inventory-service && python3.12 -m venv .venv; \
	fi
	@echo "$(YELLOW)🔧 Installing dependencies for Python 3.12...$(NC)"
	cd services/inventory-service && source .venv/bin/activate && \
	pip install --upgrade pip && \
	pip install wheel && \
	pip install -r requirements.txt
	@echo "$(GREEN)✅ Python dependencies installed in virtual environment!$(NC)"

install-node-deps: ## 📦 Install Node.js dependencies
	@echo "$(GREEN)📦 Installing Node.js dependencies...$(NC)"
	cd services/analytics-api && npm ci
	@echo "$(GREEN)✅ Node.js dependencies installed!$(NC)"

build: install-deps generate ## 💪  Build all services
	@echo "$(GREEN)💪  Building all services...$(NC)"

	@echo "$(YELLOW)💪 Building Java Order Service (Gradle):$(NC)"
	cd services/order-service && ./gradlew build --info
	@echo "$(GREEN)✅ Java Order Service build complete!$(NC)"

	@echo "$(YELLOW)💪 Building Python Inventory Service:$(NC)"
	@if [ ! -d services/inventory-service/.venv ]; then \
		echo "$(YELLOW)🔧 Creating Python virtual environment...$(NC)"; \
		cd services/inventory-service && python3 -m venv .venv; \
		echo "$(YELLOW)🔧 Installing dependencies in virtual environment...$(NC)"; \
		cd services/inventory-service && source .venv/bin/activate && pip install -r requirements.txt; \
	fi
	cd services/inventory-service && source .venv/bin/activate && python -m pytest --tb=short || echo "$(YELLOW)⚠️  No tests to run yet$(NC)"
	@echo "$(GREEN)✅ Python Inventory Service build complete!$(NC)"

	@echo "$(YELLOW)💪 Building Node.js Analytics API:$(NC)"
	cd services/analytics-api && npm ci && npm run build
	@echo "$(GREEN)✅ Node.js Analytics API build complete!$(NC)"

	@echo "$(GREEN)🎉 All builds successful!$(NC)"

demo-codegen: ## 🎭 Demo schema-first development
	@echo "$(GREEN)🎭 Demonstrating schema-first development...$(NC)"
	@echo "$(YELLOW)1. Show schema definition$(NC)"
	cat schemas/v1/order-event.avsc
	@echo "$(YELLOW)2. Generate code artifacts$(NC)"
	make generate
	@echo "$(YELLOW)3. Show generated classes$(NC)"
	@echo "$(GREEN)Java (generated by Gradle):$(NC)"
	find services/order-service/build/generated-main-avro-java -name "*.java" | head -3
	@echo "$(GREEN)Python (generated):$(NC)"
	find services/inventory-service/src/generated -name "*.py" | head -3
	@echo "$(GREEN)TypeScript (generated):$(NC)"
	find services/analytics-api/src/generated -name "*.ts" | head -3
	@echo "$(GREEN)🎉 Schema drives code generation!$(NC)"

run-order-service: ## 🚀 Run Java Order Service
	@echo "$(GREEN)🚀 Starting Order Service...$(NC)"
	cd services/order-service && ./gradlew bootRun


run-inventory-service: ## 🚀 Run Python Inventory Service
	@echo "$(GREEN)🚀 Starting Inventory Service...$(NC)"
	@echo "$(YELLOW)Using Python virtual environment...$(NC)"
	cd services/inventory-service && source .venv/bin/activate && python -m inventory_service.main

run-analytics-api: install-node-deps ## 🚀 Run Node.js Analytics API
	@echo "$(GREEN)🚀 Starting Analytics API...$(NC)"
	cd services/analytics-api && npm start

phase3-demo: ## 🎭 Run Phase 3 Demo (all scenarios)
	@echo "$(GREEN)🎭 Running Phase 3 Demo - Serialization Scenarios...$(NC)"
	@echo "$(YELLOW)This demo shows different serialization scenarios:$(NC)"
	@echo "$(YELLOW)1. Normal flow (everything works)$(NC)"
	@echo "$(YELLOW)2. Java serialization failures$(NC)"
	@echo "$(YELLOW)3. JSON field name mismatch failures$(NC)"
	@echo "$(YELLOW)4. Type inconsistency failures$(NC)"
	@echo "$(GREEN)Make sure all services are running:$(NC)"
	@echo "$(GREEN)- make run-order-service (in one terminal)$(NC)"
	@echo "$(GREEN)- make run-inventory-service (in another terminal)$(NC)"
	@echo "$(GREEN)- make run-analytics-api (in a third terminal)$(NC)"
	@echo "$(GREEN)Then run each demo scenario:$(NC)"
	@echo "$(GREEN)- make phase3-normal-flow$(NC)"
	@echo "$(GREEN)- make phase3-java-serialization$(NC)"
	@echo "$(GREEN)- make phase3-json-mismatch$(NC)"
	@echo "$(GREEN)- make phase3-type-inconsistency$(NC)"

demo-broken: ## 💥 Start failure scenarios demo
	@echo "$(GREEN)💥 Starting failure scenarios demo...$(NC)"
	@echo "$(YELLOW)This will demonstrate serialization issues across languages$(NC)"
	./scripts/start-broken-services.sh
	@echo "$(GREEN)🎭 Demo ready! Run failure scenarios with:$(NC)"
	@echo "$(GREEN)- make phase3-java-serialization$(NC)"
	@echo "$(GREEN)- make phase3-json-mismatch$(NC)"
	@echo "$(GREEN)- make phase3-type-inconsistency$(NC)"

demo-fixed: ## ✨ Switch to Avro serialization
	@echo "$(GREEN)✨ Switching to Avro serialization...$(NC)"
	@echo "$(YELLOW)This will demonstrate how Schema Registry fixes serialization issues$(NC)"
	./scripts/start-avro-services.sh
	@echo "$(GREEN)🎉 Avro demo ready! Run with:$(NC)"
	@echo "$(GREEN)- make phase4-demo$(NC)"

demo-evolution: ## 🧬 Demonstrate schema evolution
	@echo "$(GREEN)🧬 Starting schema evolution demo...$(NC)"
	@echo "$(YELLOW)This will show backward/forward compatibility with schema changes$(NC)"
	./scripts/evolve-schema.sh
	@echo "$(GREEN)🎉 Schema evolution demo complete!$(NC)"

phase3-java-serialization: ## 🎭 Demo Java serialization failures
	@echo "$(GREEN)🎭 Running Java Serialization Failure Demo...$(NC)"
	chmod +x scripts/demo/trigger-java-serialization-failure.sh
	./scripts/demo/trigger-java-serialization-failure.sh


phase3-json-mismatch: ## 🎭 Demo JSON field name mismatch failures
	@echo "$(GREEN)🎭 Running JSON Field Name Mismatch Demo...$(NC)"
	chmod +x scripts/demo/trigger-json-mismatch-failure.sh
	./scripts/demo/trigger-json-mismatch-failure.sh


phase3-type-inconsistency: ## 🎭 Demo type inconsistency failures
	@echo "$(GREEN)🎭 Running Type Inconsistency Failure Demo...$(NC)"
	chmod +x scripts/demo/trigger-type-inconsistency-failure.sh
	./scripts/demo/trigger-type-inconsistency-failure.sh


phase3-normal-flow: ## ✨ Demo normal flow scenario (everything works)
	@echo "$(GREEN)✨ Running Normal Flow Demo...$(NC)"
	chmod +x scripts/demo/trigger-normal-flow.sh
	./scripts/demo/trigger-normal-flow.sh

phase4-demo: ## 🚀 Run Phase 4 Demo (Schema Registry with Avro)
	@echo "$(GREEN)🚀 Running Phase 4 Demo - Schema Registry Integration with Avro...$(NC)"
	chmod +x scripts/phase4-demo.sh
	./scripts/phase4-demo.sh

phase4-test: ## 🧪 Run Phase 4 Tests (Schema Registry with Avro)
	@echo "$(GREEN)🧪 Running Phase 4 Test Suite - Schema Registry Integration with Avro...$(NC)"
	chmod +x scripts/test-phase4.sh
	./scripts/test-phase4.sh

inventory-service-smoke-test: ## 🔥 Run smoke tests for the Python inventory service
	@echo "$(GREEN)🔥 Running Smoke Tests for Python Inventory Service...$(NC)"
	@echo "$(YELLOW)Testing Python dependencies and critical functionality...$(NC)"
	chmod +x services/inventory-service/scripts/smoke_test.py
	cd services/inventory-service && source .venv/bin/activate && python scripts/smoke_test.py

analytics-api-smoke-test: ## 🔥 Run smoke tests for the Node.js analytics API
	@echo "$(GREEN)🔥 Running Smoke Tests for Node.js Analytics API...$(NC)"
	@echo "$(YELLOW)Testing Node.js dependencies and critical functionality...$(NC)"
	chmod +x services/analytics-api/scripts/smoke-test.js
	cd services/analytics-api && node scripts/smoke-test.js
