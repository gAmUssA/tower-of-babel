#!/bin/bash

# Test Suite 4: Compatibility Checks
# Automated tests for breaking change prevention

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🧪 Test Suite 4: Compatibility Checks${NC}"
echo -e "${CYAN}=====================================================${NC}\n"

TESTS_PASSED=0
TESTS_FAILED=0
SUBJECT="orders-value"

# Test 1: Removing required field should be rejected
echo -e "${CYAN}Test 1: Removing required field is rejected${NC}"

BREAKING_SCHEMA=$(cat <<'EOF'
{
  "type": "record",
  "name": "OrderEvent",
  "namespace": "com.company.orders",
  "fields": [
    {"name": "orderId", "type": "string"},
    {"name": "amount", "type": "double"},
    {"name": "status", "type": "string"}
  ]
}
EOF
)

BREAKING_SCHEMA_JSON=$(echo "$BREAKING_SCHEMA" | jq -c tostring)
COMPAT_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data "{\"schema\":$BREAKING_SCHEMA_JSON}" \
    http://localhost:8081/compatibility/subjects/$SUBJECT/versions/latest)

IS_COMPATIBLE=$(echo "$COMPAT_RESPONSE" | jq -r '.is_compatible')

if [ "$IS_COMPATIBLE" = "false" ]; then
    echo -e "${GREEN}✅ PASSED - Breaking change blocked${NC}\n"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}❌ FAILED - Breaking change not detected${NC}\n"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 2: Changing field type should be rejected
echo -e "${CYAN}Test 2: Changing field type is rejected${NC}"

TYPE_CHANGE_SCHEMA=$(cat <<'EOF'
{
  "type": "record",
  "name": "OrderEvent",
  "namespace": "com.company.orders",
  "fields": [
    {"name": "orderId", "type": "string"},
    {"name": "userId", "type": "string"},
    {"name": "amount", "type": "string"},
    {"name": "status", "type": "string"}
  ]
}
EOF
)

TYPE_CHANGE_JSON=$(echo "$TYPE_CHANGE_SCHEMA" | jq -c tostring)
COMPAT_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data "{\"schema\":$TYPE_CHANGE_JSON}" \
    http://localhost:8081/compatibility/subjects/$SUBJECT/versions/latest)

IS_COMPATIBLE=$(echo "$COMPAT_RESPONSE" | jq -r '.is_compatible')

if [ "$IS_COMPATIBLE" = "false" ]; then
    echo -e "${GREEN}✅ PASSED - Type change blocked${NC}\n"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}❌ FAILED - Type change not detected${NC}\n"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 3: Adding optional field should be allowed
echo -e "${CYAN}Test 3: Adding optional field is allowed${NC}"

if [ -f "schemas/v2/order-event.avsc" ]; then
    SCHEMA_V2_JSON=$(cat schemas/v2/order-event.avsc | jq -c tostring)
    COMPAT_RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/vnd.schemaregistry.v1+json" \
        --data "{\"schema\":$SCHEMA_V2_JSON}" \
        http://localhost:8081/compatibility/subjects/$SUBJECT/versions/latest)
    
    IS_COMPATIBLE=$(echo "$COMPAT_RESPONSE" | jq -r '.is_compatible')
    
    if [ "$IS_COMPATIBLE" = "true" ]; then
        echo -e "${GREEN}✅ PASSED - Optional field allowed${NC}\n"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAILED - Optional field rejected${NC}\n"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    echo -e "${YELLOW}⚠️  SKIPPED - v2 schema file not found${NC}\n"
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
