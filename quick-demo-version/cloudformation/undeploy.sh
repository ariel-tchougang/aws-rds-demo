#!/bin/bash

# Mission DB007 - CloudFormation Cleanup Script
# Agent DB007 resource cleanup for DataCorp

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.env"

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}Error: Configuration file not found at $CONFIG_FILE${NC}"
    exit 1
fi

source "$CONFIG_FILE"

echo -e "${BLUE}Mission DB007 - Resource Cleanup${NC}"
echo -e "${BLUE}================================${NC}"

# Validate AWS CLI and profile
echo -e "${YELLOW}Validating AWS configuration...${NC}"
if ! aws sts get-caller-identity --profile "$AWS_PROFILE" --region "$AWS_REGION" > /dev/null 2>&1; then
    echo -e "${RED}Error: AWS CLI not configured or invalid profile/region${NC}"
    exit 1
fi

echo -e "${GREEN}AWS Profile: $AWS_PROFILE${NC}"
echo -e "${GREEN}AWS Region: $AWS_REGION${NC}"

# Confirmation prompt
echo -e "\n${YELLOW}⚠️  WARNING: This will delete ALL Mission DB007 resources${NC}"
echo -e "Stacks to be deleted:"
echo -e "  - ${BLUE}$STACK_NAME_INFRASTRUCTURE${NC}"
echo -e "  - ${BLUE}$STACK_NAME_MONITORING${NC}"
echo ""
read -p "Are you sure you want to proceed? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo -e "${BLUE}Cleanup cancelled. Resources preserved.${NC}"
    exit 0
fi

# Delete monitoring stack first (if exists)
echo -e "\n${YELLOW}Checking for monitoring stack...${NC}"
if aws cloudformation describe-stacks --stack-name "$STACK_NAME_MONITORING" --profile "$AWS_PROFILE" --region "$AWS_REGION" > /dev/null 2>&1; then
    echo -e "${YELLOW}Deleting monitoring stack...${NC}"
    aws cloudformation delete-stack \
        --stack-name "$STACK_NAME_MONITORING" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION"
    
    echo -e "${YELLOW}Waiting for monitoring stack deletion...${NC}"
    aws cloudformation wait stack-delete-complete \
        --stack-name "$STACK_NAME_MONITORING" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION"
    
    echo -e "${GREEN}Monitoring stack deleted successfully!${NC}"
else
    echo -e "${BLUE}Monitoring stack not found, skipping...${NC}"
fi

# Delete infrastructure stack
echo -e "\n${YELLOW}Deleting infrastructure stack...${NC}"
if aws cloudformation describe-stacks --stack-name "$STACK_NAME_INFRASTRUCTURE" --profile "$AWS_PROFILE" --region "$AWS_REGION" > /dev/null 2>&1; then
    aws cloudformation delete-stack \
        --stack-name "$STACK_NAME_INFRASTRUCTURE" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION"
    
    echo -e "${YELLOW}Waiting for infrastructure stack deletion...${NC}"
    aws cloudformation wait stack-delete-complete \
        --stack-name "$STACK_NAME_INFRASTRUCTURE" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION"
    
    echo -e "${GREEN}Infrastructure stack deleted successfully!${NC}"
else
    echo -e "${RED}Infrastructure stack not found!${NC}"
    exit 1
fi

echo -e "\n${GREEN}Mission DB007 cleanup completed!${NC}"
echo -e "${BLUE}All resources have been terminated. Agent DB007 signing off.${NC}"