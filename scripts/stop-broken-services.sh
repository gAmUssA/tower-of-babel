#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🛑 Stopping all demo services...${NC}"

# Create logs directory if it doesn't exist
mkdir -p services/logs

# Stop services using PID files
if [ -f services/logs/order-service.pid ]; then
    ORDER_PID=$(cat services/logs/order-service.pid)
    if ps -p $ORDER_PID > /dev/null 2>&1; then
        echo -e "${YELLOW}🛑 Stopping Order Service (PID: $ORDER_PID)...${NC}"
        kill $ORDER_PID
        rm services/logs/order-service.pid
    fi
fi

if [ -f services/logs/order-service-avro.pid ]; then
    ORDER_AVRO_PID=$(cat services/logs/order-service-avro.pid)
    if ps -p $ORDER_AVRO_PID > /dev/null 2>&1; then
        echo -e "${YELLOW}🛑 Stopping Order Service Avro (PID: $ORDER_AVRO_PID)...${NC}"
        kill $ORDER_AVRO_PID
        rm services/logs/order-service-avro.pid
    fi
fi

if [ -f services/logs/inventory-service.pid ]; then
    INVENTORY_PID=$(cat services/logs/inventory-service.pid)
    if ps -p $INVENTORY_PID > /dev/null 2>&1; then
        echo -e "${YELLOW}🛑 Stopping Inventory Service (PID: $INVENTORY_PID)...${NC}"
        kill $INVENTORY_PID
        rm services/logs/inventory-service.pid
    fi
fi

if [ -f services/logs/inventory-service-avro.pid ]; then
    INVENTORY_AVRO_PID=$(cat services/logs/inventory-service-avro.pid)
    if ps -p $INVENTORY_AVRO_PID > /dev/null 2>&1; then
        echo -e "${YELLOW}🛑 Stopping Inventory Service Avro (PID: $INVENTORY_AVRO_PID)...${NC}"
        kill $INVENTORY_AVRO_PID
        rm services/logs/inventory-service-avro.pid
    fi
fi

if [ -f services/logs/analytics-api.pid ]; then
    ANALYTICS_PID=$(cat services/logs/analytics-api.pid)
    if ps -p $ANALYTICS_PID > /dev/null 2>&1; then
        echo -e "${YELLOW}🛑 Stopping Analytics API (PID: $ANALYTICS_PID)...${NC}"
        kill $ANALYTICS_PID
        rm services/logs/analytics-api.pid
    fi
fi

if [ -f services/logs/analytics-api-avro.pid ]; then
    ANALYTICS_AVRO_PID=$(cat services/logs/analytics-api-avro.pid)
    if ps -p $ANALYTICS_AVRO_PID > /dev/null 2>&1; then
        echo -e "${YELLOW}🛑 Stopping Analytics API Avro (PID: $ANALYTICS_AVRO_PID)...${NC}"
        kill $ANALYTICS_AVRO_PID
        rm services/logs/analytics-api-avro.pid
    fi
fi

# Also stop any remaining processes on the known ports
echo -e "${YELLOW}🛑 Checking for any remaining services on known ports...${NC}"

# Check and kill processes on port 9080 (Order Service)
ORDER_PORT_PID=$(lsof -ti:9080)
if [ ! -z "$ORDER_PORT_PID" ]; then
    echo -e "${YELLOW}🛑 Stopping process on port 9080 (PID: $ORDER_PORT_PID)...${NC}"
    kill $ORDER_PORT_PID
fi

# Check and kill processes on port 9000 (Inventory Service)
INVENTORY_PORT_PID=$(lsof -ti:9000)
if [ ! -z "$INVENTORY_PORT_PID" ]; then
    echo -e "${YELLOW}🛑 Stopping process on port 9000 (PID: $INVENTORY_PORT_PID)...${NC}"
    kill $INVENTORY_PORT_PID
fi

# Check and kill processes on port 9300 (Analytics API)
ANALYTICS_PORT_PID=$(lsof -ti:9300)
if [ ! -z "$ANALYTICS_PORT_PID" ]; then
    echo -e "${YELLOW}🛑 Stopping process on port 9300 (PID: $ANALYTICS_PORT_PID)...${NC}"
    kill $ANALYTICS_PORT_PID
fi

# Wait a moment for graceful shutdown
sleep 2

echo -e "${GREEN}✅ All demo services stopped!${NC}"
