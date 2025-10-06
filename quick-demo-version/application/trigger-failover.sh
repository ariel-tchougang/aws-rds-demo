#!/bin/bash
# Mission DB007 - Trigger Failover

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}💥 Mission DB007 - Trigger Failover${NC}"
echo "=================================="

# Load environment
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

RDS_INSTANCE_ID=${RDS_INSTANCE_ID:-"db007-mission-postgres"}

# Get current AZ
CURRENT_AZ=$(aws rds describe-db-instances --db-instance-identifier "$RDS_INSTANCE_ID" --query 'DBInstances[0].AvailabilityZone' --output text)

echo -e "${YELLOW}⚠️  WARNING: Triggering controlled failover${NC}"
echo "Current AZ: $CURRENT_AZ"
echo ""
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

# Trigger failover
echo -e "\n${BLUE}🚀 Initiating failover...${NC}"
aws rds reboot-db-instance --db-instance-identifier "$RDS_INSTANCE_ID" --force-failover

echo -e "${GREEN}✅ Failover triggered${NC}"
echo "Monitor the demo output for recovery timing!"