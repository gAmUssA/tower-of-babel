#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}💥 Starting services in broken mode for failure demos...${NC}"

# Stop any running services first
echo -e "${YELLOW}🛑 Stopping any existing services...${NC}"
./scripts/stop-broken-services.sh

# Start Docker infrastructure
echo -e "${YELLOW}🏗️  Starting Docker infrastructure...${NC}"
docker-compose up -d

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for Kafka and Schema Registry to be ready...${NC}"
./scripts/wait-for-services.sh

# Start services in broken mode (using different serialization formats)
echo -e "${YELLOW}🚀 Starting Order Service (Java) with multiple serialization endpoints...${NC}"
cd services/order-service
./gradlew bootRun > ../logs/order-service.log 2>&1 &
ORDER_PID=$!
echo $ORDER_PID > ../logs/order-service.pid
cd ../..

echo -e "${YELLOW}🚀 Starting Inventory Service (Python) for JSON/Java deserialization...${NC}"
cd services/inventory-service
# Activate virtual environment and start the service
source .venv/bin/activate && python -m inventory_service.main > ../logs/inventory-service.log 2>&1 &
INVENTORY_PID=$!
echo $INVENTORY_PID > ../logs/inventory-service.pid
cd ../..

echo -e "${YELLOW}🚀 Starting Analytics API (Node.js) for cross-language consumption...${NC}"
cd services/analytics-api
npm start > ../logs/analytics-api.log 2>&1 &
ANALYTICS_PID=$!
echo $ANALYTICS_PID > ../logs/analytics-api.pid
cd ../..

# Create logs directory if it doesn't exist
mkdir -p services/logs

# Wait for services to start
echo -e "${YELLOW}⏳ Waiting for services to start...${NC}"
sleep 10

# Check if services are running
echo -e "${YELLOW}📊 Checking service health...${NC}"
if curl -s http://localhost:9080/health > /dev/null; then
    echo -e "${GREEN}✅ Order Service is running${NC}"
else
    echo -e "${RED}❌ Order Service failed to start${NC}"
fi

if curl -s http://localhost:9000/health > /dev/null; then
    echo -e "${GREEN}✅ Inventory Service is running${NC}"
else
    echo -e "${RED}❌ Inventory Service failed to start${NC}"
fi

if curl -s http://localhost:9300/health > /dev/null; then
    echo -e "${GREEN}✅ Analytics API is running${NC}"
else
    echo -e "${RED}❌ Analytics API failed to start${NC}"
fi

echo -e "${GREEN}🎭 Services started in broken mode!${NC}"
echo -e "${YELLOW}Ready for failure scenario demos:${NC}"
echo -e "${GREEN}- make phase3-java-serialization${NC}"
echo -e "${GREEN}- make phase3-json-mismatch${NC}"
echo -e "${GREEN}- make phase3-type-inconsistency${NC}"
echo -e "${YELLOW}To view logs: tail -f services/logs/*.log${NC}"
echo -e "${YELLOW}To stop services: make demo-reset${NC}"
