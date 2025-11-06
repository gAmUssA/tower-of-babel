#!/bin/bash

# Script to demonstrate normal flow scenario
# This shows that all services can communicate properly using Avro serialization

# Set colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Triggering Normal Flow Demo${NC}"
echo -e "${YELLOW}📋 This demo shows the correct flow when Avro serialization is used${NC}"
echo

# Check if services are running
echo -e "${BLUE}🔍 Checking if services are running...${NC}"

# Check Order Service
ORDER_SERVICE_HEALTH=$(curl -s http://localhost:9080/actuator/health | grep -o '"status":"UP"' || echo "DOWN")
if [[ $ORDER_SERVICE_HEALTH == *"UP"* ]]; then
  echo -e "${GREEN}✅ Order Service is running${NC}"
else
  echo -e "${RED}❌ Order Service is not running. Please start it first.${NC}"
  exit 1
fi

# Check Inventory Service
INVENTORY_SERVICE_HEALTH=$(curl -s http://localhost:9000/health | grep -o '"status":"healthy"' || echo "DOWN")
if [[ $INVENTORY_SERVICE_HEALTH == *"healthy"* ]]; then
  echo -e "${GREEN}✅ Inventory Service is running${NC}"
else
  echo -e "${RED}❌ Inventory Service is not running. Please start it first.${NC}"
  exit 1
fi

# Check Analytics API
ANALYTICS_API_HEALTH=$(curl -s http://localhost:9300/health | grep -o '"status":"healthy"' || echo "DOWN")
if [[ $ANALYTICS_API_HEALTH == *"healthy"* ]]; then
  echo -e "${GREEN}✅ Analytics API is running${NC}"
else
  echo -e "${RED}❌ Analytics API is not running. Please start it first.${NC}"
  exit 1
fi

echo
# Get initial error counts
INITIAL_INVENTORY_ERRORS=$(curl -s http://localhost:9000/errors)
INITIAL_INVENTORY_ERROR_COUNT=$(echo $INITIAL_INVENTORY_ERRORS | grep -o '"error_count":[0-9]*' | head -1 | cut -d':' -f2)
INITIAL_INVENTORY_ERROR_COUNT=${INITIAL_INVENTORY_ERROR_COUNT:-0}

INITIAL_ANALYTICS_ERRORS=$(curl -s http://localhost:9300/api/errors)
INITIAL_ANALYTICS_ERROR_COUNT=$(echo $INITIAL_ANALYTICS_ERRORS | grep -o '"errorCount":[0-9]*' | head -1 | cut -d':' -f2)
INITIAL_ANALYTICS_ERROR_COUNT=${INITIAL_ANALYTICS_ERROR_COUNT:-0}

echo -e "${YELLOW}ℹ️ Initial error counts - Inventory: $INITIAL_INVENTORY_ERROR_COUNT, Analytics: $INITIAL_ANALYTICS_ERROR_COUNT${NC}"

# Send the order and wait for processing
echo -e "${BLUE}🚀 Sending order with Avro serialization...${NC}"

# Create an order using the correct endpoint (Avro serialization)
ORDER_RESPONSE=$(curl -s -X POST http://localhost:9080/orders \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "amount": 99.99,
    "items": [
      {
        "productId": "product456",
        "quantity": 2,
        "price": 49.99
      }
    ]
  }')

ORDER_ID=$(echo $ORDER_RESPONSE | grep -o '"orderId":"[^"]*"' | cut -d'"' -f4)

if [ -n "$ORDER_ID" ]; then
  echo -e "${GREEN}✅ Order created with ID: $ORDER_ID${NC}"
else
  echo -e "${RED}❌ Failed to create order${NC}"
  exit 1
fi

echo
echo -e "${YELLOW}⏳ Waiting for message processing (5 seconds)...${NC}"
sleep 5

# Check for new errors in Inventory Service
FINAL_INVENTORY_ERRORS=$(curl -s http://localhost:9000/errors)
FINAL_INVENTORY_ERROR_COUNT=$(echo $FINAL_INVENTORY_ERRORS | grep -o '"error_count":[0-9]*' | head -1 | cut -d':' -f2)
FINAL_INVENTORY_ERROR_COUNT=${FINAL_INVENTORY_ERROR_COUNT:-0}
NEW_INVENTORY_ERRORS=$((FINAL_INVENTORY_ERROR_COUNT - INITIAL_INVENTORY_ERROR_COUNT))

echo
echo -e "${BLUE}📊 Results:${NC}"
echo -e "${YELLOW}🔍 New Inventory Service Errors: $NEW_INVENTORY_ERRORS${NC}"

if [ "$NEW_INVENTORY_ERRORS" -gt 0 ]; then
  echo -e "${RED}❌ New errors detected in Inventory Service${NC}"
  echo -e "${RED}⚠️ This is unexpected - the normal flow should not have errors${NC}"
else
  echo -e "${GREEN}✅ No new errors detected in Inventory Service${NC}"
  echo -e "${GREEN}✓ This is the expected behavior - Avro serialization works across languages${NC}"
fi

# Check for new errors in Analytics API
FINAL_ANALYTICS_ERRORS=$(curl -s http://localhost:9300/api/errors)
FINAL_ANALYTICS_ERROR_COUNT=$(echo $FINAL_ANALYTICS_ERRORS | grep -o '"errorCount":[0-9]*' | head -1 | cut -d':' -f2)
FINAL_ANALYTICS_ERROR_COUNT=${FINAL_ANALYTICS_ERROR_COUNT:-0}
NEW_ANALYTICS_ERRORS=$((FINAL_ANALYTICS_ERROR_COUNT - INITIAL_ANALYTICS_ERROR_COUNT))

echo -e "${YELLOW}🔍 New Analytics API Errors: $NEW_ANALYTICS_ERRORS${NC}"

if [ "$NEW_ANALYTICS_ERRORS" -gt 0 ]; then
  echo -e "${RED}❌ New errors detected in Analytics API${NC}"
  echo -e "${RED}⚠️ This is unexpected - the normal flow should not have errors${NC}"
else
  echo -e "${GREEN}✅ No new errors detected in Analytics API${NC}"
  echo -e "${GREEN}✓ This is the expected behavior - Avro serialization works across languages${NC}"
fi

# Check if order was processed by Inventory Service
INVENTORY_ORDERS=$(curl -s http://localhost:9000/inventory)
INVENTORY_ORDER_COUNT=$(echo $INVENTORY_ORDERS | grep -o "$ORDER_ID" | wc -l)

echo -e "${YELLOW}🔍 Order in Inventory Service: $([ $INVENTORY_ORDER_COUNT -gt 0 ] && echo "Yes" || echo "No")${NC}"

if [ "$INVENTORY_ORDER_COUNT" -gt 0 ]; then
  echo -e "${GREEN}✅ Order was successfully processed by Inventory Service${NC}"
else
  echo -e "${RED}❌ Order was not processed by Inventory Service${NC}"
  echo -e "${RED}⚠️ This is unexpected - the order should be processed${NC}"
fi

# Check if order was processed by Analytics API
ANALYTICS_ORDERS=$(curl -s http://localhost:9300/api/messages/recent)
ANALYTICS_ORDER_COUNT=$(echo $ANALYTICS_ORDERS | grep -o "$ORDER_ID" | wc -l)

echo -e "${YELLOW}🔍 Order in Analytics API: $([ $ANALYTICS_ORDER_COUNT -gt 0 ] && echo "Yes" || echo "No")${NC}"

if [ "$ANALYTICS_ORDER_COUNT" -gt 0 ]; then
  echo -e "${GREEN}✅ Order was successfully processed by Analytics API${NC}"
else
  echo -e "${RED}❌ Order was not processed by Analytics API${NC}"
  echo -e "${RED}⚠️ This is unexpected - the order should be processed${NC}"
fi

echo
echo -e "${BLUE}🎯 Demo Summary:${NC}"
echo -e "${GREEN}✅ This demo shows that Avro serialization enables proper communication between services:${NC}"
echo -e "${YELLOW}📝 The Order Service (Java) can serialize objects using Avro${NC}"
echo -e "${YELLOW}📝 The Inventory Service (Python) can deserialize the Avro messages${NC}"
echo -e "${YELLOW}📝 The Analytics API (Node.js) can also deserialize the Avro messages${NC}"
echo -e "${YELLOW}📝 This demonstrates the power of schema-based serialization for cross-language communication${NC}"
