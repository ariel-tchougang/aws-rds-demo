#!/bin/bash

# Mission DB007 - Terraform Cleanup Script
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

echo -e "${BLUE}Mission DB007 - Terraform Cleanup${NC}"
echo -e "${BLUE}==================================${NC}"

# Check if terraform.tfvars exists
if [[ ! -f "$SCRIPT_DIR/terraform.tfvars" ]]; then
    echo -e "${RED}Error: terraform.tfvars not found${NC}"
    echo -e "${YELLOW}Please ensure terraform.tfvars exists before cleanup${NC}"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed or not in PATH${NC}"
    exit 1
fi

# Check if state file exists
if [[ ! -f "$SCRIPT_DIR/terraform.tfstate" ]]; then
    echo -e "${YELLOW}Warning: No terraform.tfstate found. Resources may not exist.${NC}"
fi

# Confirmation prompt
echo -e "\n${YELLOW}⚠️  WARNING: This will destroy ALL Mission DB007 Terraform resources${NC}"
echo -e "This includes:"
echo -e "  - ${BLUE}RDS Multi-AZ PostgreSQL instance${NC}"
echo -e "  - ${BLUE}VPC and networking components${NC}"
echo -e "  - ${BLUE}Security groups and IAM roles${NC}"
echo -e "  - ${BLUE}CloudWatch dashboards and logs${NC}"
echo ""
read -p "Are you sure you want to proceed? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo -e "${BLUE}Cleanup cancelled. Resources preserved.${NC}"
    exit 0
fi

# Change to terraform directory
cd "$SCRIPT_DIR"

# Initialize Terraform (in case of state changes)
echo -e "\n${YELLOW}Initializing Terraform...${NC}"
terraform init

# Plan destruction
echo -e "\n${YELLOW}Planning resource destruction...${NC}"
terraform plan -destroy -out=destroy.tfplan

# Show what will be destroyed
echo -e "\n${YELLOW}Resources to be destroyed:${NC}"
terraform show destroy.tfplan

# Final confirmation
echo -e "\n${RED}FINAL WARNING: This action cannot be undone!${NC}"
read -p "Type 'DESTROY' to confirm destruction: " FINAL_CONFIRM

if [[ "$FINAL_CONFIRM" != "DESTROY" ]]; then
    echo -e "${BLUE}Cleanup cancelled. Resources preserved.${NC}"
    rm -f destroy.tfplan
    exit 0
fi

# Execute destruction
echo -e "\n${YELLOW}Destroying resources...${NC}"
terraform apply destroy.tfplan

# Cleanup plan file
rm -f destroy.tfplan

echo -e "\n${GREEN}Mission DB007 Terraform cleanup completed!${NC}"
echo -e "${BLUE}All resources have been destroyed. Agent DB007 signing off.${NC}"

# Optional: Remove state files
echo -e "\n${YELLOW}Clean up state files? (terraform.tfstate*)${NC}"
read -p "Remove state files? (yes/no): " CLEAN_STATE

if [[ "$CLEAN_STATE" == "yes" ]]; then
    rm -f terraform.tfstate*
    echo -e "${GREEN}State files cleaned up.${NC}"
fi