# Tower of Babel Demo Makefile
# Kafka Schema Registry Demo with emoji and colors for better readability

# Colors
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

.PHONY: help setup setup-cloud clean status demo-reset

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
	docker-compose down -v
	docker system prune -f
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
