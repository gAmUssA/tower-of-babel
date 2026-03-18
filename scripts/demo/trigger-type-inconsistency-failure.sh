#!/bin/bash

# Script to trigger type inconsistency failure scenario
# This demonstrates the issues that occur when types don't match across services

# Set colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Triggering Type Inconsistency Failure Demo${NC}"
echo -e "${YELLOW}📋 This demo shows what happens when data types don't match across services${NC}"
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

# Check Analytics API
ANALYTICS_API_HEALTH=$(curl -s http://localhost:9300/health | grep -o '"status":"healthy"' || echo "DOWN")
if [[ $ANALYTICS_API_HEALTH == *"healthy"* ]]; then
  echo -e "${GREEN}✅ Analytics API is running${NC}"
else
  echo -e "${RED}❌ Analytics API is not running. Please start it first.${NC}"
  exit 1
fi

echo
echo -e "${BLUE}🚀 Sending orders with various type issues...${NC}"

# Create an order with string amount — JSON silently accepts it,
# but consumers expecting a number type may break or silently coerce
ORDER_RESPONSE1=$(curl -s -X POST http://localhost:9080/orders \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "amount": "99.99",
    "items": [
      {
        "productId": "product456",
        "quantity": 2,
        "price": 49.99
      }
    ]
  }')

ORDER_ID1=$(echo $ORDER_RESPONSE1 | grep -o '"orderId":"[^"]*"' | cut -d'"' -f4)

if [ -n "$ORDER_ID1" ]; then
  echo -e "${GREEN}✅ Order created with ID: $ORDER_ID1 (amount: '99.99' as string)${NC}"
else
  echo -e "${RED}❌ Failed to create order with invalid amount${NC}"
fi

# Create an order with product ID that can't be parsed as number
ORDER_RESPONSE2=$(curl -s -X POST http://localhost:9080/orders \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "amount": 199.99,
    "items": [
      {
        "productId": "product-with-dashes",
        "quantity": 2,
        "price": 99.99
      }
    ]
  }')

ORDER_ID2=$(echo $ORDER_RESPONSE2 | grep -o '"orderId":"[^"]*"' | cut -d'"' -f4)

if [ -n "$ORDER_ID2" ]; then
  echo -e "${GREEN}✅ Order created with ID: $ORDER_ID2 (productId: 'product-with-dashes')${NC}"
else
  echo -e "${RED}❌ Failed to create order with invalid productId${NC}"
fi

# Create an order with user ID that can't be parsed as number
ORDER_RESPONSE3=$(curl -s -X POST http://localhost:9080/orders \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user-with-dashes",
    "amount": 299.99,
    "items": [
      {
        "productId": "product789",
        "quantity": 3,
        "price": 99.99
      }
    ]
  }')

ORDER_ID3=$(echo $ORDER_RESPONSE3 | grep -o '"orderId":"[^"]*"' | cut -d'"' -f4)

if [ -n "$ORDER_ID3" ]; then
  echo -e "${GREEN}✅ Order created with ID: $ORDER_ID3 (userId: 'user-with-dashes')${NC}"
else
  echo -e "${RED}❌ Failed to create order with invalid userId${NC}"
fi

echo
echo -e "${YELLOW}⏳ Waiting for message processing (5 seconds)...${NC}"
sleep 5

# Check for errors in Analytics API
ANALYTICS_ERRORS=$(curl -s http://localhost:9300/api/errors)
ANALYTICS_ERROR_COUNT=$(echo "$ANALYTICS_ERRORS" | jq '[.json.errorCount, .avro.errorCount] | add // 0')
ANALYTICS_ERROR_COUNT=${ANALYTICS_ERROR_COUNT:-0}

echo
echo -e "${BLUE}📊 Results:${NC}"
echo -e "${YELLOW}🔍 Analytics API Errors: $ANALYTICS_ERROR_COUNT${NC}"

if [ "$ANALYTICS_ERROR_COUNT" -gt 0 ]; then
  echo -e "${RED}❌ Type conversion issues detected in Analytics API${NC}"
  echo -e "${YELLOW}📝 This is expected behavior for the demo - type inconsistencies cause errors${NC}"
else
  echo -e "${GREEN}✅ No errors detected in Analytics API${NC}"
  echo -e "${YELLOW}📝 The Analytics API handled the type conversions gracefully${NC}"
fi

# Check Analytics API for the orders
ANALYTICS_ORDERS=$(curl -s http://localhost:9300/api/messages/recent)
echo -e "${YELLOW}📝 Check the Analytics Dashboard to see how the orders were processed${NC}"

echo
echo -e "${BLUE}🎯 Demo Summary:${NC}"
echo -e "${YELLOW}📝 This demo shows the challenges of type inconsistencies across services.${NC}"
echo -e "${YELLOW}📝 The Java Order Service uses specific types (UUID, BigDecimal, etc.)${NC}"
echo -e "${YELLOW}📝 The TypeScript Analytics API expects different types (number instead of string, etc.)${NC}"
echo -e "${YELLOW}📝 This causes parsing errors and data inconsistencies${NC}"
echo -e "${YELLOW}📝 Schema-based serialization with Avro would solve these issues by enforcing consistent types${NC}"
echo -e "${BLUE}🌐 Visit the Analytics Dashboard: http://localhost:9300/analytics/dashboard${NC}"
