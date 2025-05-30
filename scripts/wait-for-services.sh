#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}⏳ Waiting for services to start...${NC}"

# Function to check if a service is ready
wait_for_service() {
    local service_name=$1
    local health_check_cmd=$2
    local max_attempts=30
    local attempt=1
    
    echo -e "${YELLOW}Checking ${service_name}...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if eval "$health_check_cmd" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ ${service_name} is ready!${NC}"
            return 0
        fi
        
        echo -e "${YELLOW}⏳ Attempt $attempt/$max_attempts - ${service_name} not ready yet...${NC}"
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}❌ ${service_name} failed to start after $max_attempts attempts${NC}"
    return 1
}

# Wait for Kafka
wait_for_service "Kafka" "docker-compose exec -T kafka kafka-topics --bootstrap-server kafka:9092 --list"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Kafka startup failed${NC}"
    exit 1
fi

# Wait for Schema Registry
wait_for_service "Schema Registry" "curl -f http://localhost:8081/subjects"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Schema Registry startup failed${NC}"
    exit 1
fi

# Wait for Kafka UI
wait_for_service "Kafka UI" "curl -f http://localhost:8080"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Kafka UI startup failed${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 All services are ready!${NC}"
echo -e "${GREEN}📊 Kafka UI: http://localhost:8080${NC}"
echo -e "${GREEN}📝 Schema Registry: http://localhost:8081${NC}"
echo -e "${GREEN}🔗 Kafka Bootstrap: localhost:29092${NC}"
