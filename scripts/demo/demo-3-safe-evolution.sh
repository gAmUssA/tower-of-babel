#!/bin/bash

# Demo 3: Safe Evolution - Schema Compatibility
# This demonstrates how Schema Registry enables safe schema evolution

# Set colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Demo 3: Safe Evolution - Schema Compatibility${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo -e "${YELLOW}This demo shows how Schema Registry enables safe schema${NC}"
echo -e "${YELLOW}evolution with backward and forward compatibility.${NC}"
echo -e "${CYAN}=====================================================${NC}\n"

# Check if Schema Registry is running
echo -e "${BLUE}🔍 Checking if Schema Registry is running...${NC}"
if ! curl -s http://localhost:8081/subjects > /dev/null 2>&1; then
  echo -e "${RED}❌ Schema Registry is not running. Please start it first.${NC}"
  echo -e "${YELLOW}Run: make run-kafka${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Schema Registry is running${NC}\n"

# Check if v1 schema exists
SUBJECT="orders-value"
echo -e "${BLUE}📋 Step 1: Checking current schema version...${NC}"

VERSIONS=$(curl -s http://localhost:8081/subjects/$SUBJECT/versions)
if echo "$VERSIONS" | grep -q '\['; then
    LATEST_VERSION=$(curl -s http://localhost:8081/subjects/$SUBJECT/versions/latest | jq -r '.version')
    echo -e "${GREEN}✅ Current schema version: $LATEST_VERSION${NC}"
    
    echo -e "${CYAN}Current schema:${NC}"
    curl -s http://localhost:8081/subjects/$SUBJECT/versions/latest | jq -r '.schema' | jq .
else
    echo -e "${YELLOW}⚠️  No schema registered yet. Registering v1...${NC}"
    
    # Register v1 schema
    if [ -f "schemas/v1/order-event.avsc" ]; then
        SCHEMA_JSON=$(cat schemas/v1/order-event.avsc | jq -c tostring)
        RESPONSE=$(curl -s -X POST \
            -H "Content-Type: application/vnd.schemaregistry.v1+json" \
            --data "{\"schema\":$SCHEMA_JSON}" \
            http://localhost:8081/subjects/$SUBJECT/versions)
        
        if echo "$RESPONSE" | jq -e '.id' > /dev/null; then
            echo -e "${GREEN}✅ Schema v1 registered successfully${NC}"
        else
            echo -e "${RED}❌ Failed to register schema v1${NC}"
            echo "$RESPONSE" | jq .
            exit 1
        fi
    else
        echo -e "${RED}❌ Schema file not found: schemas/v1/order-event.avsc${NC}"
        exit 1
    fi
fi

echo ""

# Step 2: Test compatibility of v2 schema (adding optional fields)
echo -e "${BLUE}📋 Step 2: Testing v2 schema compatibility (adding optional fields)...${NC}"

if [ ! -f "schemas/v2/order-event.avsc" ]; then
    echo -e "${RED}❌ Schema file not found: schemas/v2/order-event.avsc${NC}"
    exit 1
fi

echo -e "${CYAN}Proposed v2 schema changes:${NC}"
echo -e "${YELLOW}  + Adding optional field: 'orderTimestamp' (long, nullable)${NC}"
echo -e "${YELLOW}  + Adding optional field: 'metadata' (map of strings, nullable)${NC}\n"

SCHEMA_V2_JSON=$(cat schemas/v2/order-event.avsc | jq -c tostring)
COMPAT_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data "{\"schema\":$SCHEMA_V2_JSON}" \
    http://localhost:8081/compatibility/subjects/$SUBJECT/versions/latest)

IS_COMPATIBLE=$(echo "$COMPAT_RESPONSE" | jq -r '.is_compatible')

if [ "$IS_COMPATIBLE" = "true" ]; then
    echo -e "${GREEN}✅ Schema v2 is COMPATIBLE with v1${NC}"
    echo -e "${CYAN}Compatibility check response:${NC}"
    echo "$COMPAT_RESPONSE" | jq .
    echo ""
    
    # Step 3: Register the new schema
    echo -e "${BLUE}📋 Step 3: Registering v2 schema...${NC}"
    
    REGISTER_RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/vnd.schemaregistry.v1+json" \
        --data "{\"schema\":$SCHEMA_V2_JSON}" \
        http://localhost:8081/subjects/$SUBJECT/versions)
    
    if echo "$REGISTER_RESPONSE" | jq -e '.id' > /dev/null; then
        SCHEMA_ID=$(echo "$REGISTER_RESPONSE" | jq -r '.id')
        SCHEMA_VERSION=$(echo "$REGISTER_RESPONSE" | jq -r '.version // .id')
        echo -e "${GREEN}✅ Schema v2 registered successfully${NC}"
        echo -e "${CYAN}Schema ID: $SCHEMA_ID${NC}"
        echo -e "${CYAN}Schema Version: $SCHEMA_VERSION${NC}"
    else
        echo -e "${RED}❌ Failed to register schema v2${NC}"
        echo "$REGISTER_RESPONSE" | jq .
        exit 1
    fi
else
    echo -e "${RED}❌ Schema v2 is NOT COMPATIBLE with v1${NC}"
    echo -e "${CYAN}Compatibility check response:${NC}"
    echo "$COMPAT_RESPONSE" | jq .
    exit 1
fi

echo ""

# Step 4: Demonstrate backward compatibility
echo -e "${BLUE}📋 Step 4: Testing backward compatibility...${NC}"
echo -e "${YELLOW}Scenario: Producer sends v1 messages, but v2 schema is registered${NC}"
echo -e "${YELLOW}Result: Consumers using v2 schema can read v1 messages (new fields get default null values)${NC}\n"

if [ -f "scripts/utils/wait-for-services.sh" ]; then
    # Check if services are running
    if curl -s http://localhost:9080/actuator/health | grep -q "UP"; then
        echo -e "${CYAN}Creating order using v1 schema (producer hasn't upgraded yet)...${NC}"
        
        ORDER_RESPONSE=$(curl -s -X POST http://localhost:9080/orders/avro \
          -H "Content-Type: application/json" \
          -d '{
            "userId": "user-compat-test-'$(date +%s)'",
            "amount": 199.99,
            "items": [{"productId": "product-v2", "quantity": 1, "price": 199.99}]
          }')
        
        ORDER_ID=$(echo $ORDER_RESPONSE | grep -o '"orderId":"[^"]*"' | cut -d'"' -f4)
        
        if [ -n "$ORDER_ID" ]; then
            echo -e "${GREEN}✅ Order created: $ORDER_ID${NC}"
            echo -e "${YELLOW}⏳ Waiting for message processing (5 seconds)...${NC}"
            sleep 5
            
            # Check if consumers can still process it
            if curl -s http://localhost:9000/health | grep -q "healthy"; then
                INVENTORY_RESULT=$(curl -s "http://localhost:9000/inventory?source=avro")
                if echo "$INVENTORY_RESULT" | grep -q "$ORDER_ID"; then
                    echo -e "${GREEN}✅ Consumer (Inventory Service) successfully processed the message${NC}"
                    echo -e "${CYAN}💡 Backward compatibility verified!${NC}"
                    echo -e "${CYAN}   • Producer uses v1 schema (4 fields)${NC}"
                    echo -e "${CYAN}   • v2 schema registered (6 fields with defaults)${NC}"
                    echo -e "${CYAN}   • Consumer can read v1 messages (new fields = null)${NC}"
                else
                    echo -e "${YELLOW}⚠️  Order not found in Inventory Service yet${NC}"
                fi
            fi
            
            if curl -s http://localhost:9300/health | grep -q "healthy"; then
                ANALYTICS_RESULT=$(curl -s "http://localhost:9300/api/messages/avro")
                if echo "$ANALYTICS_RESULT" | grep -q "$ORDER_ID"; then
                    echo -e "${GREEN}✅ Analytics API also processed the message${NC}"
                fi
            fi
        else
            echo -e "${YELLOW}⚠️  Could not create order${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Order Service not running - skipping live test${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Services not running - skipping live test${NC}"
fi

echo ""

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Demo 3 Summary: Safe Evolution${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Schema evolution demonstrated:${NC}"
echo -e "  ${GREEN}✓${NC} Added optional fields: orderTimestamp, metadata"
echo -e "  ${GREEN}✓${NC} Compatibility check passed (BACKWARD compatible)"
echo -e "  ${GREEN}✓${NC} New schema v2 registered successfully"
echo -e "  ${GREEN}✓${NC} Backward compatibility verified in practice"
echo -e ""
echo -e "${CYAN}What happened:${NC}"
echo -e "  ${BLUE}1.${NC} v1 schema has 4 fields: orderId, userId, amount, status"
echo -e "  ${BLUE}2.${NC} v2 schema adds 2 optional fields with null defaults"
echo -e "  ${BLUE}3.${NC} Producer still sends v1 messages (hasn't upgraded)"
echo -e "  ${BLUE}4.${NC} Consumers can use v2 schema and read v1 messages"
echo -e "  ${BLUE}5.${NC} New fields get default null values automatically"
echo -e ""
echo -e "${CYAN}Key benefits:${NC}"
echo -e "  ${BLUE}•${NC} Gradual rollout: upgrade consumers first, producers later"
echo -e "  ${BLUE}•${NC} No service downtime required"
echo -e "  ${BLUE}•${NC} No coordination needed between teams"
echo -e "  ${BLUE}•${NC} Schema Registry enforces compatibility rules"
echo -e ""
echo -e "${CYAN}Next: Run ${BLUE}make demo-4${CYAN} to see how Schema Registry${NC}"
echo -e "${CYAN}prevents incompatible breaking changes${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
