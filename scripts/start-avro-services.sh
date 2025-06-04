#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}✨ Starting services in Avro mode for fixed demos...${NC}"

# Stop any running services first
echo -e "${YELLOW}🛑 Stopping any existing services...${NC}"
./scripts/stop-broken-services.sh

# Start Docker infrastructure
echo -e "${YELLOW}🏗️  Starting Docker infrastructure...${NC}"
docker-compose up -d

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for Kafka and Schema Registry to be ready...${NC}"
./scripts/wait-for-services.sh

# Register schemas
echo -e "${YELLOW}📋 Registering Avro schemas...${NC}"
./scripts/register-schemas.sh

# Generate code from schemas
echo -e "${YELLOW}🔧 Generating code from schemas...${NC}"
make generate

# Build services with Avro support
echo -e "${YELLOW}💪 Building services with Avro support...${NC}"
make build

# Start services in Avro mode
echo -e "${YELLOW}🚀 Starting Order Service (Java) with Avro serialization...${NC}"
cd services/order-service
./gradlew bootRun > ../logs/order-service-avro.log 2>&1 &
ORDER_PID=$!
echo $ORDER_PID > ../logs/order-service-avro.pid
cd ../..

echo -e "${YELLOW}🚀 Starting Inventory Service (Python) with Avro deserialization...${NC}"
cd services/inventory-service
# Activate virtual environment and start the service
source .venv/bin/activate && python -m inventory_service.main > ../logs/inventory-service-avro.log 2>&1 &
INVENTORY_PID=$!
echo $INVENTORY_PID > ../logs/inventory-service-avro.pid
cd ../..

echo -e "${YELLOW}🚀 Starting Analytics API (Node.js) with Avro support...${NC}"
cd services/analytics-api
npm start > ../logs/analytics-api-avro.log 2>&1 &
ANALYTICS_PID=$!
echo $ANALYTICS_PID > ../logs/analytics-api-avro.pid
cd ../..

# Create logs directory if it doesn't exist
mkdir -p services/logs

# Wait for services to start
echo -e "${YELLOW}⏳ Waiting for services to start...${NC}"
sleep 15

# Check if services are running
echo -e "${YELLOW}📊 Checking service health...${NC}"
if curl -s http://localhost:9080/health > /dev/null; then
    echo -e "${GREEN}✅ Order Service is running with Avro${NC}"
else
    echo -e "${RED}❌ Order Service failed to start${NC}"
fi

if curl -s http://localhost:9000/health > /dev/null; then
    echo -e "${GREEN}✅ Inventory Service is running with Avro${NC}"
else
    echo -e "${RED}❌ Inventory Service failed to start${NC}"
fi

if curl -s http://localhost:9300/health > /dev/null; then
    echo -e "${GREEN}✅ Analytics API is running with Avro${NC}"
else
    echo -e "${RED}❌ Analytics API failed to start${NC}"
fi

echo -e "${GREEN}🎉 Services started in Avro mode!${NC}"
echo -e "${YELLOW}Ready for Avro demos:${NC}"
echo -e "${GREEN}- make phase4-demo${NC}"
echo -e "${GREEN}- make phase4-test${NC}"
echo -e "${YELLOW}Analytics Dashboard: http://localhost:9300/analytics/dashboard${NC}"
echo -e "${YELLOW}To view logs: tail -f services/logs/*-avro.log${NC}"
echo -e "${YELLOW}To stop services: make demo-reset${NC}"
