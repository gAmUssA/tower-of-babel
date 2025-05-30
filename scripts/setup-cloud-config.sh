#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}☁️ Setting up Confluent Cloud configuration...${NC}"

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file from template...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}⚠️ Please edit .env file with your Confluent Cloud credentials${NC}"
    echo -e "${YELLOW}⚠️ Uncomment and fill in the CONFLUENT_CLOUD_* variables${NC}"
    exit 1
fi

# Check if required environment variables are set
grep -q "^CONFLUENT_CLOUD_BOOTSTRAP_SERVERS=" .env
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ CONFLUENT_CLOUD_BOOTSTRAP_SERVERS not configured in .env file${NC}"
    echo -e "${YELLOW}⚠️ Please uncomment and set Confluent Cloud variables in .env file${NC}"
    exit 1
fi

grep -q "^CONFLUENT_CLOUD_API_KEY=" .env
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ CONFLUENT_CLOUD_API_KEY not configured in .env file${NC}"
    echo -e "${YELLOW}⚠️ Please uncomment and set Confluent Cloud variables in .env file${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Confluent Cloud configuration found in .env file${NC}"
echo -e "${YELLOW}Starting services with Confluent Cloud configuration...${NC}"

# Set DEMO_MODE to cloud
sed -i '' 's/^DEMO_MODE=.*/DEMO_MODE=cloud/' .env

# Start docker-compose with cloud configuration
docker-compose -f docker-compose.cloud.yml up -d

echo -e "${GREEN}✅ Cloud configuration ready!${NC}"
echo -e "${GREEN}📊 Kafka UI: http://localhost:8080${NC}"
echo -e "${GREEN}🔗 Using Confluent Cloud for Kafka and Schema Registry${NC}"
