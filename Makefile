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

.PHONY: help demo-ready demo-workflow setup setup-cloud clean status demo-reset generate build install-deps install-python-deps install-node-deps run-order-service run-inventory-service run-analytics-api \
	demo-1 demo-1-tower-of-babel demo-1-java demo-1-json demo-1-type \
	demo-2 demo-2-babel-fish demo-2-comprehensive \
	demo-3 demo-3-safe-evolution \
	demo-4 demo-4-breaking-change-blocked \
	demo-all demo-broken demo-fixed demo-evolution \
	test-1 test-1-serialization-failures \
	test-2 test-2-avro-integration \
	test-3 test-3-schema-evolution \
	test-4 test-4-compatibility-checks \
	test-all \
	phase3-demo phase3-java-serialization phase3-json-mismatch phase3-type-inconsistency phase3-normal-flow phase4-demo phase4-test \
	inventory-service-smoke-test analytics-api-smoke-test

help: ## 📋 Show this help message
	@echo -e "$(BLUE)🚀 Kafka Schema Registry Demo$(NC)"
	@echo -e "$(YELLOW)Available commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

setup: ## 🏗️  Setup local environment with Docker
	@echo -e "$(GREEN)🏗️  Setting up local Kafka environment...$(NC)"
	docker-compose up -d
	@echo -e "$(GREEN)⏳ Waiting for services to be ready...$(NC)"
	./scripts/utils/wait-for-services.sh
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
	./scripts/utils/cleanup-topics.sh
	./scripts/utils/cleanup-schemas.sh
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
	cd services/inventory-service && uv run python scripts/generate_classes.py
	@echo -e "$(YELLOW)TypeScript interfaces:$(NC)"
	cd services/analytics-api && npm run generate-types
	@echo -e "$(GREEN)✅ Code generation complete!$(NC)"

install-deps: install-python-deps install-node-deps ## 📦 Install all dependencies
	@echo -e "$(GREEN)✅ All dependencies installed!$(NC)"

install-python-deps: ## 📦 Install Python dependencies
	@echo -e "$(GREEN)📦 Installing Python dependencies...$(NC)"
	cd services/inventory-service && uv sync --extra dev
	@echo -e "$(GREEN)✅ Python dependencies installed!$(NC)"

install-node-deps: ## 📦 Install Node.js dependencies
	@echo -e "$(GREEN)📦 Installing Node.js dependencies...$(NC)"
	source "$$HOME/.nvm/nvm.sh" 2>/dev/null; nvm use 22 --silent 2>/dev/null || true; \
	cd services/analytics-api && npm install
	@echo -e "$(GREEN)✅ Node.js dependencies installed!$(NC)"

build: install-deps generate ## 💪  Build all services
	@echo -e "$(GREEN)💪  Building all services...$(NC)"

	@echo -e "$(YELLOW)💪 Building Java Order Service (Gradle):$(NC)"
	cd services/order-service && ./gradlew build --info
	@echo -e "$(GREEN)✅ Java Order Service build complete!$(NC)"

	@echo -e "$(YELLOW)💪 Building Python Inventory Service:$(NC)"
	cd services/inventory-service && uv run python -m pytest --tb=short || echo -e "$(YELLOW)⚠️  No tests to run yet$(NC)"
	@echo -e "$(GREEN)✅ Python Inventory Service build complete!$(NC)"

	@echo -e "$(YELLOW)💪 Building Node.js Analytics API:$(NC)"
	source "$$HOME/.nvm/nvm.sh" 2>/dev/null; nvm use 22 --silent 2>/dev/null || true; \
	cd services/analytics-api && npm install && npm run build
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
	cd services/inventory-service && uv run python -m inventory_service.main

run-analytics-api: install-node-deps ## 🚀 Run Node.js Analytics API
	@echo -e "$(GREEN)🚀 Starting Analytics API...$(NC)"
	source "$$HOME/.nvm/nvm.sh" 2>/dev/null; nvm use 22 --silent 2>/dev/null || true; \
	cd services/analytics-api && npm run dev

phase3-demo: ## 🎭 [DEPRECATED] Run Phase 3 Demo - Use demo-1 instead
	@echo -e "$(YELLOW)⚠️  This target is deprecated. Use 'make demo-1' instead.$(NC)"
	@echo -e "$(GREEN)🎭 Running Demo 1: Tower of Babel...$(NC)"
	@echo -e "$(BLUE)This demo shows different serialization scenarios:$(NC)"
	@echo -e "$(BLUE)1. Java serialization failures$(NC)"
	@echo -e "$(BLUE)2. JSON field name mismatch failures$(NC)"
	@echo -e "$(BLUE)3. Type inconsistency failures$(NC)"
	@echo -e "$(BLUE)Make sure all services are running:$(NC)"
	@echo -e "$(BLUE)- make run-order-service (in one terminal)$(NC)"
	@echo -e "$(BLUE)- make run-inventory-service (in another terminal)$(NC)"
	@echo -e "$(BLUE)- make run-analytics-api (in a third terminal)$(NC)"
	@echo -e "$(BLUE)New commands:$(NC)"
	@echo -e "$(BLUE)- make demo-1          # Run all chaos scenarios$(NC)"
	@echo -e "$(BLUE)- make demo-1-java     # Java serialization only$(NC)"
	@echo -e "$(BLUE)- make demo-1-json     # JSON mismatch only$(NC)"
	@echo -e "$(BLUE)- make demo-1-type     # Type inconsistency only$(NC)"

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
	./scripts/utils/evolve-schema.sh
	@echo -e "$(GREEN)🎉 Schema evolution demo complete!$(NC)"

# ============================================================================
# Demo Scripts - New Naming Convention
# ============================================================================

demo-1: demo-1-tower-of-babel ## 🗼 Run Demo 1: Tower of Babel (all chaos scenarios)

demo-1-tower-of-babel: ## 🗼 Demo 1: Tower of Babel - Serialization Chaos
	@echo -e "$(GREEN)🗼 Running Demo 1: Tower of Babel - Serialization Chaos...$(NC)"
	./scripts/demo/demo-1-tower-of-babel.sh

demo-1-java: ## 🗼 Demo 1a: Java serialization failure only
	@echo -e "$(GREEN)🗼 Running Demo 1a: Java Serialization Failure...$(NC)"
	./scripts/demo/demo-1-tower-of-babel.sh java

demo-1-json: ## 🗼 Demo 1b: JSON field mismatch only
	@echo -e "$(GREEN)🗼 Running Demo 1b: JSON Field Mismatch...$(NC)"
	./scripts/demo/demo-1-tower-of-babel.sh json

demo-1-type: ## 🗼 Demo 1c: Type inconsistency only
	@echo -e "$(GREEN)🗼 Running Demo 1c: Type Inconsistency...$(NC)"
	./scripts/demo/demo-1-tower-of-babel.sh type

demo-2: demo-2-babel-fish ## 🐟 Run Demo 2: Babel Fish (Avro solution)

demo-2-babel-fish: ## 🐟 Demo 2: Babel Fish - Schema Registry Solution
	@echo -e "$(GREEN)🐟 Running Demo 2: Babel Fish - Schema Registry Solution...$(NC)"
	./scripts/demo/demo-2-babel-fish.sh

demo-2-comprehensive: ## 🐟 Demo 2: Babel Fish - Comprehensive Test
	@echo -e "$(GREEN)🐟 Running Demo 2: Babel Fish - Comprehensive...$(NC)"
	./scripts/demo/demo-2-babel-fish-comprehensive.sh

demo-3: demo-3-safe-evolution ## 🔄 Run Demo 3: Safe Evolution

demo-3-safe-evolution: ## 🔄 Demo 3: Safe Evolution - Schema Compatibility
	@echo -e "$(GREEN)🔄 Running Demo 3: Safe Evolution - Schema Compatibility...$(NC)"
	./scripts/demo/demo-3-safe-evolution.sh

demo-4: demo-4-breaking-change-blocked ## 🛡️  Run Demo 4: Prevented Disasters

demo-4-breaking-change-blocked: ## 🛡️  Demo 4: Prevented Disasters - Breaking Changes Blocked
	@echo -e "$(GREEN)🛡️  Running Demo 4: Prevented Disasters - Breaking Changes Blocked...$(NC)"
	./scripts/demo/demo-4-breaking-change-blocked.sh

demo-all: ## 🎭 Run all demos in sequence
	@echo -e "$(GREEN)🎭 Running all demos in sequence...$(NC)"
	@echo -e "$(BLUE)Demo 1: Tower of Babel$(NC)"
	./scripts/demo/demo-1-tower-of-babel.sh
	@echo -e "$(BLUE)Demo 2: Babel Fish$(NC)"
	./scripts/demo/demo-2-babel-fish.sh
	@echo -e "$(BLUE)Demo 3: Safe Evolution$(NC)"
	./scripts/demo/demo-3-safe-evolution.sh
	@echo -e "$(BLUE)Demo 4: Prevented Disasters$(NC)"
	./scripts/demo/demo-4-breaking-change-blocked.sh
	@echo -e "$(GREEN)🎉 All demos complete!$(NC)"

# ============================================================================
# Test Scripts - New Naming Convention
# ============================================================================

test-1: test-1-serialization-failures ## 🧪 Run Test 1: Serialization Failures

test-1-serialization-failures: ## 🧪 Test 1: Serialization Failures
	@echo -e "$(GREEN)🧪 Running Test 1: Serialization Failures...$(NC)"
	./scripts/test/test-1-serialization-failures.sh

test-2: test-2-avro-integration ## 🧪 Run Test 2: Avro Integration

test-2-avro-integration: ## 🧪 Test 2: Avro Integration
	@echo -e "$(GREEN)🧪 Running Test 2: Avro Integration...$(NC)"
	./scripts/test/test-2-avro-integration.sh

test-3: test-3-schema-evolution ## 🧪 Run Test 3: Schema Evolution

test-3-schema-evolution: ## 🧪 Test 3: Schema Evolution
	@echo -e "$(GREEN)🧪 Running Test 3: Schema Evolution...$(NC)"
	./scripts/test/test-3-schema-evolution.sh

test-4: test-4-compatibility-checks ## 🧪 Run Test 4: Compatibility Checks

test-4-compatibility-checks: ## 🧪 Test 4: Compatibility Checks
	@echo -e "$(GREEN)🧪 Running Test 4: Compatibility Checks...$(NC)"
	./scripts/test/test-4-compatibility-checks.sh

test-all: ## 🧪 Run all tests
	@echo -e "$(GREEN)🧪 Running all tests...$(NC)"
	@PASSED=0; FAILED=0; \
	for test in ./scripts/test/test-*.sh; do \
		echo -e "$(BLUE)Running $$test...$(NC)"; \
		if $$test; then \
			PASSED=$$((PASSED + 1)); \
		else \
			FAILED=$$((FAILED + 1)); \
		fi; \
		echo ""; \
	done; \
	echo -e "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"; \
	echo -e "$(BLUE)Test Results:$(NC)"; \
	echo -e "$(GREEN)Passed: $$PASSED$(NC)"; \
	if [ $$FAILED -gt 0 ]; then \
		echo -e "$(RED)Failed: $$FAILED$(NC)"; \
		exit 1; \
	else \
		echo -e "$(GREEN)Failed: 0$(NC)"; \
		echo -e "$(GREEN)🎉 All tests passed!$(NC)"; \
	fi

# ============================================================================
# Legacy Demo Targets (Deprecated - use demo-1, demo-2, etc.)
# ============================================================================

phase3-java-serialization: demo-1-java ## 🎭 [DEPRECATED] Use demo-1-java instead

phase3-json-mismatch: demo-1-json ## 🎭 [DEPRECATED] Use demo-1-json instead

phase3-type-inconsistency: demo-1-type ## 🎭 [DEPRECATED] Use demo-1-type instead

phase3-normal-flow: demo-2-babel-fish ## ✨ [DEPRECATED] Use demo-2-babel-fish instead

phase4-demo: demo-2-comprehensive ## 🚀 [DEPRECATED] Use demo-2-comprehensive instead

phase4-test: test-2-avro-integration ## 🧪 [DEPRECATED] Use test-2-avro-integration instead

inventory-service-smoke-test: ## 🔥 Run smoke tests for the Python inventory service
	@echo -e "$(GREEN)🔥 Running Smoke Tests for Python Inventory Service...$(NC)"
	@echo -e "$(BLUE)Testing Python dependencies and critical functionality...$(NC)"
	cd services/inventory-service && uv run python scripts/smoke_test.py

analytics-api-smoke-test: ## 🔥 Run smoke tests for the Node.js analytics API
	@echo -e "$(GREEN)🔥 Running Smoke Tests for Node.js Analytics API...$(NC)"
	@echo -e "$(BLUE)Testing Node.js dependencies and critical functionality...$(NC)"
	chmod +x services/analytics-api/scripts/smoke-test.js
	cd services/analytics-api && node scripts/smoke-test.js

demo-ready: ## 🖥️  Launch tmux session with all 3 services + scenario window
	@./scripts/demo-ready.sh

demo-workflow: ## 📖 Show recommended demo workflow
	@echo -e "$(BLUE)📖 Recommended Demo Workflow$(NC)"
	@echo -e "$(CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo -e "$(YELLOW)1. Setup Infrastructure:$(NC)"
	@echo -e "   $(GREEN)make setup$(NC)                    # Start Kafka + Schema Registry"
	@echo -e ""
	@echo -e "$(YELLOW)2. Start Services (in separate terminals):$(NC)"
	@echo -e "   $(GREEN)make run-order-service$(NC)        # Terminal 1: Java/Spring Boot"
	@echo -e "   $(GREEN)make run-inventory-service$(NC)    # Terminal 2: Python/FastAPI"
	@echo -e "   $(GREEN)make run-analytics-api$(NC)        # Terminal 3: Node.js/Express"
	@echo -e ""
	@echo -e "$(YELLOW)3. Run Demos (in order):$(NC)"
	@echo -e "   $(GREEN)make demo-1$(NC)                   # Tower of Babel (chaos)"
	@echo -e "   $(GREEN)make demo-2$(NC)                   # Babel Fish (solution)"
	@echo -e "   $(GREEN)make demo-3$(NC)                   # Safe Evolution"
	@echo -e "   $(GREEN)make demo-4$(NC)                   # Prevented Disasters"
	@echo -e ""
	@echo -e "$(YELLOW)4. Run Tests (optional):$(NC)"
	@echo -e "   $(GREEN)make test-all$(NC)                 # Run all automated tests"
	@echo -e ""
	@echo -e "$(YELLOW)5. Quick Commands:$(NC)"
	@echo -e "   $(GREEN)make demo-all$(NC)                 # Run all demos in sequence"
	@echo -e "   $(GREEN)make status$(NC)                   # Check service status"
	@echo -e "   $(GREEN)make demo-reset$(NC)               # Reset demo environment"
	@echo -e "$(CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
