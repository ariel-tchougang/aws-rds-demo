#!/bin/bash

# Mission DB007 - Terraform Deployment Script
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

echo -e "${BLUE}Mission DB007 - Terraform Deployment${NC}"
echo -e "${BLUE}====================================${NC}"

# Check if terraform.tfvars exists
if [[ ! -f "$SCRIPT_DIR/terraform.tfvars" ]]; then
    echo -e "${RED}Error: terraform.tfvars not found${NC}"
    echo -e "${YELLOW}Please copy terraform.tfvars.example to terraform.tfvars and customize your values${NC}"
    exit 1
fi

# Check Terraform installation
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}Terraform version:${NC}"
terraform version

# Initialize Terraform
echo -e "\n${YELLOW}Initializing Terraform...${NC}"
terraform init

# Validate configuration
echo -e "\n${YELLOW}Validating Terraform configuration...${NC}"
terraform validate

if [[ $? -ne 0 ]]; then
    echo -e "${RED}Terraform validation failed!${NC}"
    exit 1
fi

# Plan deployment
echo -e "\n${YELLOW}Planning Terraform deployment...${NC}"
terraform plan -out=tfplan

# Ask for confirmation
echo -e "\n${YELLOW}Do you want to apply this plan? (yes/no):${NC}"
read -r response

if [[ "$response" != "yes" ]]; then
    echo -e "${YELLOW}Deployment cancelled by user${NC}"
    rm -f tfplan
    exit 0
fi

# Apply deployment
echo -e "\n${YELLOW}Applying Terraform deployment...${NC}"
terraform apply tfplan

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}Infrastructure deployed successfully!${NC}"
    rm -f tfplan
else
    echo -e "${RED}Infrastructure deployment failed!${NC}"
    rm -f tfplan
    exit 1
fi

# Display outputs
echo -e "\n${YELLOW}Retrieving deployment outputs...${NC}"
terraform output

# Display mission status
echo -e "\n${GREEN}Mission DB007 Infrastructure Status:${NC}"
echo -e "${GREEN}====================================${NC}"

VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "N/A")
RDS_ENDPOINT=$(terraform output -raw rds_endpoint 2>/dev/null || echo "N/A")
PRIMARY_AZ=$(terraform output -raw primary_availability_zone 2>/dev/null || echo "N/A")
SECONDARY_AZ=$(terraform output -raw secondary_availability_zone 2>/dev/null || echo "N/A")
DASHBOARD_URL=$(terraform output -raw dashboard_url 2>/dev/null || echo "N/A")

echo -e "VPC ID: ${BLUE}$VPC_ID${NC}"
echo -e "RDS Endpoint: ${BLUE}$RDS_ENDPOINT${NC}"
echo -e "Primary AZ: ${BLUE}$PRIMARY_AZ${NC}"
echo -e "Secondary AZ: ${BLUE}$SECONDARY_AZ${NC}"
echo -e "Dashboard URL: ${BLUE}$DASHBOARD_URL${NC}"

echo -e "\n${GREEN}Mission DB007 deployment completed!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Configure your application with the RDS endpoint: ${BLUE}$RDS_ENDPOINT${NC}"
echo -e "2. Run the DB007 monitoring agent"
echo -e "3. Execute failover test when ready"
echo -e "\n${BLUE}Agent DB007 standing by for orders...${NC}"