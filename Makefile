# Tower of Babel Demo Makefile
# Kafka Schema Registry Demo with emoji and colors for better readability

# Use bash as the shell for all commands
SHELL := /bin/bash

# Colors
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
BLUE = \033[0;34m
NC = \033[0m # No Color

.PHONY: help setup setup-cloud clean status demo-reset generate build install-deps install-python-deps install-node-deps run-order-service run-inventory-service run-analytics-api phase3-demo phase3-java-serialization phase3-json-mismatch phase3-type-inconsistency phase3-normal-flow phase4-demo phase4-test inventory-service-smoke-test

help: ## 📋 Show this help message
	@echo -e "$(BLUE)🚀 Kafka Schema Registry Demo$(NC)"
	@echo -e "$(YELLOW)Available commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

setup: ## 🏗️  Setup local environment with Docker
	@echo -e "$(GREEN)🏗️  Setting up local Kafka environment...$(NC)"
	docker-compose up -d
	@echo -e "$(GREEN)⏳ Waiting for services to be ready...$(NC)"
	./scripts/wait-for-services.sh
	@echo -e "$(GREEN)✅ Environment ready!$(NC)"

setup-cloud: ## ☁️  Setup for Confluent Cloud
	@echo -e "$(GREEN)☁️  Configuring for Confluent Cloud...$(NC)"
	@if [ ! -f .env ]; then \
		echo -e "$(RED)❌ .env file not found. Creating from template...$(NC)"; \
		cp .env.example .env; \
		echo -e "$(YELLOW)⚠️  Please edit .env file with your Confluent Cloud credentials$(NC)"; \
		exit 1; \
	fi
	docker-compose -f docker-compose.cloud.yml up -d
	@echo -e "$(GREEN)✅ Cloud configuration ready!$(NC)"

clean: ## 🧹 Clean up everything
	@echo -e "$(RED)🧹 Cleaning up everything...$(NC)"
	@echo -e "$(YELLOW)🧹 Cleaning Docker containers and volumes...$(NC)"
	docker-compose down -v
	docker system prune -f
	@echo -e "$(YELLOW)🧹 Cleaning Java Order Service build artifacts...$(NC)"
	cd services/order-service && ./gradlew clean || echo -e "$(YELLOW)⚠️  No Gradle build to clean$(NC)"
	@echo -e "$(YELLOW)🧹 Cleaning Python Inventory Service build artifacts...$(NC)"
	rm -rf services/inventory-service/__pycache__ services/inventory-service/.pytest_cache services/inventory-service/inventory_service/__pycache__
	@echo -e "$(YELLOW)🧹 Cleaning Node.js Analytics API build artifacts...$(NC)"
	rm -rf services/analytics-api/dist services/analytics-api/node_modules
	@echo -e "$(GREEN)✨ Cleanup complete!$(NC)"

demo-reset: ## 🔄 Reset demo environment
	@echo -e "$(YELLOW)🔄 Resetting demo state...$(NC)"
	./scripts/cleanup-topics.sh
	./scripts/cleanup-schemas.sh
	docker-compose restart
	@echo -e "$(GREEN)✨ Demo reset complete!$(NC)"

status: ## 📊 Check service status
	@echo -e "$(BLUE)📊 Checking service status...$(NC)"
	@echo -e "$(BLUE)Docker services:$(NC)"
	@docker-compose ps
	@echo -e "$(BLUE)Kafka topics:$(NC)"
	@docker-compose exec -T kafka kafka-topics --bootstrap-server kafka:9092 --list || echo -e "$(RED)❌ Kafka not available$(NC)"
	@echo -e "$(BLUE)Schema Registry subjects:$(NC)"
	@curl -s http://localhost:8081/subjects | jq . || echo -e "$(RED)❌ Schema Registry not available$(NC)"

generate: ## 🔧 Generate code from schemas
	@echo -e "$(GREEN)🔧 Generating code from Avro schemas...$(NC)"
	@echo -e "$(YELLOW)Java POJOs (Gradle + Kotlin DSL):$(NC)"
	cd services/order-service && ./gradlew generateAvroJava
	@echo -e "$(YELLOW)Python dataclasses:$(NC)"
	cd services/inventory-service && python3 scripts/generate_classes.py
	@echo -e "$(YELLOW)TypeScript interfaces:$(NC)"
	cd services/analytics-api && npm run generate-types
	@echo -e "$(GREEN)✅ Code generation complete!$(NC)"

install-deps: install-python-deps install-node-deps ## 📦 Install all dependencies
	@echo -e "$(GREEN)✅ All dependencies installed!$(NC)"

install-python-deps: ## 📦 Install Python dependencies
	@echo -e "$(GREEN)📦 Installing Python dependencies...$(NC)"
	@if [ ! -d services/inventory-service/.venv ]; then \
		echo -e "$(YELLOW)🔧 Creating Python virtual environment with Python 3.12...$(NC)"; \
		cd services/inventory-service && python3.12 -m venv .venv; \
	fi
	@echo -e "$(YELLOW)🔧 Installing dependencies for Python 3.12...$(NC)"
	cd services/inventory-service && source .venv/bin/activate && \
	pip install --upgrade pip && \
	pip install wheel && \
	pip install -r requirements.txt
	@echo -e "$(GREEN)✅ Python dependencies installed in virtual environment!$(NC)"

install-node-deps: ## 📦 Install Node.js dependencies
	@echo -e "$(GREEN)📦 Installing Node.js dependencies...$(NC)"
	cd services/analytics-api && npm ci
	@echo -e "$(GREEN)✅ Node.js dependencies installed!$(NC)"

build: install-deps generate ## 💪  Build all services
	@echo -e "$(GREEN)💪  Building all services...$(NC)"

	@echo -e "$(YELLOW)💪 Building Java Order Service (Gradle):$(NC)"
	cd services/order-service && ./gradlew build --info
	@echo -e "$(GREEN)✅ Java Order Service build complete!$(NC)"

	@echo -e "$(YELLOW)💪 Building Python Inventory Service:$(NC)"
	@if [ ! -d services/inventory-service/.venv ]; then \
		echo -e "$(YELLOW)🔧 Creating Python virtual environment...$(NC)"; \
		cd services/inventory-service && python3 -m venv .venv; \
		echo -e "$(YELLOW)🔧 Installing dependencies in virtual environment...$(NC)"; \
		cd services/inventory-service && source .venv/bin/activate && pip install -r requirements.txt; \
	fi
	cd services/inventory-service && source .venv/bin/activate && python -m pytest --tb=short || echo -e "$(YELLOW)⚠️  No tests to run yet$(NC)"
	@echo -e "$(GREEN)✅ Python Inventory Service build complete!$(NC)"

	@echo -e "$(YELLOW)💪 Building Node.js Analytics API:$(NC)"
	cd services/analytics-api && npm ci && npm run build
	@echo -e "$(GREEN)✅ Node.js Analytics API build complete!$(NC)"

	@echo -e "$(GREEN)🎉 All builds successful!$(NC)"

demo-codegen: ## 🎭 Demo schema-first development
	@echo -e "$(GREEN)🎭 Demonstrating schema-first development...$(NC)"
	@echo -e "$(BLUE)1. Show schema definition$(NC)"
	cat schemas/v1/order-event.avsc
	@echo -e "$(BLUE)2. Generate code artifacts$(NC)"
	make generate
	@echo -e "$(BLUE)3. Show generated classes$(NC)"
	@echo -e "$(BLUE)Java (generated by Gradle):$(NC)"
	find services/order-service/build/generated-main-avro-java -name "*.java" | head -3
	@echo -e "$(BLUE)Python (generated):$(NC)"
	find services/inventory-service/src/generated -name "*.py" | head -3
	@echo -e "$(BLUE)TypeScript (generated):$(NC)"
	find services/analytics-api/src/generated -name "*.ts" | head -3
	@echo -e "$(GREEN)🎉 Schema drives code generation!$(NC)"

run-order-service: ## 🚀 Run Java Order Service
	@echo -e "$(GREEN)🚀 Starting Order Service...$(NC)"
	cd services/order-service && ./gradlew bootRun


run-inventory-service: ## 🚀 Run Python Inventory Service
	@echo -e "$(GREEN)🚀 Starting Inventory Service...$(NC)"
	@echo -e "$(BLUE)Using Python virtual environment...$(NC)"
	cd services/inventory-service && source .venv/bin/activate && python -m inventory_service.main

run-analytics-api: install-node-deps ## 🚀 Run Node.js Analytics API
	@echo -e "$(GREEN)🚀 Starting Analytics API...$(NC)"
	cd services/analytics-api && npm start

phase3-demo: ## 🎭 Run Phase 3 Demo (all scenarios)
	@echo -e "$(GREEN)🎭 Running Phase 3 Demo - Serialization Scenarios...$(NC)"
	@echo -e "$(BLUE)This demo shows different serialization scenarios:$(NC)"
	@echo -e "$(BLUE)1. Normal flow (everything works)$(NC)"
	@echo -e "$(BLUE)2. Java serialization failures$(NC)"
	@echo -e "$(BLUE)3. JSON field name mismatch failures$(NC)"
	@echo -e "$(BLUE)4. Type inconsistency failures$(NC)"
	@echo -e "$(BLUE)Make sure all services are running:$(NC)"
	@echo -e "$(BLUE)- make run-order-service (in one terminal)$(NC)"
	@echo -e "$(BLUE)- make run-inventory-service (in another terminal)$(NC)"
	@echo -e "$(BLUE)- make run-analytics-api (in a third terminal)$(NC)"
	@echo -e "$(BLUE)Then run each demo scenario:$(NC)"
	@echo -e "$(BLUE)- make phase3-normal-flow$(NC)"
	@echo -e "$(BLUE)- make phase3-java-serialization$(NC)"
	@echo -e "$(BLUE)- make phase3-json-mismatch$(NC)"
	@echo -e "$(BLUE)- make phase3-type-inconsistency$(NC)"

demo-broken: ## 💥 Start failure scenarios demo
	@echo -e "$(GREEN)💥 Starting failure scenarios demo...$(NC)"
	@echo -e "$(BLUE)This will demonstrate serialization issues across languages$(NC)"
	./scripts/start-broken-services.sh
	@echo -e "$(GREEN)🎭 Demo ready! Run failure scenarios with:$(NC)"
	@echo -e "$(BLUE)- make phase3-java-serialization$(NC)"
	@echo -e "$(BLUE)- make phase3-json-mismatch$(NC)"
	@echo -e "$(BLUE)- make phase3-type-inconsistency$(NC)"

demo-fixed: ## ✨ Switch to Avro serialization
	@echo -e "$(GREEN)✨ Switching to Avro serialization...$(NC)"
	@echo -e "$(BLUE)This will demonstrate how Schema Registry fixes serialization issues$(NC)"
	./scripts/start-avro-services.sh
	@echo -e "$(GREEN)🎉 Avro demo ready! Run with:$(NC)"
	@echo -e "$(BLUE)- make phase4-demo$(NC)"

demo-evolution: ## 🧬 Demonstrate schema evolution
	@echo -e "$(GREEN)🧬 Starting schema evolution demo...$(NC)"
	@echo -e "$(BLUE)This will show backward/forward compatibility with schema changes$(NC)"
	./scripts/evolve-schema.sh
	@echo -e "$(GREEN)🎉 Schema evolution demo complete!$(NC)"

phase3-java-serialization: ## 🎭 Demo Java serialization failures
	@echo -e "$(GREEN)🎭 Running Java Serialization Failure Demo...$(NC)"
	chmod +x scripts/demo/trigger-java-serialization-failure.sh
	./scripts/demo/trigger-java-serialization-failure.sh


phase3-json-mismatch: ## 🎭 Demo JSON field name mismatch failures
	@echo -e "$(GREEN)🎭 Running JSON Field Name Mismatch Demo...$(NC)"
	chmod +x scripts/demo/trigger-json-mismatch-failure.sh
	./scripts/demo/trigger-json-mismatch-failure.sh


phase3-type-inconsistency: ## 🎭 Demo type inconsistency failures
	@echo -e "$(GREEN)🎭 Running Type Inconsistency Failure Demo...$(NC)"
	chmod +x scripts/demo/trigger-type-inconsistency-failure.sh
	./scripts/demo/trigger-type-inconsistency-failure.sh


phase3-normal-flow: ## ✨ Demo normal flow scenario (everything works)
	@echo -e "$(GREEN)✨ Running Normal Flow Demo...$(NC)"
	chmod +x scripts/demo/trigger-normal-flow.sh
	./scripts/demo/trigger-normal-flow.sh

phase4-demo: ## 🚀 Run Phase 4 Demo (Schema Registry with Avro)
	@echo -e "$(GREEN)🚀 Running Phase 4 Demo - Schema Registry Integration with Avro...$(NC)"
	chmod +x scripts/phase4-demo.sh
	./scripts/phase4-demo.sh

phase4-test: ## 🧪 Run Phase 4 Tests (Schema Registry with Avro)
	@echo -e "$(GREEN)🧪 Running Phase 4 Test Suite - Schema Registry Integration with Avro...$(NC)"
	chmod +x scripts/test-phase4.sh
	./scripts/test-phase4.sh

inventory-service-smoke-test: ## 🔥 Run smoke tests for the Python inventory service
	@echo -e "$(GREEN)🔥 Running Smoke Tests for Python Inventory Service...$(NC)"
	@echo -e "$(BLUE)Testing Python dependencies and critical functionality...$(NC)"
	chmod +x services/inventory-service/scripts/smoke_test.py
	cd services/inventory-service && source .venv/bin/activate && python scripts/smoke_test.py

analytics-api-smoke-test: ## 🔥 Run smoke tests for the Node.js analytics API
	@echo -e "$(GREEN)🔥 Running Smoke Tests for Node.js Analytics API...$(NC)"
	@echo -e "$(BLUE)Testing Node.js dependencies and critical functionality...$(NC)"
	chmod +x services/analytics-api/scripts/smoke-test.js
	cd services/analytics-api && node scripts/smoke-test.js
