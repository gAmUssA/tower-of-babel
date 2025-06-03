#!/bin/bash

# Script to trigger Java serialization failure scenario
# This demonstrates the issues that occur when using Java serialization instead of Avro

# Set colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Triggering Java Serialization Failure Demo${NC}"
echo -e "${YELLOW}📋 This demo shows what happens when Java serialization is used instead of Avro${NC}"
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
echo -e "${BLUE}🚀 Sending order with Java serialization...${NC}"

# Create an order using the broken endpoint (Java serialization)
ORDER_RESPONSE=$(curl -s -X POST http://localhost:9080/orders/broken \
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

# Check for errors in Inventory Service
INVENTORY_ERRORS=$(curl -s http://localhost:9000/errors)
INVENTORY_ERROR_COUNT=$(echo $INVENTORY_ERRORS | grep -o '"error_count":[0-9]*' | cut -d':' -f2)

echo
echo -e "${BLUE}📊 Results:${NC}"
echo -e "${YELLOW}🔍 Inventory Service Errors: $INVENTORY_ERROR_COUNT${NC}"

if [ "$INVENTORY_ERROR_COUNT" -gt 0 ]; then
  echo -e "${RED}❌ Deserialization failure detected in Inventory Service${NC}"
  echo -e "${YELLOW}📝 This is expected behavior for the demo - Java serialization cannot be deserialized by Python${NC}"
else
  echo -e "${GREEN}✅ No errors detected in Inventory Service${NC}"
  echo -e "${RED}⚠️ This is unexpected - the demo should show deserialization failures${NC}"
fi

# Check for errors in Analytics API
ANALYTICS_ERRORS=$(curl -s http://localhost:9300/api/errors)
ANALYTICS_ERROR_COUNT=$(echo $ANALYTICS_ERRORS | grep -o '"errorCount":[0-9]*' | cut -d':' -f2)

echo -e "${YELLOW}🔍 Analytics API Errors: $ANALYTICS_ERROR_COUNT${NC}"

if [ "$ANALYTICS_ERROR_COUNT" -gt 0 ]; then
  echo -e "${RED}❌ Deserialization failure detected in Analytics API${NC}"
  echo -e "${YELLOW}📝 This is expected behavior for the demo - Java serialization cannot be deserialized by Node.js${NC}"
else
  echo -e "${GREEN}✅ No errors detected in Analytics API${NC}"
  echo -e "${RED}⚠️ This is unexpected - the demo should show deserialization failures${NC}"
fi

echo
echo -e "${BLUE}🎯 Demo Summary:${NC}"
echo -e "${YELLOW}📝 This demo shows that Java serialization is not interoperable between different languages.${NC}"
echo -e "${YELLOW}📝 The Order Service (Java) can serialize objects, but Inventory Service (Python) and Analytics API (Node.js) cannot deserialize them.${NC}"
echo -e "${YELLOW}📝 This is why schema-based serialization formats like Avro are needed for cross-language communication.${NC}"
