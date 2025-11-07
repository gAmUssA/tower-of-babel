#!/bin/bash

# Test Suite 1: Serialization Failures
# Automated tests for Tower of Babel scenarios

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🧪 Test Suite 1: Serialization Failures${NC}"
echo -e "${CYAN}=====================================================${NC}\n"

TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: Java serialization should cause errors
echo -e "${CYAN}Test 1: Java serialization causes deserialization errors${NC}"
INITIAL_ERRORS=$(curl -s http://localhost:9000/errors | grep -o '"error_count":[0-9]*' | head -1 | cut -d':' -f2)
INITIAL_ERRORS=${INITIAL_ERRORS:-0}

curl -s -X POST http://localhost:9080/orders/broken \
  -H "Content-Type: application/json" \
  -d '{"userId":"test","amount":99.99,"items":[{"productId":"p1","quantity":1,"price":99.99}]}' > /dev/null

sleep 3

NEW_ERRORS=$(curl -s http://localhost:9000/errors | grep -o '"error_count":[0-9]*' | head -1 | cut -d':' -f2)
NEW_ERRORS=${NEW_ERRORS:-0}

if [ "$NEW_ERRORS" -gt "$INITIAL_ERRORS" ]; then
    echo -e "${GREEN}✅ PASSED${NC}\n"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}❌ FAILED${NC}\n"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 2: JSON field names should work with guessing
echo -e "${CYAN}Test 2: JSON field names work with name guessing${NC}"
ORDER_RESPONSE=$(curl -s -X POST http://localhost:9080/orders \
  -H "Content-Type: application/json" \
  -d '{"userId":"test-json","amount":149.99,"items":[{"productId":"p2","quantity":2,"price":74.99}]}')

ORDER_ID=$(echo $ORDER_RESPONSE | grep -o '"orderId":"[^"]*"' | cut -d'"' -f4)
sleep 3

if [ -n "$ORDER_ID" ]; then
    INVENTORY_RESULT=$(curl -s "http://localhost:9000/inventory/$ORDER_ID")
    if echo "$INVENTORY_RESULT" | grep -q "RESERVED"; then
        echo -e "${GREEN}✅ PASSED${NC}\n"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAILED${NC}\n"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    echo -e "${RED}❌ FAILED - Could not create order${NC}\n"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Test Results:${NC}"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ "$TESTS_FAILED" -eq 0 ]; then
    exit 0
else
    exit 1
fi
