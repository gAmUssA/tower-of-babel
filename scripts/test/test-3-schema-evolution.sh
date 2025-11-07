#!/bin/bash

# Test Suite 3: Schema Evolution
# Automated tests for safe schema evolution

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🧪 Test Suite 3: Schema Evolution${NC}"
echo -e "${CYAN}=====================================================${NC}\n"

TESTS_PASSED=0
TESTS_FAILED=0
SUBJECT="orders-value"

# Test 1: v2 schema should be compatible with v1
echo -e "${CYAN}Test 1: v2 schema is compatible with v1${NC}"

if [ -f "schemas/v2/order-event.avsc" ]; then
    SCHEMA_V2_JSON=$(cat schemas/v2/order-event.avsc | jq -c tostring)
    COMPAT_RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/vnd.schemaregistry.v1+json" \
        --data "{\"schema\":$SCHEMA_V2_JSON}" \
        http://localhost:8081/compatibility/subjects/$SUBJECT/versions/latest)
    
    IS_COMPATIBLE=$(echo "$COMPAT_RESPONSE" | jq -r '.is_compatible')
    
    if [ "$IS_COMPATIBLE" = "true" ]; then
        echo -e "${GREEN}✅ PASSED${NC}\n"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAILED - Schema not compatible${NC}"
        echo "$COMPAT_RESPONSE" | jq .
        echo ""
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    echo -e "${YELLOW}⚠️  SKIPPED - v2 schema file not found${NC}\n"
fi

# Test 2: v2 schema can be registered
echo -e "${CYAN}Test 2: v2 schema can be registered${NC}"

if [ -f "schemas/v2/order-event.avsc" ]; then
    SCHEMA_V2_JSON=$(cat schemas/v2/order-event.avsc | jq -c tostring)
    REGISTER_RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/vnd.schemaregistry.v1+json" \
        --data "{\"schema\":$SCHEMA_V2_JSON}" \
        http://localhost:8081/subjects/$SUBJECT/versions)
    
    if echo "$REGISTER_RESPONSE" | jq -e '.id' > /dev/null; then
        echo -e "${GREEN}✅ PASSED${NC}\n"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAILED - Could not register schema${NC}"
        echo "$REGISTER_RESPONSE" | jq .
        echo ""
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    echo -e "${YELLOW}⚠️  SKIPPED - v2 schema file not found${NC}\n"
fi

# Test 3: Multiple versions should exist
echo -e "${CYAN}Test 3: Multiple schema versions exist${NC}"

VERSIONS=$(curl -s http://localhost:8081/subjects/$SUBJECT/versions)
VERSION_COUNT=$(echo "$VERSIONS" | jq '. | length')

if [ "$VERSION_COUNT" -ge 2 ]; then
    echo -e "${GREEN}✅ PASSED - Found $VERSION_COUNT versions${NC}\n"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${YELLOW}⚠️  PARTIAL - Only $VERSION_COUNT version(s) found${NC}\n"
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
