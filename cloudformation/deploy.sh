#!/bin/bash

# Mission DB007 - CloudFormation Deployment Script
# Agent DB007 infrastructure deployment for DataCorp

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
    echo -e "${YELLOW}Please copy config.env.example to config.env and customize your values${NC}"
    exit 1
fi

source "$CONFIG_FILE"

echo -e "${BLUE}Mission DB007 - Infrastructure Deployment${NC}"
echo -e "${BLUE}=========================================${NC}"

# Validate AWS CLI and profile
echo -e "${YELLOW}Validating AWS configuration...${NC}"
if ! aws sts get-caller-identity --profile "$AWS_PROFILE" --region "$AWS_REGION" > /dev/null 2>&1; then
    echo -e "${RED}Error: AWS CLI not configured or invalid profile/region${NC}"
    exit 1
fi

echo -e "${GREEN}AWS Profile: $AWS_PROFILE${NC}"
echo -e "${GREEN}AWS Region: $AWS_REGION${NC}"

# Deploy Infrastructure Stack
echo -e "\n${YELLOW}Deploying infrastructure stack...${NC}"
aws cloudformation deploy \
    --template-file "$SCRIPT_DIR/db007-infrastructure.yaml" \
    --stack-name "$STACK_NAME_INFRASTRUCTURE" \
    --parameter-overrides \
        ProjectName="$PROJECT_NAME" \
        DBInstanceClass="$DB_INSTANCE_CLASS" \
        DBName="$DB_NAME" \
        DBUsername="$DB_USERNAME" \
        DBPassword="$DB_PASSWORD" \
        VpcCidr="$VPC_CIDR" \
        SSHAllowedCidr="$SSH_ALLOWED_CIDR" \
    --capabilities CAPABILITY_NAMED_IAM \
    --tags \
        Mission="$TAG_MISSION" \
        Purpose="$TAG_PURPOSE" \
        Environment="$TAG_ENVIRONMENT" \
        Owner="$TAG_OWNER" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION"

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}Infrastructure stack deployed successfully!${NC}"
else
    echo -e "${RED}Infrastructure stack deployment failed!${NC}"
    exit 1
fi

# Get stack outputs
echo -e "\n${YELLOW}Retrieving stack outputs...${NC}"
RDS_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME_INFRASTRUCTURE" \
    --query 'Stacks[0].Outputs[?OutputKey==`RDSEndpoint`].OutputValue' \
    --output text \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION")

VPC_ID=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME_INFRASTRUCTURE" \
    --query 'Stacks[0].Outputs[?OutputKey==`VPCId`].OutputValue' \
    --output text \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION")

AZ1=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME_INFRASTRUCTURE" \
    --query 'Stacks[0].Outputs[?OutputKey==`AvailabilityZone1`].OutputValue' \
    --output text \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION")

AZ2=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME_INFRASTRUCTURE" \
    --query 'Stacks[0].Outputs[?OutputKey==`AvailabilityZone2`].OutputValue' \
    --output text \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION")

# Display mission status
echo -e "\n${GREEN}Mission DB007 Infrastructure Status:${NC}"
echo -e "${GREEN}====================================${NC}"
echo -e "VPC ID: ${BLUE}$VPC_ID${NC}"
echo -e "RDS Endpoint: ${BLUE}$RDS_ENDPOINT${NC}"
echo -e "Primary AZ: ${BLUE}$AZ1${NC}"
echo -e "Secondary AZ: ${BLUE}$AZ2${NC}"
echo -e "Database: ${BLUE}$DB_NAME${NC}"
echo -e "Username: ${BLUE}$DB_USERNAME${NC}"

# Check if monitoring stack should be deployed
if [[ -f "$SCRIPT_DIR/db007-monitoring.yaml" ]]; then
    echo -e "\n${YELLOW}Deploying monitoring stack...${NC}"
    aws cloudformation deploy \
        --template-file "$SCRIPT_DIR/db007-monitoring.yaml" \
        --stack-name "$STACK_NAME_MONITORING" \
        --parameter-overrides \
            ProjectName="$PROJECT_NAME" \
            DashboardName="$DASHBOARD_NAME" \
            MetricNamespace="$METRIC_NAMESPACE" \
            LogGroupName="$LOG_GROUP_NAME" \
            LogRetentionDays="$LOG_RETENTION_DAYS" \
        --capabilities CAPABILITY_NAMED_IAM \
        --tags \
            Mission="$TAG_MISSION" \
            Purpose="$TAG_PURPOSE" \
            Environment="$TAG_ENVIRONMENT" \
            Owner="$TAG_OWNER" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Monitoring stack deployed successfully!${NC}"
    else
        echo -e "${YELLOW}Warning: Monitoring stack deployment failed, but infrastructure is ready${NC}"
    fi
fi

echo -e "\n${GREEN}Mission DB007 deployment completed!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Configure your application with the RDS endpoint: ${BLUE}$RDS_ENDPOINT${NC}"
echo -e "2. Run the DB007 monitoring agent"
echo -e "3. Execute failover test when ready"
echo -e "\n${BLUE}Agent DB007 standing by for orders...${NC}"