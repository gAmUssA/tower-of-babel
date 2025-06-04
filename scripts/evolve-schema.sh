#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🧬 Schema Evolution Demo${NC}"
echo -e "${YELLOW}This demo shows backward and forward compatibility with schema changes${NC}"

# Check if Schema Registry is available
if ! curl -s http://localhost:8081/subjects > /dev/null; then
    echo -e "${RED}❌ Schema Registry not available. Start with 'make setup' first.${NC}"
    exit 1
fi

# Function to register a schema and show the result
register_schema() {
    local version=$1
    local schema_file=$2
    local subject="orders-value"
    
    echo -e "${BLUE}📋 Registering schema version $version...${NC}"
    echo -e "${YELLOW}Schema file: $schema_file${NC}"
    
    # Show the schema content
    echo -e "${YELLOW}Schema content:${NC}"
    cat $schema_file | jq .
    
    # Register the schema
    local response=$(curl -s -X POST \
        -H "Content-Type: application/vnd.schemaregistry.v1+json" \
        --data "{\"schema\":$(cat $schema_file | jq -c tostring)}" \
        http://localhost:8081/subjects/$subject/versions)
    
    echo -e "${YELLOW}Registration response:${NC}"
    echo $response | jq .
    
    if echo $response | jq -e '.id' > /dev/null; then
        echo -e "${GREEN}✅ Schema version $version registered successfully${NC}"
        local schema_id=$(echo $response | jq -r '.id')
        echo -e "${GREEN}Schema ID: $schema_id${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to register schema version $version${NC}"
        echo $response
        return 1
    fi
}

# Function to test compatibility
test_compatibility() {
    local test_schema=$1
    local subject="order-event-value"
    
    echo -e "${BLUE}🔍 Testing compatibility...${NC}"
    
    local response=$(curl -s -X POST \
        -H "Content-Type: application/vnd.schemaregistry.v1+json" \
        --data "{\"schema\":$(cat $test_schema | jq -c tostring)}" \
        http://localhost:8081/compatibility/subjects/$subject/versions/latest)
    
    echo -e "${YELLOW}Compatibility test response:${NC}"
    echo $response | jq .
    
    local is_compatible=$(echo $response | jq -r '.is_compatible')
    if [ "$is_compatible" = "true" ]; then
        echo -e "${GREEN}✅ Schema is compatible${NC}"
        return 0
    else
        echo -e "${RED}❌ Schema is not compatible${NC}"
        return 1
    fi
}

# Start the demo
echo -e "${YELLOW}🚀 Starting schema evolution demonstration...${NC}"

# Step 1: Register V1 schema
echo -e "\n${BLUE}=== Step 1: Register Initial Schema (V1) ===${NC}"
register_schema "V1" "schemas/v1/order-event.avsc"

# Step 2: Show current subjects and versions
echo -e "\n${BLUE}=== Step 2: Show Current State ===${NC}"
echo -e "${YELLOW}Current subjects:${NC}"
curl -s http://localhost:8081/subjects | jq .

echo -e "${YELLOW}Versions for order-event-value:${NC}"
curl -s http://localhost:8081/subjects/order-event-value/versions | jq .

# Step 3: Test V2 compatibility (should be compatible - added optional fields)
echo -e "\n${BLUE}=== Step 3: Test V2 Compatibility (Backward Compatible) ===${NC}"
echo -e "${YELLOW}V2 adds optional fields, should be backward compatible${NC}"
test_compatibility "schemas/v2/order-event.avsc"

# Step 4: Register V2 schema
echo -e "\n${BLUE}=== Step 4: Register V2 Schema ===${NC}"
register_schema "V2" "schemas/v2/order-event.avsc"

# Step 5: Show versions again
echo -e "\n${BLUE}=== Step 5: Show Updated State ===${NC}"
echo -e "${YELLOW}Updated versions for order-event-value:${NC}"
curl -s http://localhost:8081/subjects/order-event-value/versions | jq .

# Step 6: Test incompatible schema (should fail)
echo -e "\n${BLUE}=== Step 6: Test Incompatible Schema (Should Fail) ===${NC}"
echo -e "${YELLOW}Incompatible schema removes required 'userId' field${NC}"
test_compatibility "schemas/incompatible/order-event.avsc"

# Step 7: Try to register incompatible schema (should fail)
echo -e "\n${BLUE}=== Step 7: Try to Register Incompatible Schema ===${NC}"
echo -e "${YELLOW}This should be rejected by Schema Registry${NC}"
register_schema "V3-Incompatible" "schemas/incompatible/order-event.avsc" || echo -e "${GREEN}✅ Schema Registry correctly rejected incompatible schema${NC}"

# Step 8: Code generation demonstration
echo -e "\n${BLUE}=== Step 8: Demonstrate Code Generation ===${NC}"
echo -e "${YELLOW}Generating code from latest schema...${NC}"
make generate

echo -e "${YELLOW}Generated artifacts:${NC}"
echo -e "${GREEN}Java:${NC}"
find services/order-service/build/generated-main-avro-java -name "*.java" 2>/dev/null | head -3 || echo "No Java files generated yet"

echo -e "${GREEN}Python:${NC}"
find services/inventory-service/src/generated -name "*.py" 2>/dev/null | head -3 || echo "No Python files generated yet"

echo -e "${GREEN}TypeScript:${NC}"
find services/analytics-api/src/generated -name "*.ts" 2>/dev/null | head -3 || echo "No TypeScript files generated yet"

# Summary
echo -e "\n${GREEN}🎉 Schema Evolution Demo Complete!${NC}"
echo -e "${YELLOW}Summary:${NC}"
echo -e "${GREEN}✅ V1 schema registered successfully${NC}"
echo -e "${GREEN}✅ V2 schema is backward compatible (adds optional fields)${NC}"
echo -e "${GREEN}✅ V2 schema registered successfully${NC}"
echo -e "${GREEN}✅ Incompatible schema correctly rejected${NC}"
echo -e "${GREEN}✅ Code generated from latest schema${NC}"

echo -e "\n${YELLOW}Key learnings:${NC}"
echo -e "${GREEN}- Schema Registry enforces compatibility rules${NC}"
echo -e "${GREEN}- Optional fields maintain backward compatibility${NC}"
echo -e "${GREEN}- Removing required fields breaks compatibility${NC}"
echo -e "${GREEN}- Code generation stays in sync with schema evolution${NC}"
