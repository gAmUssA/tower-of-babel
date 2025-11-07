#!/bin/bash
# Phase 4 Demo Script - Schema Registry Integration with Avro
# This script demonstrates the use of Avro serialization with Schema Registry across all services

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

echo -e "${BLUE}${BOOKS} Phase 4 Demo: Schema Registry Integration with Avro ${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo -e "${YELLOW}This demonstration shows how Avro serialization with Schema Registry\nsolves cross-language serialization issues between services${NC}"
echo -e "${CYAN}=====================================================${NC}\n"

# Check if services are running
echo -e "${BLUE}${MAGNIFYING} Checking if services are running...${NC}"

# Check Order Service
echo -ne "${CYAN}Checking Order Service (Java/Kotlin)...${NC} "
if curl -s http://localhost:9080/actuator/health | grep -q "UP"; then
    echo -e "${GREEN}${CHECK} Running${NC}"
else
    echo -e "${RED}${CROSS} Not running${NC}"
    echo -e "${YELLOW}Please start the Order Service using: make run-order-service${NC}"
    exit 1
fi

# Check Inventory Service
echo -ne "${CYAN}Checking Inventory Service (Python)...${NC} "
if curl -s http://localhost:9000/health | grep -q "healthy"; then
    echo -e "${GREEN}${CHECK} Running${NC}"
else
    echo -e "${RED}${CROSS} Not running${NC}"
    echo -e "${YELLOW}Please start the Inventory Service using: make run-inventory-service${NC}"
    exit 1
fi

# Check Analytics API
echo -ne "${CYAN}Checking Analytics API (Node.js)...${NC} "
if curl -s http://localhost:9300/health | grep -q "healthy"; then
    echo -e "${GREEN}${CHECK} Running${NC}"
else
    echo -e "${RED}${CROSS} Not running${NC}"
    echo -e "${YELLOW}Please start the Analytics API using: make run-analytics-api${NC}"
    exit 1
fi

# Check Schema Registry
echo -ne "${CYAN}Checking Schema Registry...${NC} "
if curl -s http://localhost:8081/subjects | grep -q ""; then
    echo -e "${GREEN}${CHECK} Running${NC}"
else
    echo -e "${RED}${CROSS} Not running${NC}"
    echo -e "${YELLOW}Please start Schema Registry using: make run-kafka${NC}"
    exit 1
fi

echo -e "\n${BLUE}${ROCKET} All services are running! Starting the demo...${NC}\n"

# Initialize step success flags
STEP1_ORDER_CREATION_SUCCESS=false
STEP2_INVENTORY_PROCESSING_SUCCESS=false
STEP3_ANALYTICS_PROCESSING_SUCCESS=false
STEP4_NO_NEW_ERRORS=true # Assume no new errors initially

# Get initial error counts BEFORE sending the order
INVENTORY_ERRORS=$(curl -s http://localhost:9000/errors | grep -o '"error_count":[0-9]*' | head -1 | cut -d':' -f2)
INVENTORY_ERRORS=${INVENTORY_ERRORS:-0}
ANALYTICS_ERRORS=$(curl -s http://localhost:9300/api/errors | grep -o '"errorCount":[0-9]*' | head -1 | cut -d':' -f2)
ANALYTICS_ERRORS=${ANALYTICS_ERRORS:-0}

# Create an order using Avro serialization
echo -e "${PURPLE}${WRENCH} Step 1: Creating an order using Avro serialization...${NC}"
ORDER_RESPONSE=$(curl -s -X POST http://localhost:9080/orders/avro -H "Content-Type: application/json" -d '{
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

ORDER_ID=$(echo $ORDER_RESPONSE | grep -o '"orderId":"[^"]*' | cut -d'"' -f4)

if [ -n "$ORDER_ID" ]; then
    echo -e "${GREEN}${CHECK} Order created successfully with ID: ${ORDER_ID}${NC}"
    STEP1_ORDER_CREATION_SUCCESS=true
else
    echo -e "${RED}${CROSS} Failed to create order${NC}"
    echo "Raw response from Order Service:"
    echo $ORDER_RESPONSE
    # Continue to summary, don't exit immediately
fi

# Wait for processing
echo -e "\n${YELLOW}Waiting for message propagation (12 seconds)...${NC}" # Increased wait time
sleep 12

# Check if the order was processed by the Inventory Service
echo -e "\n${PURPLE}${MAGNIFYING} Step 2: Checking if the order was processed by the Inventory Service...${NC}"
if [ "$STEP1_ORDER_CREATION_SUCCESS" = true ]; then
    INVENTORY_RESULT=$(curl -s "http://localhost:9000/inventory?source=avro")
    if echo "$INVENTORY_RESULT" | grep -q "$ORDER_ID"; then
        echo -e "${GREEN}${CHECK} Order found in Inventory Service using Avro deserialization!${NC}"
        echo -e "${CYAN}Raw Inventory Service response (source=avro):${NC}"
        echo "$INVENTORY_RESULT"
        STEP2_INVENTORY_PROCESSING_SUCCESS=true
    else
        echo -e "${RED}${CROSS} Order ID ($ORDER_ID) not found in Inventory Service (source=avro)${NC}"
        echo -e "${YELLOW}Raw Inventory Service response (source=avro):${NC}"
        echo "$INVENTORY_RESULT"
        echo -e "${YELLOW}This might indicate a deserialization issue or delay in processing.${NC}"
        echo -e "${YELLOW}Checking current errors in Inventory Service:${NC}"
        curl -s "http://localhost:9000/errors"
    fi
else
    echo -e "${YELLOW}Skipping Inventory Service check because order creation failed.${NC}"
fi

# Check if the order was processed by the Analytics API
echo -e "\n${PURPLE}${MAGNIFYING} Step 3: Checking if the order was processed by the Analytics API...${NC}"
if [ "$STEP1_ORDER_CREATION_SUCCESS" = true ]; then
    ANALYTICS_RESULT=$(curl -s "http://localhost:9300/api/messages/avro")
    if echo "$ANALYTICS_RESULT" | grep -q "$ORDER_ID"; then
        echo -e "${GREEN}${CHECK} Order found in Analytics API using Avro deserialization!${NC}"
        echo -e "${CYAN}Raw Analytics API response (messages/avro):${NC}"
        echo "$ANALYTICS_RESULT"
        STEP3_ANALYTICS_PROCESSING_SUCCESS=true
    else
        echo -e "${RED}${CROSS} Order ID ($ORDER_ID) not found in Analytics API (messages/avro)${NC}"
        echo -e "${YELLOW}Raw Analytics API response (messages/avro):${NC}"
        echo "$ANALYTICS_RESULT"
        echo -e "${YELLOW}Checking current errors in Analytics API:${NC}"
        curl -s "http://localhost:9300/api/errors"
    fi
else
    echo -e "${YELLOW}Skipping Analytics API check because order creation failed.${NC}"
fi

# Check for any new errors
NEW_INVENTORY_ERRORS=$(curl -s http://localhost:9000/errors | grep -o '"error_count":[0-9]*' | head -1 | cut -d':' -f2)
NEW_INVENTORY_ERRORS=${NEW_INVENTORY_ERRORS:-0}
NEW_ANALYTICS_ERRORS=$(curl -s http://localhost:9300/api/errors | grep -o '"errorCount":[0-9]*' | head -1 | cut -d':' -f2)
NEW_ANALYTICS_ERRORS=${NEW_ANALYTICS_ERRORS:-0}

INVENTORY_ERROR_DIFF=$((NEW_INVENTORY_ERRORS - INVENTORY_ERRORS))
ANALYTICS_ERROR_DIFF=$((NEW_ANALYTICS_ERRORS - ANALYTICS_ERRORS))

echo -e "\n${PURPLE}${MAGNIFYING} Step 4: Checking for deserialization errors...${NC}"
if [ "$INVENTORY_ERROR_DIFF" -gt 0 ]; then
    echo -e "${RED}${CROSS} Inventory Service reported ${INVENTORY_ERROR_DIFF} new errors during processing${NC}"
    STEP4_NO_NEW_ERRORS=false
else
    echo -e "${GREEN}${CHECK} No new errors in Inventory Service${NC}"
fi

if [ "$ANALYTICS_ERROR_DIFF" -gt 0 ]; then
    echo -e "${RED}${CROSS} Analytics API reported ${ANALYTICS_ERROR_DIFF} new errors during processing${NC}"
    STEP4_NO_NEW_ERRORS=false
else
    echo -e "${GREEN}${CHECK} No new errors in Analytics API${NC}"
fi

# Summary
echo -e "\n${BLUE}${CHART} Phase 4: Demo Summary${NC}"
echo -e "${CYAN}=====================================================${NC}"

FINAL_EXIT_CODE=0
if [ "$STEP1_ORDER_CREATION_SUCCESS" = true ] && \
   [ "$STEP2_INVENTORY_PROCESSING_SUCCESS" = true ] && \
   [ "$STEP3_ANALYTICS_PROCESSING_SUCCESS" = true ] && \
   [ "$STEP4_NO_NEW_ERRORS" = true ]; then
    echo -e "${GREEN}${CHECK} Schema Registry Integration with Avro is working perfectly!${NC}"
    echo -e "${GREEN}${CHECK} The same message was successfully processed by all three services:${NC}"
    echo -e "  - ${CYAN}Order Service (Java/Kotlin)${NC} - Created and serialized the order using Avro"
    echo -e "  - ${CYAN}Inventory Service (Python)${NC} - Deserialized the Avro message successfully"
    echo -e "  - ${CYAN}Analytics API (Node.js/TypeScript)${NC} - Deserialized the Avro message successfully"
    
    echo -e "\n${YELLOW}${BOOKS} The Schema Registry enabled cross-language serialization by:${NC}"
    echo -e "  1. Storing the Avro schema and providing it to all services"
    echo -e "  2. Adding schema ID to messages for version compatibility"
    echo -e "  3. Handling the binary encoding/decoding consistently across languages"
    echo -e "  4. Enforcing schema compatibility during evolution"
    
    echo -e "\n${GREEN}${ROCKET} Phase 4 Demo PASSED!${NC}"
else
    echo -e "${RED}${CROSS} Phase 4 Demo FAILED. Review step outputs above.${NC}"
    echo -e "Status:"
    echo -e "  Step 1 (Order Creation):         $(if [ "$STEP1_ORDER_CREATION_SUCCESS" = true ]; then echo -e "${GREEN}PASSED${NC}"; else echo -e "${RED}FAILED${NC}"; fi)"
    echo -e "  Step 2 (Inventory Processing):   $(if [ "$STEP2_INVENTORY_PROCESSING_SUCCESS" = true ]; then echo -e "${GREEN}PASSED${NC}"; else echo -e "${RED}FAILED${NC}"; fi)"
    echo -e "  Step 3 (Analytics Processing): $(if [ "$STEP3_ANALYTICS_PROCESSING_SUCCESS" = true ]; then echo -e "${GREEN}PASSED${NC}"; else echo -e "${RED}FAILED${NC}"; fi)"
    echo -e "  Step 4 (No New Errors):        $(if [ "$STEP4_NO_NEW_ERRORS" = true ]; then echo -e "${GREEN}PASSED${NC}"; else echo -e "${RED}FAILED${NC}"; fi)"
    echo -e "${YELLOW}Please check the error logs for each service and script output to troubleshoot.${NC}"
    FINAL_EXIT_CODE=1
fi

echo -e "${CYAN}=====================================================${NC}"
exit $FINAL_EXIT_CODE
