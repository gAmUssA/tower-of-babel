#!/bin/bash

# Demo 4: Prevented Disasters - Breaking Changes Blocked
# This demonstrates how Schema Registry prevents incompatible schema changes

# Set colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛡️  Demo 4: Prevented Disasters - Breaking Changes Blocked${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo -e "${YELLOW}This demo shows how Schema Registry prevents incompatible${NC}"
echo -e "${YELLOW}schema changes that would break existing consumers.${NC}"
echo -e "${CYAN}=====================================================${NC}\n"

# Check if Schema Registry is running
echo -e "${BLUE}🔍 Checking if Schema Registry is running...${NC}"
if ! curl -s http://localhost:8081/subjects > /dev/null 2>&1; then
  echo -e "${RED}❌ Schema Registry is not running. Please start it first.${NC}"
  echo -e "${YELLOW}Run: make run-kafka${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Schema Registry is running${NC}\n"

SUBJECT="orders-value"

# Check if schema exists
echo -e "${BLUE}📋 Step 1: Checking current schema...${NC}"
VERSIONS=$(curl -s http://localhost:8081/subjects/$SUBJECT/versions)
if ! echo "$VERSIONS" | grep -q '\['; then
    echo -e "${YELLOW}⚠️  No schema registered yet. Registering v1 first...${NC}"
    
    if [ -f "schemas/v1/order-event.avsc" ]; then
        SCHEMA_JSON=$(cat schemas/v1/order-event.avsc | jq -c tostring)
        curl -s -X POST \
            -H "Content-Type: application/vnd.schemaregistry.v1+json" \
            --data "{\"schema\":$SCHEMA_JSON}" \
            http://localhost:8081/subjects/$SUBJECT/versions > /dev/null
        echo -e "${GREEN}✅ Schema v1 registered${NC}"
    else
        echo -e "${RED}❌ Schema file not found: schemas/v1/order-event.avsc${NC}"
        exit 1
    fi
fi

LATEST_VERSION=$(curl -s http://localhost:8081/subjects/$SUBJECT/versions/latest | jq -r '.version')
echo -e "${GREEN}✅ Current schema version: $LATEST_VERSION${NC}"

echo -e "${CYAN}Current schema fields:${NC}"
curl -s http://localhost:8081/subjects/$SUBJECT/versions/latest | jq -r '.schema' | jq -r '.fields[] | "  • \(.name) (\(.type))"'

echo ""

# Test 1: Remove a required field
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}🧪 Test 1: Attempting to remove required field 'userId'${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Create a breaking schema (remove userId field)
BREAKING_SCHEMA_1=$(cat <<'EOF'
{
  "type": "record",
  "name": "OrderEvent",
  "namespace": "com.example.orders",
  "fields": [
    {"name": "orderId", "type": "string"},
    {"name": "amount", "type": "double"},
    {"name": "timestamp", "type": "long"},
    {"name": "items", "type": {
      "type": "array",
      "items": {
        "type": "record",
        "name": "OrderItem",
        "fields": [
          {"name": "productId", "type": "string"},
          {"name": "quantity", "type": "int"},
          {"name": "price", "type": "double"}
        ]
      }
    }}
  ]
}
EOF
)

echo -e "${YELLOW}Proposed change: Remove 'userId' field${NC}"
echo -e "${RED}Expected result: REJECTED (breaks backward compatibility)${NC}\n"

BREAKING_SCHEMA_1_JSON=$(echo "$BREAKING_SCHEMA_1" | jq -c tostring)
COMPAT_RESPONSE_1=$(curl -s -X POST \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data "{\"schema\":$BREAKING_SCHEMA_1_JSON}" \
    http://localhost:8081/compatibility/subjects/$SUBJECT/versions/latest)

IS_COMPATIBLE_1=$(echo "$COMPAT_RESPONSE_1" | jq -r '.is_compatible')

if [ "$IS_COMPATIBLE_1" = "false" ]; then
    echo -e "${GREEN}✅ Schema Registry BLOCKED the breaking change!${NC}"
    echo -e "${CYAN}Reason:${NC}"
    echo "$COMPAT_RESPONSE_1" | jq -r '.messages[]? // "Removing required field breaks backward compatibility"'
    echo ""
else
    echo -e "${RED}❌ Unexpected: Schema was marked as compatible${NC}"
    echo "$COMPAT_RESPONSE_1" | jq .
fi

echo ""

# Test 2: Change field type
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}🧪 Test 2: Attempting to change 'amount' type (double → string)${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

BREAKING_SCHEMA_2=$(cat <<'EOF'
{
  "type": "record",
  "name": "OrderEvent",
  "namespace": "com.example.orders",
  "fields": [
    {"name": "orderId", "type": "string"},
    {"name": "userId", "type": "string"},
    {"name": "amount", "type": "string"},
    {"name": "timestamp", "type": "long"},
    {"name": "items", "type": {
      "type": "array",
      "items": {
        "type": "record",
        "name": "OrderItem",
        "fields": [
          {"name": "productId", "type": "string"},
          {"name": "quantity", "type": "int"},
          {"name": "price", "type": "double"}
        ]
      }
    }}
  ]
}
EOF
)

echo -e "${YELLOW}Proposed change: Change 'amount' from double to string${NC}"
echo -e "${RED}Expected result: REJECTED (incompatible type change)${NC}\n"

BREAKING_SCHEMA_2_JSON=$(echo "$BREAKING_SCHEMA_2" | jq -c tostring)
COMPAT_RESPONSE_2=$(curl -s -X POST \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data "{\"schema\":$BREAKING_SCHEMA_2_JSON}" \
    http://localhost:8081/compatibility/subjects/$SUBJECT/versions/latest)

IS_COMPATIBLE_2=$(echo "$COMPAT_RESPONSE_2" | jq -r '.is_compatible')

if [ "$IS_COMPATIBLE_2" = "false" ]; then
    echo -e "${GREEN}✅ Schema Registry BLOCKED the breaking change!${NC}"
    echo -e "${CYAN}Reason:${NC}"
    echo "$COMPAT_RESPONSE_2" | jq -r '.messages[]? // "Type change is not compatible"'
    echo ""
else
    echo -e "${RED}❌ Unexpected: Schema was marked as compatible${NC}"
    echo "$COMPAT_RESPONSE_2" | jq .
fi

echo ""

# Test 3: Rename a field
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}🧪 Test 3: Attempting to rename field 'orderId' → 'id'${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

BREAKING_SCHEMA_3=$(cat <<'EOF'
{
  "type": "record",
  "name": "OrderEvent",
  "namespace": "com.example.orders",
  "fields": [
    {"name": "id", "type": "string"},
    {"name": "userId", "type": "string"},
    {"name": "amount", "type": "double"},
    {"name": "timestamp", "type": "long"},
    {"name": "items", "type": {
      "type": "array",
      "items": {
        "type": "record",
        "name": "OrderItem",
        "fields": [
          {"name": "productId", "type": "string"},
          {"name": "quantity", "type": "int"},
          {"name": "price", "type": "double"}
        ]
      }
    }}
  ]
}
EOF
)

echo -e "${YELLOW}Proposed change: Rename 'orderId' to 'id'${NC}"
echo -e "${RED}Expected result: REJECTED (field removal + addition)${NC}\n"

BREAKING_SCHEMA_3_JSON=$(echo "$BREAKING_SCHEMA_3" | jq -c tostring)
COMPAT_RESPONSE_3=$(curl -s -X POST \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data "{\"schema\":$BREAKING_SCHEMA_3_JSON}" \
    http://localhost:8081/compatibility/subjects/$SUBJECT/versions/latest)

IS_COMPATIBLE_3=$(echo "$COMPAT_RESPONSE_3" | jq -r '.is_compatible')

if [ "$IS_COMPATIBLE_3" = "false" ]; then
    echo -e "${GREEN}✅ Schema Registry BLOCKED the breaking change!${NC}"
    echo -e "${CYAN}Reason:${NC}"
    echo "$COMPAT_RESPONSE_3" | jq -r '.messages[]? // "Field rename breaks backward compatibility"'
    echo ""
else
    echo -e "${RED}❌ Unexpected: Schema was marked as compatible${NC}"
    echo "$COMPAT_RESPONSE_3" | jq .
fi

echo ""

# Show compatibility mode
echo -e "${BLUE}📋 Current compatibility mode:${NC}"
COMPAT_CONFIG=$(curl -s http://localhost:8081/config/$SUBJECT)
if echo "$COMPAT_CONFIG" | jq -e '.compatibilityLevel' > /dev/null 2>&1; then
    COMPAT_LEVEL=$(echo "$COMPAT_CONFIG" | jq -r '.compatibilityLevel')
    echo -e "${CYAN}Subject compatibility: $COMPAT_LEVEL${NC}"
else
    GLOBAL_COMPAT=$(curl -s http://localhost:8081/config | jq -r '.compatibilityLevel')
    echo -e "${CYAN}Global compatibility: $GLOBAL_COMPAT${NC}"
fi

echo ""

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Demo 4 Summary: Prevented Disasters${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Schema Registry prevented breaking changes:${NC}"
echo -e "  ${RED}✗${NC} Removing required fields"
echo -e "  ${RED}✗${NC} Changing field types incompatibly"
echo -e "  ${RED}✗${NC} Renaming fields"
echo -e ""
echo -e "${CYAN}Protection mechanisms:${NC}"
echo -e "  ${BLUE}•${NC} Compatibility checks before registration"
echo -e "  ${BLUE}•${NC} Configurable compatibility modes (BACKWARD, FORWARD, FULL)"
echo -e "  ${BLUE}•${NC} Prevents production incidents from schema changes"
echo -e "  ${BLUE}•${NC} Enforces safe evolution practices"
echo -e ""
echo -e "${GREEN}Result: Your microservices are protected from schema disasters!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
