#!/bin/bash

# Script to trigger JSON field name mismatch failure scenario
# This demonstrates the issues that occur when field names don't match across services

# Set colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Triggering JSON Field Name Mismatch Demo${NC}"
echo -e "${YELLOW}📋 This demo shows what happens when JSON field names don't match across services${NC}"
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
echo -e "${BLUE}🚀 Sending order with JSON serialization...${NC}"

# Create an order using the regular endpoint (JSON serialization)
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

# Check if the order was processed by Inventory Service
INVENTORY_ORDER=$(curl -s http://localhost:9000/inventory/$ORDER_ID 2>/dev/null)
INVENTORY_STATUS=$(echo $INVENTORY_ORDER | grep -o '"status":"[^"]*"' || echo "NOT_FOUND")

echo
echo -e "${BLUE}📊 Results:${NC}"

if [[ $INVENTORY_STATUS == *"RESERVED"* ]]; then
  echo -e "${GREEN}✅ Order was processed by Inventory Service${NC}"
  echo -e "${YELLOW}📝 The Inventory Service was able to handle the field name mismatches${NC}"
  echo -e "${YELLOW}📝 It uses field name guessing to map 'orderId' to 'order_id', etc.${NC}"
else
  echo -e "${RED}❌ Order was not processed by Inventory Service${NC}"
  echo -e "${YELLOW}📝 This could be due to field name mismatches or other issues${NC}"
fi

# Check Analytics API for the order
ANALYTICS_ORDERS=$(curl -s http://localhost:9300/api/messages/recent)
ANALYTICS_HAS_ORDER=$(echo $ANALYTICS_ORDERS | grep -o "$ORDER_ID" || echo "NOT_FOUND")

if [[ $ANALYTICS_HAS_ORDER == *"$ORDER_ID"* ]]; then
  echo -e "${GREEN}✅ Order was processed by Analytics API${NC}"
  echo -e "${YELLOW}📝 The Analytics API was able to process the order${NC}"
  echo -e "${YELLOW}📝 But it has type inconsistencies - check the dashboard for errors${NC}"
else
  echo -e "${RED}❌ Order was not processed by Analytics API${NC}"
  echo -e "${YELLOW}📝 This could be due to field name mismatches or type inconsistencies${NC}"
fi

# Check for errors in Analytics API
ANALYTICS_ERRORS=$(curl -s http://localhost:9300/api/errors)
ANALYTICS_ERROR_COUNT=$(echo $ANALYTICS_ERRORS | grep -o '"errorCount":[0-9]*' | cut -d':' -f2)

echo -e "${YELLOW}🔍 Analytics API Errors: $ANALYTICS_ERROR_COUNT${NC}"

if [ "$ANALYTICS_ERROR_COUNT" -gt 0 ]; then
  echo -e "${RED}❌ Type conversion issues detected in Analytics API${NC}"
  echo -e "${YELLOW}📝 This is expected behavior for the demo - type inconsistencies cause errors${NC}"
else
  echo -e "${GREEN}✅ No errors detected in Analytics API${NC}"
  echo -e "${YELLOW}📝 The Analytics API handled the type conversions gracefully${NC}"
fi

echo
echo -e "${BLUE}🎯 Demo Summary:${NC}"
echo -e "${YELLOW}📝 This demo shows the challenges of field name mismatches and type inconsistencies across services.${NC}"
echo -e "${YELLOW}📝 The Inventory Service tries to handle field name mismatches by guessing alternative names.${NC}"
echo -e "${YELLOW}📝 The Analytics API has to convert between types (string to number, etc.) which can cause errors.${NC}"
echo -e "${YELLOW}📝 Schema-based serialization with Avro would solve these issues by enforcing consistent field names and types.${NC}"
echo -e "${BLUE}🌐 Visit the Analytics Dashboard: http://localhost:9300/analytics/dashboard${NC}"
