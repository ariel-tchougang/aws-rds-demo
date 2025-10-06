#!/bin/bash
# Mission DB007 - RDS Status Check

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Mission DB007 - RDS Status${NC}"
echo "=============================="

# Load environment
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

RDS_INSTANCE_ID=${RDS_INSTANCE_ID:-"db007-mission-postgres"}

# Check RDS instance
if ! aws rds describe-db-instances --db-instance-identifier "$RDS_INSTANCE_ID" >/dev/null 2>&1; then
    echo -e "${RED}❌ RDS instance '$RDS_INSTANCE_ID' not found${NC}"
    exit 1
fi

# Get instance details
RDS_INFO=$(aws rds describe-db-instances --db-instance-identifier "$RDS_INSTANCE_ID" --query 'DBInstances[0]')

STATUS=$(echo "$RDS_INFO" | jq -r '.DBInstanceStatus')
MULTI_AZ=$(echo "$RDS_INFO" | jq -r '.MultiAZ')
ENDPOINT=$(echo "$RDS_INFO" | jq -r '.Endpoint.Address')
AZ=$(echo "$RDS_INFO" | jq -r '.AvailabilityZone')

echo -e "${GREEN}✅ RDS Instance Status${NC}"
echo "  Instance: $RDS_INSTANCE_ID"
echo "  Status: $STATUS"
echo "  Endpoint: $ENDPOINT"
echo "  Current AZ: $AZ"
echo "  Multi-AZ: $MULTI_AZ"

if [ "$MULTI_AZ" = "true" ]; then
    echo -e "${GREEN}✅ Multi-AZ is ENABLED${NC}"
else
    echo -e "${RED}❌ Multi-AZ is DISABLED${NC}"
fi

echo -e "\n${BLUE}Ready for Mission DB007!${NC}"