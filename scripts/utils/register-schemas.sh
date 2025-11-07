#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}📋 Registering Avro schemas with Schema Registry...${NC}"

# Check if Schema Registry is available
if ! curl -s http://localhost:8081/subjects > /dev/null; then
    echo -e "${RED}❌ Schema Registry not available at localhost:8081${NC}"
    echo -e "${YELLOW}Please start Schema Registry with 'make setup' first${NC}"
    exit 1
fi

# Set global compatibility mode to FULL for comprehensive protection
echo -e "${YELLOW}🔧 Setting compatibility mode to FULL...${NC}"
COMPAT_RESPONSE=$(curl -s -X PUT \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data '{"compatibility":"FULL"}' \
    http://localhost:8081/config)

if echo "$COMPAT_RESPONSE" | jq -e '.compatibility' > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Compatibility mode set to FULL${NC}"
    echo -e "${YELLOW}   This ensures both backward and forward compatibility${NC}"
else
    echo -e "${YELLOW}⚠️  Could not set compatibility mode (may already be set)${NC}"
fi

# Function to register a schema
register_schema() {
    local schema_file=$1
    local subject=$2
    
    echo -e "${YELLOW}📋 Registering schema: $schema_file -> $subject${NC}"
    
    local response=$(curl -s -X POST \
        -H "Content-Type: application/vnd.schemaregistry.v1+json" \
        --data "{\"schema\":$(cat $schema_file | jq -c tostring)}" \
        http://localhost:8081/subjects/$subject/versions)
    
    if echo $response | jq -e '.id' > /dev/null; then
        local schema_id=$(echo $response | jq -r '.id')
        echo -e "${GREEN}✅ Schema registered successfully with ID: $schema_id${NC}"
    else
        echo -e "${RED}❌ Failed to register schema${NC}"
        echo $response | jq .
        return 1
    fi
}

# Register order event schema (V2 by default for demos)
echo -e "${YELLOW}Registering Order Event schema...${NC}"
register_schema "schemas/v2/order-event.avsc" "orders-value"

# Register user event schema
echo -e "${YELLOW}Registering User Event schema...${NC}"
register_schema "schemas/v1/user-event.avsc" "user-event-value"

# Register payment event schema
echo -e "${YELLOW}Registering Payment Event schema...${NC}"
register_schema "schemas/v1/payment-event.avsc" "payment-event-value"

# Show registered subjects
echo -e "${GREEN}📋 Currently registered subjects:${NC}"
curl -s http://localhost:8081/subjects | jq .

echo -e "${GREEN}🎉 Schema registration complete!${NC}"
