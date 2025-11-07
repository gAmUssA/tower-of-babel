#!/bin/bash

# Demo 1: Tower of Babel - Serialization Chaos
# This demonstrates cross-language serialization failures without Schema Registry

# Set colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🗼 Demo 1: Tower of Babel - Serialization Chaos${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo -e "${YELLOW}This demo shows the problems that occur when services use${NC}"
echo -e "${YELLOW}different serialization formats without a common schema.${NC}"
echo -e "${CYAN}=====================================================${NC}\n"

# Parse command line arguments
SCENARIO=${1:-all}

if [ "$SCENARIO" != "all" ] && [ "$SCENARIO" != "java" ] && [ "$SCENARIO" != "json" ] && [ "$SCENARIO" != "type" ]; then
    echo -e "${RED}Usage: $0 [all|java|json|type]${NC}"
    echo -e "${YELLOW}  all  - Run all chaos scenarios (default)${NC}"
    echo -e "${YELLOW}  java - Java serialization failure${NC}"
    echo -e "${YELLOW}  json - JSON field name mismatch${NC}"
    echo -e "${YELLOW}  type - Type inconsistency${NC}"
    exit 1
fi

# Check if services are running
echo -e "${BLUE}🔍 Checking if services are running...${NC}"

ORDER_SERVICE_HEALTH=$(curl -s http://localhost:9080/actuator/health | grep -o '"status":"UP"' || echo "DOWN")
if [[ $ORDER_SERVICE_HEALTH != *"UP"* ]]; then
  echo -e "${RED}❌ Order Service is not running. Please start it first.${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Order Service is running${NC}"

INVENTORY_SERVICE_HEALTH=$(curl -s http://localhost:9000/health | grep -o '"status":"healthy"' || echo "DOWN")
if [[ $INVENTORY_SERVICE_HEALTH != *"healthy"* ]]; then
  echo -e "${RED}❌ Inventory Service is not running. Please start it first.${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Inventory Service is running${NC}"

ANALYTICS_API_HEALTH=$(curl -s http://localhost:9300/health | grep -o '"status":"healthy"' || echo "DOWN")
if [[ $ANALYTICS_API_HEALTH != *"healthy"* ]]; then
  echo -e "${RED}❌ Analytics API is not running. Please start it first.${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Analytics API is running${NC}"

echo ""

# Scenario 1a: Java Serialization Failure
if [ "$SCENARIO" = "all" ] || [ "$SCENARIO" = "java" ]; then
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}📦 Scenario 1a: Java Serialization Failure${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Testing: Java Object Serialization → Python/Node.js${NC}\n"

    # Get initial error counts
    INITIAL_INV_ERRORS=$(curl -s http://localhost:9000/errors | grep -o '"error_count":[0-9]*' | head -1 | cut -d':' -f2)
    INITIAL_INV_ERRORS=${INITIAL_INV_ERRORS:-0}
    INITIAL_ANA_ERRORS=$(curl -s http://localhost:9300/api/errors | grep -o '"errorCount":[0-9]*' | head -1 | cut -d':' -f2)
    INITIAL_ANA_ERRORS=${INITIAL_ANA_ERRORS:-0}

    echo -e "${CYAN}Sending order with Java serialization...${NC}"
    ORDER_RESPONSE=$(curl -s -X POST http://localhost:9080/orders/broken \
      -H "Content-Type: application/json" \
      -d '{
        "userId": "user-java-'$(date +%s)'",
        "amount": 99.99,
        "items": [{"productId": "product456", "quantity": 2, "price": 49.99}]
      }')

    ORDER_ID=$(echo $ORDER_RESPONSE | grep -o '"orderId":"[^"]*"' | cut -d'"' -f4)

    if [ -n "$ORDER_ID" ]; then
      echo -e "${GREEN}✅ Order created with ID: $ORDER_ID${NC}"
    else
      echo -e "${RED}❌ Failed to create order${NC}"
    fi

    echo -e "${YELLOW}⏳ Waiting for message processing (5 seconds)...${NC}"
    sleep 5

    # Check for new errors
    NEW_INV_ERRORS=$(curl -s http://localhost:9000/errors | grep -o '"error_count":[0-9]*' | head -1 | cut -d':' -f2)
    NEW_INV_ERRORS=${NEW_INV_ERRORS:-0}
    NEW_ANA_ERRORS=$(curl -s http://localhost:9300/api/errors | grep -o '"errorCount":[0-9]*' | head -1 | cut -d':' -f2)
    NEW_ANA_ERRORS=${NEW_ANA_ERRORS:-0}

    INV_ERROR_DIFF=$((NEW_INV_ERRORS - INITIAL_INV_ERRORS))
    ANA_ERROR_DIFF=$((NEW_ANA_ERRORS - INITIAL_ANA_ERRORS))

    echo -e "\n${CYAN}Results:${NC}"
    echo -e "  Inventory Service: ${INV_ERROR_DIFF} new errors"
    echo -e "  Analytics API: ${ANA_ERROR_DIFF} new errors"

    if [ "$INV_ERROR_DIFF" -gt 0 ] || [ "$ANA_ERROR_DIFF" -gt 0 ]; then
      echo -e "${RED}❌ Deserialization failures detected (expected)${NC}"
      echo -e "${YELLOW}💡 Java serialization is not interoperable across languages${NC}\n"
    else
      echo -e "${YELLOW}⚠️  No errors detected (unexpected)${NC}\n"
    fi
fi

# Scenario 1b: JSON Field Name Mismatch
if [ "$SCENARIO" = "all" ] || [ "$SCENARIO" = "json" ]; then
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}🏷️  Scenario 1b: JSON Field Name Mismatch${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Testing: camelCase vs snake_case field naming${NC}\n"

    echo -e "${CYAN}Sending order with JSON serialization...${NC}"
    ORDER_RESPONSE=$(curl -s -X POST http://localhost:9080/orders \
      -H "Content-Type: application/json" \
      -d '{
        "userId": "user-json-'$(date +%s)'",
        "amount": 149.99,
        "items": [{"productId": "product789", "quantity": 3, "price": 49.99}]
      }')

    ORDER_ID=$(echo $ORDER_RESPONSE | grep -o '"orderId":"[^"]*"' | cut -d'"' -f4)

    if [ -n "$ORDER_ID" ]; then
      echo -e "${GREEN}✅ Order created with ID: $ORDER_ID${NC}"
    else
      echo -e "${RED}❌ Failed to create order${NC}"
    fi

    echo -e "${YELLOW}⏳ Waiting for message processing (5 seconds)...${NC}"
    sleep 5

    # Check if order was processed
    INVENTORY_ORDER=$(curl -s http://localhost:9000/inventory/$ORDER_ID 2>/dev/null)
    INVENTORY_STATUS=$(echo $INVENTORY_ORDER | grep -o '"status":"[^"]*"' || echo "NOT_FOUND")

    echo -e "\n${CYAN}Results:${NC}"
    if [[ $INVENTORY_STATUS == *"RESERVED"* ]]; then
      echo -e "${GREEN}✅ Inventory Service processed the order${NC}"
      echo -e "${YELLOW}💡 Python service uses field name guessing (orderId → order_id)${NC}\n"
    else
      echo -e "${RED}❌ Inventory Service did not process the order${NC}\n"
    fi
fi

# Scenario 1c: Type Inconsistency
if [ "$SCENARIO" = "all" ] || [ "$SCENARIO" = "type" ]; then
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}🔢 Scenario 1c: Type Inconsistency${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Testing: String vs Number type mismatches${NC}\n"

    # Get initial error count and messages
    INITIAL_ANA_ERRORS=$(curl -s http://localhost:9300/api/errors | grep -o '"errorCount":[0-9]*' | head -1 | cut -d':' -f2)
    INITIAL_ANA_ERRORS=${INITIAL_ANA_ERRORS:-0}

    echo -e "${CYAN}Sending orders with type issues...${NC}"
    echo -e "${YELLOW}Example 1: amount as string instead of number${NC}"
    echo -e "${BLUE}  Sent:     amount: \"not-a-number\" (string)${NC}"
    echo -e "${BLUE}  Expected: amount: 99.99 (number)${NC}\n"
    
    # Order with invalid amount
    ORDER_RESPONSE_1=$(curl -s -X POST http://localhost:9080/orders \
      -H "Content-Type: application/json" \
      -d '{
        "userId": "user-type-'$(date +%s)'",
        "amount": "not-a-number",
        "items": [{"productId": "product123", "quantity": 1, "price": 99.99}]
      }')

    ORDER_ID_1=$(echo $ORDER_RESPONSE_1 | grep -o '"orderId":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$ORDER_ID_1" ]; then
      echo -e "${GREEN}✅ Order created: $ORDER_ID_1${NC}"
    else
      echo -e "${YELLOW}⚠️  Order creation may have failed due to validation${NC}"
    fi

    echo -e "\n${YELLOW}Example 2: userId with special characters${NC}"
    echo -e "${BLUE}  Sent:     userId: \"user-with-@-symbols\" (string with special chars)${NC}"
    echo -e "${BLUE}  Expected: userId: \"user123\" (alphanumeric string)${NC}\n"
    
    ORDER_RESPONSE_2=$(curl -s -X POST http://localhost:9080/orders \
      -H "Content-Type: application/json" \
      -d '{
        "userId": "user-with-@-symbols-'$(date +%s)'",
        "amount": 199.99,
        "items": [{"productId": "product456", "quantity": 2, "price": 99.99}]
      }')

    ORDER_ID_2=$(echo $ORDER_RESPONSE_2 | grep -o '"orderId":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$ORDER_ID_2" ]; then
      echo -e "${GREEN}✅ Order created: $ORDER_ID_2${NC}"
    fi

    echo -e "\n${YELLOW}⏳ Waiting for message processing (7 seconds)...${NC}"
    sleep 7

    # Check for new errors
    NEW_ANA_ERRORS=$(curl -s http://localhost:9300/api/errors | grep -o '"errorCount":[0-9]*' | head -1 | cut -d':' -f2)
    NEW_ANA_ERRORS=${NEW_ANA_ERRORS:-0}
    ANA_ERROR_DIFF=$((NEW_ANA_ERRORS - INITIAL_ANA_ERRORS))

    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Results:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  Analytics API Errors: ${ANA_ERROR_DIFF} new errors"

    if [ "$ANA_ERROR_DIFF" -gt 0 ]; then
      echo -e "${RED}❌ Type conversion failures detected (expected)${NC}\n"
      
      # Show actual error messages
      echo -e "${YELLOW}📋 Recent error messages from Analytics API:${NC}"
      ERROR_DETAILS=$(curl -s http://localhost:9300/api/errors)
      echo "$ERROR_DETAILS" | jq -r '.recentErrors[]? | "  • \(.timestamp | strftime("%H:%M:%S")): \(.message)"' 2>/dev/null | tail -3 || echo "  (Error details not available)"
      
      echo -e "\n${YELLOW}💡 What happened:${NC}"
      echo -e "  ${RED}•${NC} Analytics API expects numeric types for calculations"
      echo -e "  ${RED}•${NC} Received string values that cannot be parsed as numbers"
      echo -e "  ${RED}•${NC} Type coercion failed, causing processing errors"
      echo -e "  ${RED}•${NC} Data inconsistency between producer and consumer"
      
      echo -e "\n${YELLOW}🔍 To see detailed errors, visit:${NC}"
      echo -e "  ${BLUE}http://localhost:9300/analytics/dashboard${NC}"
      echo -e "  ${BLUE}http://localhost:9300/api/errors${NC}\n"
    else
      echo -e "${YELLOW}⚠️  No errors detected - service handled gracefully${NC}"
      echo -e "${YELLOW}💡 The Analytics API may have type coercion or validation that prevented errors${NC}\n"
    fi
fi

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Demo 1 Summary: Tower of Babel${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Problems demonstrated:${NC}"
echo -e "  ${RED}❌${NC} Java serialization is not cross-language compatible"
echo -e "  ${RED}❌${NC} JSON field naming inconsistencies (camelCase vs snake_case)"
echo -e "  ${RED}❌${NC} Type mismatches between languages"
echo -e ""
echo -e "${GREEN}Solution:${NC} Schema Registry with Avro provides:"
echo -e "  ${GREEN}✅${NC} Language-agnostic binary serialization"
echo -e "  ${GREEN}✅${NC} Enforced field names and types"
echo -e "  ${GREEN}✅${NC} Automatic code generation for all languages"
echo -e ""
echo -e "${CYAN}Next: Run ${BLUE}./scripts/demo/demo-2-babel-fish.sh${CYAN} to see the solution${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
