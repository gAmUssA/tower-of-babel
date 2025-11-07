#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧹 Cleaning up Kafka topics...${NC}"

# Get list of topics
TOPICS=$(docker-compose exec -T kafka kafka-topics --bootstrap-server kafka:9092 --list | grep -v "__consumer_offsets" | grep -v "_schemas")

if [ -z "$TOPICS" ]; then
    echo -e "${GREEN}✅ No application topics to clean up${NC}"
else
    echo -e "${YELLOW}Found topics to delete:${NC}"
    echo "$TOPICS"
    
    # Delete each topic
    for topic in $TOPICS; do
        echo -e "${YELLOW}Deleting topic: $topic${NC}"
        docker-compose exec -T kafka kafka-topics --bootstrap-server kafka:9092 --delete --topic "$topic"
    done
    
    echo -e "${GREEN}✅ Topics deleted successfully${NC}"
fi

echo -e "${GREEN}🎉 Topic cleanup complete!${NC}"
