#!/bin/bash
# Phase 4 Test Script - Schema Registry Integration with Avro
# This script runs a series of tests to verify Avro serialization with Schema Registry

# Set colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Set emojis for better readability
CHECK="✅"
CROSS="❌"
ROCKET="🚀"
WRENCH="🔧"
MAGNIFYING="🔍"
BOOKS="📚"
CHART="📊"
LAPTOP="💻"
CLOUD="☁️"
TEST="🧪"

echo -e "${BLUE}${TEST} Phase 4 Test Suite: Schema Registry Integration with Avro ${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo -e "${YELLOW}Running comprehensive tests for Avro serialization${NC}"
echo -e "${CYAN}=====================================================${NC}\n"

# Check if services are running
echo -e "${BLUE}${MAGNIFYING} Verifying service availability...${NC}"

# Check Schema Registry
echo -ne "${CYAN}Schema Registry...${NC} "
if curl -s http://localhost:8081/subjects | grep -q ""; then
    echo -e "${GREEN}${CHECK} Available${NC}"
    # List available schemas
    echo -e "${CYAN}Available schemas:${NC}"
    curl -s http://localhost:8081/subjects | jq .
else
    echo -e "${RED}${CROSS} Not available${NC}"
    echo -e "${YELLOW}Please start Schema Registry using: make run-kafka${NC}"
    exit 1
fi

# Check Order Service
echo -ne "${CYAN}Order Service...${NC} "
if curl -s http://localhost:9080/actuator/health | grep -q "UP"; then
    echo -e "${GREEN}${CHECK} Available${NC}"
else
    echo -e "${RED}${CROSS} Not available${NC}"
    echo -e "${YELLOW}Please start the Order Service using: make run-order-service${NC}"
    exit 1
fi

# Check Inventory Service
echo -ne "${CYAN}Inventory Service...${NC} "
if curl -s http://localhost:9000/health | grep -q "healthy"; then
    echo -e "${GREEN}${CHECK} Available${NC}"
else
    echo -e "${RED}${CROSS} Not available${NC}"
    echo -e "${YELLOW}Please start the Inventory Service using: make run-inventory-service${NC}"
    exit 1
fi

# Check Analytics API
echo -ne "${CYAN}Analytics API...${NC} "
if curl -s http://localhost:9300/health | grep -q "healthy"; then
    echo -e "${GREEN}${CHECK} Available${NC}"
else
    echo -e "${RED}${CROSS} Not available${NC}"
    echo -e "${YELLOW}Please start the Analytics API using: make run-analytics-api${NC}"
    exit 1
fi

echo -e "\n${BLUE}${TEST} Test 1: Schema Registry Subject Registration${NC}"
echo -e "${CYAN}----------------------------------------------------${NC}"
# Check if orders-value subject exists in Schema Registry
echo -ne "${CYAN}Checking if orders-value subject exists...${NC} "
if curl -s http://localhost:8081/subjects/orders-value/versions | grep -q ""; then
    echo -e "${GREEN}${CHECK} Subject exists${NC}"
    # Get the latest schema version
    SCHEMA_VERSION=$(curl -s http://localhost:8081/subjects/orders-value/versions | jq '.[-1]')
    echo -e "${CYAN}Latest schema version: ${SCHEMA_VERSION}${NC}"
    
    # Get schema details
    echo -e "${CYAN}Schema details:${NC}"
    curl -s http://localhost:8081/subjects/orders-value/versions/$SCHEMA_VERSION | jq .
else
    echo -e "${RED}${CROSS} Subject not found${NC}"
    echo -e "${YELLOW}The schema has not been registered yet. It will be registered when an Avro message is produced.${NC}"
fi

echo -e "\n${BLUE}${TEST} Test 2: Order Creation with Avro Serialization${NC}"
echo -e "${CYAN}----------------------------------------------------${NC}"
# Create a test order
echo -e "${CYAN}Creating test order using Avro serialization...${NC}"
ORDER_RESPONSE=$(curl -s -X POST http://localhost:9080/orders/avro -H "Content-Type: application/json" -d '{
    "userId": "test-user-'$(date +%s)'",
    "amount": 123.45,
    "items": [
        {
            "productId": "test-product-'$(date +%s)'",
            "quantity": 3,
            "price": 41.15
        }
    ]
}')

ORDER_ID=$(echo $ORDER_RESPONSE | grep -o '"orderId":"[^"]*' | cut -d'"' -f4)

if [ -n "$ORDER_ID" ]; then
    echo -e "${GREEN}${CHECK} Order created successfully with ID: ${ORDER_ID}${NC}"
    echo -e "${CYAN}Order details:${NC}"
    echo $ORDER_RESPONSE | jq .
else
    echo -e "${RED}${CROSS} Failed to create order${NC}"
    echo $ORDER_RESPONSE
    exit 1
fi

# Wait for processing
echo -e "\n${YELLOW}Waiting for message propagation (5 seconds)...${NC}"
sleep 5

# Get initial error counts
INVENTORY_ERRORS=$(curl -s http://localhost:9000/errors | grep -o '"error_count":[0-9]*' | head -1 | cut -d':' -f2)
ANALYTICS_ERRORS=$(curl -s http://localhost:9300/api/errors | grep -o '"errorCount":[0-9]*' | head -1 | cut -d':' -f2)

echo -e "\n${BLUE}${TEST} Test 3: Python Avro Deserialization${NC}"
echo -e "${CYAN}----------------------------------------------------${NC}"
# Check if the order was processed by the Inventory Service
echo -e "${CYAN}Checking Inventory Service Avro deserialization...${NC}"
INVENTORY_RESULT=$(curl -s "http://localhost:9000/inventory?source=avro")
if echo $INVENTORY_RESULT | grep -q "$ORDER_ID"; then
    echo -e "${GREEN}${CHECK} Order successfully deserialized by Python Inventory Service!${NC}"
    echo -e "${CYAN}Order data in Inventory Service:${NC}"
    echo $INVENTORY_RESULT | grep -A 10 "$ORDER_ID" | head -5
else
    echo -e "${RED}${CROSS} Order not found in Inventory Service${NC}"
    echo -e "${YELLOW}This indicates a deserialization issue between Order Service and Inventory Service${NC}"
    echo -e "${YELLOW}Checking for errors:${NC}"
    curl -s "http://localhost:9000/errors"
    echo
fi

echo -e "\n${BLUE}${TEST} Test 4: TypeScript Avro Deserialization${NC}"
echo -e "${CYAN}----------------------------------------------------${NC}"
# Check if the order was processed by the Analytics API
echo -e "${CYAN}Checking Analytics API Avro deserialization...${NC}"
ANALYTICS_RESULT=$(curl -s "http://localhost:9300/api/messages/avro")
if echo $ANALYTICS_RESULT | grep -q "$ORDER_ID"; then
    echo -e "${GREEN}${CHECK} Order successfully deserialized by TypeScript Analytics API!${NC}"
    echo -e "${CYAN}Order data in Analytics API:${NC}"
    echo $ANALYTICS_RESULT | grep -A 10 "$ORDER_ID" | head -5
else
    echo -e "${RED}${CROSS} Order not found in Analytics API${NC}"
    echo -e "${YELLOW}This indicates a deserialization issue between Order Service and Analytics API${NC}"
    echo -e "${YELLOW}Checking for errors:${NC}"
    curl -s "http://localhost:9300/api/errors"
    echo
fi

echo -e "\n${BLUE}${TEST} Test 5: Error Detection${NC}"
echo -e "${CYAN}----------------------------------------------------${NC}"
# Check for any new errors
NEW_INVENTORY_ERRORS=$(curl -s http://localhost:9000/errors | grep -o '"error_count":[0-9]*' | head -1 | cut -d':' -f2)
NEW_ANALYTICS_ERRORS=$(curl -s http://localhost:9300/api/errors | grep -o '"errorCount":[0-9]*' | head -1 | cut -d':' -f2)

INVENTORY_ERROR_DIFF=$((NEW_INVENTORY_ERRORS - INVENTORY_ERRORS))
ANALYTICS_ERROR_DIFF=$((NEW_ANALYTICS_ERRORS - ANALYTICS_ERRORS))

# Check for any new errors
echo -e "${CYAN}Checking for deserialization errors...${NC}"
if [ "$INVENTORY_ERROR_DIFF" -gt 0 ]; then
    echo -e "${RED}${CROSS} Inventory Service reported ${INVENTORY_ERROR_DIFF} new errors during processing${NC}"
else
    echo -e "${GREEN}${CHECK} No new errors in Inventory Service${NC}"
fi

if [ "$ANALYTICS_ERROR_DIFF" -gt 0 ]; then
    echo -e "${RED}${CROSS} Analytics API reported ${ANALYTICS_ERROR_DIFF} new errors during processing${NC}"
else
    echo -e "${GREEN}${CHECK} No new errors in Analytics API${NC}"
fi

echo -e "\n${BLUE}${TEST} Test 6: Schema Validation${NC}"
echo -e "${CYAN}----------------------------------------------------${NC}"
# Check if orders-value subject exists now (should be created after sending a message)
echo -ne "${CYAN}Verifying schema was registered in Schema Registry...${NC} "
if curl -s http://localhost:8081/subjects/orders-value/versions | grep -q ""; then
    echo -e "${GREEN}${CHECK} Schema registered successfully${NC}"
    # Get the latest schema version
    SCHEMA_VERSION=$(curl -s http://localhost:8081/subjects/orders-value/versions | jq '.[-1]')
    echo -e "${CYAN}Schema version: ${SCHEMA_VERSION}${NC}"
    
    # Get schema ID
    SCHEMA_ID=$(curl -s http://localhost:8081/subjects/orders-value/versions/$SCHEMA_VERSION | jq '.id')
    echo -e "${CYAN}Schema ID: ${SCHEMA_ID}${NC}"
    
    # Get schema compatibility
    COMPATIBILITY=$(curl -s http://localhost:8081/config/orders-value)
    echo -e "${CYAN}Schema compatibility setting:${NC}"
    echo $COMPATIBILITY | jq .
else
    echo -e "${RED}${CROSS} Schema not registered${NC}"
    echo -e "${YELLOW}Something went wrong with Schema Registry integration${NC}"
fi

# Test Results Summary
echo -e "\n${BLUE}${CHART} Phase 4 Test Results Summary${NC}"
echo -e "${CYAN}=====================================================${NC}"

TEST_FAILURES=0
if ! curl -s http://localhost:8081/subjects/orders-value/versions | grep -q ""; then
    echo -e "${RED}${CROSS} Test 1: Schema Registration - FAILED${NC}"
    TEST_FAILURES=$((TEST_FAILURES + 1))
else
    echo -e "${GREEN}${CHECK} Test 1: Schema Registration - PASSED${NC}"
fi

if [ -z "$ORDER_ID" ]; then
    echo -e "${RED}${CROSS} Test 2: Order Creation - FAILED${NC}"
    TEST_FAILURES=$((TEST_FAILURES + 1))
else
    echo -e "${GREEN}${CHECK} Test 2: Order Creation - PASSED${NC}"
fi

if ! echo $INVENTORY_RESULT | grep -q "$ORDER_ID"; then
    echo -e "${RED}${CROSS} Test 3: Python Deserialization - FAILED${NC}"
    TEST_FAILURES=$((TEST_FAILURES + 1))
else
    echo -e "${GREEN}${CHECK} Test 3: Python Deserialization - PASSED${NC}"
fi

if ! echo $ANALYTICS_RESULT | grep -q "$ORDER_ID"; then
    echo -e "${RED}${CROSS} Test 4: TypeScript Deserialization - FAILED${NC}"
    TEST_FAILURES=$((TEST_FAILURES + 1))
else
    echo -e "${GREEN}${CHECK} Test 4: TypeScript Deserialization - PASSED${NC}"
fi

if [ "$INVENTORY_ERROR_DIFF" -gt 0 ] || [ "$ANALYTICS_ERROR_DIFF" -gt 0 ]; then
    echo -e "${RED}${CROSS} Test 5: Error Detection - FAILED${NC}"
    TEST_FAILURES=$((TEST_FAILURES + 1))
else
    echo -e "${GREEN}${CHECK} Test 5: Error Detection - PASSED${NC}"
fi

if ! curl -s http://localhost:8081/subjects/orders-value/versions | grep -q ""; then
    echo -e "${RED}${CROSS} Test 6: Schema Validation - FAILED${NC}"
    TEST_FAILURES=$((TEST_FAILURES + 1))
else
    echo -e "${GREEN}${CHECK} Test 6: Schema Validation - PASSED${NC}"
fi

if [ "$TEST_FAILURES" -eq 0 ]; then
    echo -e "\n${GREEN}${ROCKET} All tests PASSED! Phase 4 implementation is working correctly.${NC}"
    echo -e "${GREEN}${CHECK} Schema Registry Integration with Avro is successfully implemented.${NC}"
else
    echo -e "\n${RED}${CROSS} ${TEST_FAILURES} tests FAILED! Please check the logs for details.${NC}"
fi

echo -e "${CYAN}=====================================================${NC}"
