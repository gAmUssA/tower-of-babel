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

# Interactive mode support
INTERACTIVE=false
SCENARIO="all"
for arg in "$@"; do
  case "$arg" in
    -i|--interactive) INTERACTIVE=true ;;
    all|java|json|type) SCENARIO="$arg" ;;
    *)
      echo -e "${RED}Usage: $0 [-i|--interactive] [all|java|json|type]${NC}"
      echo -e "${YELLOW}  -i   - Interactive mode (pause between scenarios)${NC}"
      echo -e "${YELLOW}  all  - Run all chaos scenarios (default)${NC}"
      echo -e "${YELLOW}  java - Java serialization failure${NC}"
      echo -e "${YELLOW}  json - JSON field name mismatch${NC}"
      echo -e "${YELLOW}  type - Type inconsistency${NC}"
      exit 1
      ;;
  esac
done

pause() {
  if [ "$INTERACTIVE" = true ]; then
    echo ""
    read -r -p "  Press Enter to continue..."
    echo ""
  fi
}

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
    INITIAL_INV_ERRORS=$(curl -s http://localhost:9000/errors | jq '[.json_consumer.error_count, .avro_consumer.error_count] | add // 0')
    INITIAL_INV_ERRORS=${INITIAL_INV_ERRORS:-0}
    INITIAL_ANA_ERRORS=$(curl -s http://localhost:9300/api/errors | jq '[.json.errorCount, .avro.errorCount] | add // 0')
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
    NEW_INV_ERRORS=$(curl -s http://localhost:9000/errors | jq '[.json_consumer.error_count, .avro_consumer.error_count] | add // 0')
    NEW_INV_ERRORS=${NEW_INV_ERRORS:-0}
    NEW_ANA_ERRORS=$(curl -s http://localhost:9300/api/errors | jq '[.json.errorCount, .avro.errorCount] | add // 0')
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
    pause
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
    pause
fi

# Scenario 1c: Type Inconsistency
if [ "$SCENARIO" = "all" ] || [ "$SCENARIO" = "type" ]; then
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}🔢 Scenario 1c: Type Inconsistency${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Testing: String vs Number type mismatches${NC}\n"

    # Get initial error count and messages
    INITIAL_ANA_ERRORS=$(curl -s http://localhost:9300/api/errors | jq '[.json.errorCount, .avro.errorCount] | add // 0')
    INITIAL_ANA_ERRORS=${INITIAL_ANA_ERRORS:-0}

    echo -e "${CYAN}Sending orders with type issues...${NC}"
    echo -e "${YELLOW}Example 1: amount as string instead of number${NC}"
    echo -e "${BLUE}  Sent:     amount: \"99.99\" (string)${NC}"
    echo -e "${BLUE}  Expected: amount: 99.99 (number)${NC}\n"

    # Order with amount as quoted string — JSON silently accepts it,
    # but consumers expecting a number type may break or silently coerce
    ORDER_RESPONSE_1=$(curl -s -X POST http://localhost:9080/orders \
      -H "Content-Type: application/json" \
      -d '{
        "userId": "user-type-'$(date +%s)'",
        "amount": "99.99",
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
    NEW_ANA_ERRORS=$(curl -s http://localhost:9300/api/errors | jq '[.json.errorCount, .avro.errorCount] | add // 0')
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
      ERROR_LINES=$(echo "$ERROR_DETAILS" | jq -r '([.json.lastErrors[]?, .avro.lastErrors[]?])[-3:][]? // empty' 2>/dev/null)
      if [ -n "$ERROR_LINES" ]; then
        echo "$ERROR_LINES" | while read -r err; do echo "  - $err"; done
      else
        echo "  (Error details not available)"
      fi
      
      echo -e "\n${YELLOW}💡 What happened:${NC}"
      echo -e "  ${RED}•${NC} JSON accepted string \"99.99\" where number 99.99 was intended"
      echo -e "  ${RED}•${NC} No schema contract to enforce correct types at produce time"
      echo -e "  ${RED}•${NC} Consumers must guess and coerce types at runtime"
      echo -e "  ${RED}•${NC} productId \"product123\" parsed as NaN by Analytics API (expects number)"
      
      echo -e "\n${YELLOW}🔍 To see detailed errors, visit:${NC}"
      echo -e "  ${BLUE}http://localhost:9300/analytics/dashboard${NC}"
      echo -e "  ${BLUE}http://localhost:9300/api/errors${NC}\n"
    else
      echo -e "${YELLOW}⚠️  No errors — but the data is SILENTLY WRONG${NC}"
      echo -e "${YELLOW}💡 JSON accepted string \"99.99\" and consumers silently coerced it${NC}"
      echo -e "${YELLOW}💡 Without a schema, nobody knows the correct type${NC}\n"
    fi

    # Show the data mismatch visually regardless of error count
    echo -e "${CYAN}🔍 Inspecting the data at each service:${NC}\n"

    if [ -n "$ORDER_ID_1" ]; then
      echo -e "${YELLOW}☕ Java Order Service sent:${NC}"
      JAVA_ORDER=$(curl -s "http://localhost:9080/orders/$ORDER_ID_1")
      if [ -n "$JAVA_ORDER" ] && echo "$JAVA_ORDER" | jq -e '.amount' > /dev/null 2>&1; then
        JAVA_AMOUNT=$(echo "$JAVA_ORDER" | jq -r '.amount')
        echo -e "  amount = ${JAVA_AMOUNT} (${BLUE}number${NC})"
      fi

      echo -e "${YELLOW}📊 Node.js Analytics API received:${NC}"
      ANALYTICS_MSG=$(curl -s "http://localhost:9300/api/messages/recent" | jq -r ".messages[]? | select(.orderId == \"$ORDER_ID_1\")" 2>/dev/null)
      if [ -n "$ANALYTICS_MSG" ]; then
        ANA_AMOUNT=$(echo "$ANALYTICS_MSG" | jq -r '.amount')
        ANA_TYPE=$(echo "$ANALYTICS_MSG" | jq -r '.amount | type')
        echo -e "  amount = ${ANA_AMOUNT} (${RED}${ANA_TYPE}${NC})"
        echo -e "${RED}  ⚠️  Type mismatch: producer sent a number, consumer stored a ${ANA_TYPE}${NC}"
      else
        echo -e "  (Order not yet visible in Analytics API)"
      fi
    fi

    echo ""
    pause
fi

pause

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
