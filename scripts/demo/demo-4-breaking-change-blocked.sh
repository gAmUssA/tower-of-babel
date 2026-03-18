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

# Interactive mode support
INTERACTIVE=false
for arg in "$@"; do
  case "$arg" in
    -i|--interactive) INTERACTIVE=true ;;
  esac
done

pause() {
  if [ "$INTERACTIVE" = true ]; then
    echo ""
    read -r -p "  Press Enter to continue..."
    echo ""
  fi
}

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

# Ensure BACKWARD compatibility is enforced for this demo
echo -e "${BLUE}🔒 Ensuring BACKWARD compatibility mode is set...${NC}"
curl -s -X PUT -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data '{"compatibility": "BACKWARD"}' \
    http://localhost:8081/config/$SUBJECT > /dev/null
echo -e "${GREEN}✅ BACKWARD compatibility mode set${NC}\n"

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
  "namespace": "com.company.orders",
  "fields": [
    {"name": "orderId", "type": "string"},
    {"name": "amount", "type": "double"},
    {"name": "status", "type": "string"}
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
    echo -e "${GREEN}✅ Compatibility check: REJECTED${NC}"
    echo -e "${CYAN}Reason:${NC}"
    echo "$COMPAT_RESPONSE_1" | jq -r '.messages[]? // "Removing required field breaks backward compatibility"'
    echo ""
    
    # Now try to actually register it (this should fail)
    echo -e "${YELLOW}⚠️  Now attempting to FORCE register the breaking schema...${NC}"
    REGISTER_RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/vnd.schemaregistry.v1+json" \
        --data "{\"schema\":$BREAKING_SCHEMA_1_JSON}" \
        http://localhost:8081/subjects/$SUBJECT/versions)
    
    if echo "$REGISTER_RESPONSE" | jq -e '.error_code' > /dev/null 2>&1; then
        ERROR_CODE=$(echo "$REGISTER_RESPONSE" | jq -r '.error_code')
        ERROR_MSG=$(echo "$REGISTER_RESPONSE" | jq -r '.message')
        echo -e "${GREEN}✅ Registration BLOCKED by Schema Registry!${NC}"
        echo -e "${RED}Error $ERROR_CODE: $ERROR_MSG${NC}"
    else
        echo -e "${RED}❌ Unexpected: Schema was registered!${NC}"
        echo "$REGISTER_RESPONSE" | jq .
    fi
else
    echo -e "${RED}❌ Unexpected: Schema was marked as compatible${NC}"
    echo "$COMPAT_RESPONSE_1" | jq .
fi

echo ""
pause

# Test 2: Change field type
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}🧪 Test 2: Attempting to change 'amount' type (double → string)${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

BREAKING_SCHEMA_2=$(cat <<'EOF'
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

echo -e "${YELLOW}Proposed change: Change 'amount' from double to string${NC}"
echo -e "${RED}Expected result: REJECTED (incompatible type change)${NC}\n"

BREAKING_SCHEMA_2_JSON=$(echo "$BREAKING_SCHEMA_2" | jq -c tostring)
COMPAT_RESPONSE_2=$(curl -s -X POST \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data "{\"schema\":$BREAKING_SCHEMA_2_JSON}" \
    http://localhost:8081/compatibility/subjects/$SUBJECT/versions/latest)

IS_COMPATIBLE_2=$(echo "$COMPAT_RESPONSE_2" | jq -r '.is_compatible')

if [ "$IS_COMPATIBLE_2" = "false" ]; then
    echo -e "${GREEN}✅ Compatibility check: REJECTED${NC}"
    echo -e "${CYAN}Reason:${NC}"
    echo "$COMPAT_RESPONSE_2" | jq -r '.messages[]? // "Type change is not compatible"'
    echo ""
    
    # Try to register it
    echo -e "${YELLOW}⚠️  Now attempting to FORCE register the breaking schema...${NC}"
    REGISTER_RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/vnd.schemaregistry.v1+json" \
        --data "{\"schema\":$BREAKING_SCHEMA_2_JSON}" \
        http://localhost:8081/subjects/$SUBJECT/versions)
    
    if echo "$REGISTER_RESPONSE" | jq -e '.error_code' > /dev/null 2>&1; then
        ERROR_CODE=$(echo "$REGISTER_RESPONSE" | jq -r '.error_code')
        ERROR_MSG=$(echo "$REGISTER_RESPONSE" | jq -r '.message')
        echo -e "${GREEN}✅ Registration BLOCKED by Schema Registry!${NC}"
        echo -e "${RED}Error $ERROR_CODE: $ERROR_MSG${NC}"
    else
        echo -e "${RED}❌ Unexpected: Schema was registered!${NC}"
        echo "$REGISTER_RESPONSE" | jq .
    fi
else
    echo -e "${RED}❌ Unexpected: Schema was marked as compatible${NC}"
    echo "$COMPAT_RESPONSE_2" | jq .
fi

echo ""
pause

# Test 3: Rename a field
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}🧪 Test 3: Attempting to rename field 'orderId' → 'id'${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

BREAKING_SCHEMA_3=$(cat <<'EOF'
{
  "type": "record",
  "name": "OrderEvent",
  "namespace": "com.company.orders",
  "fields": [
    {"name": "id", "type": "string"},
    {"name": "userId", "type": "string"},
    {"name": "amount", "type": "double"},
    {"name": "status", "type": "string"}
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
    echo -e "${GREEN}✅ Compatibility check: REJECTED${NC}"
    echo -e "${CYAN}Reason:${NC}"
    echo "$COMPAT_RESPONSE_3" | jq -r '.messages[]? // "Field rename breaks backward compatibility"'
    echo ""
    
    # Try to register it
    echo -e "${YELLOW}⚠️  Now attempting to FORCE register the breaking schema...${NC}"
    REGISTER_RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/vnd.schemaregistry.v1+json" \
        --data "{\"schema\":$BREAKING_SCHEMA_3_JSON}" \
        http://localhost:8081/subjects/$SUBJECT/versions)
    
    if echo "$REGISTER_RESPONSE" | jq -e '.error_code' > /dev/null 2>&1; then
        ERROR_CODE=$(echo "$REGISTER_RESPONSE" | jq -r '.error_code')
        ERROR_MSG=$(echo "$REGISTER_RESPONSE" | jq -r '.message')
        echo -e "${GREEN}✅ Registration BLOCKED by Schema Registry!${NC}"
        echo -e "${RED}Error $ERROR_CODE: $ERROR_MSG${NC}"
    else
        echo -e "${RED}❌ Unexpected: Schema was registered!${NC}"
        echo "$REGISTER_RESPONSE" | jq .
    fi
else
    echo -e "${RED}❌ Unexpected: Schema was marked as compatible${NC}"
    echo "$COMPAT_RESPONSE_3" | jq .
fi

echo ""
pause

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
echo -e "${GREEN}✅ Schema Registry BLOCKED all breaking changes:${NC}"
echo -e "  ${RED}✗${NC} Removing required fields → Registration FAILED"
echo -e "  ${RED}✗${NC} Changing field types incompatibly → Registration FAILED"
echo -e "  ${RED}✗${NC} Renaming fields → Registration FAILED"
echo -e ""
echo -e "${CYAN}How it works:${NC}"
echo -e "  ${BLUE}1.${NC} Developer tries to register new schema"
echo -e "  ${BLUE}2.${NC} Schema Registry checks compatibility with existing versions"
echo -e "  ${BLUE}3.${NC} If incompatible, registration is REJECTED with error"
echo -e "  ${BLUE}4.${NC} Producer cannot use the breaking schema"
echo -e "  ${BLUE}5.${NC} Existing consumers continue working safely"
echo -e ""
echo -e "${CYAN}Protection mechanisms:${NC}"
echo -e "  ${BLUE}•${NC} Automatic compatibility validation on registration"
echo -e "  ${BLUE}•${NC} Configurable compatibility modes (BACKWARD, FORWARD, FULL)"
echo -e "  ${BLUE}•${NC} Prevents production incidents from schema changes"
echo -e "  ${BLUE}•${NC} Forces developers to use safe evolution patterns"
echo -e ""
echo -e "${GREEN}Result: Breaking changes are impossible - your microservices are protected!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
