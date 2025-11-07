#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧹 Cleaning up Schema Registry subjects...${NC}"

# Get list of subjects
SUBJECTS=$(curl -s http://localhost:8081/subjects | jq -r '.[]')

if [ -z "$SUBJECTS" ]; then
    echo -e "${GREEN}✅ No subjects to clean up${NC}"
else
    echo -e "${YELLOW}Found subjects to delete:${NC}"
    echo "$SUBJECTS"
    
    # Delete each subject
    for subject in $SUBJECTS; do
        echo -e "${YELLOW}Deleting subject: $subject${NC}"
        curl -X DELETE "http://localhost:8081/subjects/$subject"
        echo ""
    done
    
    echo -e "${GREEN}✅ Subjects deleted successfully${NC}"
fi

echo -e "${GREEN}🎉 Schema Registry cleanup complete!${NC}"
