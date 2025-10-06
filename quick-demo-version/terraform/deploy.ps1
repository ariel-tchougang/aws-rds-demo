# Mission DB007 - Terraform Deployment Script (PowerShell)
# Agent DB007 infrastructure deployment for DataCorp

param(
    [switch]$AutoApprove,
    [switch]$Destroy
)

# Script configuration
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "Mission DB007 - Terraform Deployment" "Blue"
Write-ColorOutput "====================================" "Blue"

# Change to script directory
Set-Location $ScriptDir

# Check if terraform.tfvars exists
if (-not (Test-Path "terraform.tfvars")) {
    Write-ColorOutput "Error: terraform.tfvars not found" "Red"
    Write-ColorOutput "Please copy terraform.tfvars.example to terraform.tfvars and customize your values" "Yellow"
    exit 1
}

# Check Terraform installation
try {
    $TerraformVersion = terraform version
    Write-ColorOutput "Terraform version:" "Green"
    Write-ColorOutput $TerraformVersion "White"
} catch {
    Write-ColorOutput "Error: Terraform is not installed" "Red"
    exit 1
}

if ($Destroy) {
    Write-ColorOutput "`nDestroying Terraform infrastructure..." "Yellow"
    
    if ($AutoApprove) {
        terraform destroy -auto-approve
    } else {
        terraform destroy
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "Infrastructure destroyed successfully!" "Green"
    } else {
        Write-ColorOutput "Infrastructure destruction failed!" "Red"
        exit 1
    }
    exit 0
}

# Initialize Terraform
Write-ColorOutput "`nInitializing Terraform..." "Yellow"
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "Terraform initialization failed!" "Red"
    exit 1
}

# Validate configuration
Write-ColorOutput "`nValidating Terraform configuration..." "Yellow"
terraform validate

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "Terraform validation failed!" "Red"
    exit 1
}

# Plan deployment
Write-ColorOutput "`nPlanning Terraform deployment..." "Yellow"
terraform plan -out=tfplan

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "Terraform planning failed!" "Red"
    exit 1
}

# Ask for confirmation unless auto-approve is set
if (-not $AutoApprove) {
    Write-ColorOutput "`nDo you want to apply this plan? (yes/no):" "Yellow"
    $response = Read-Host
    
    if ($response -ne "yes") {
        Write-ColorOutput "Deployment cancelled by user" "Yellow"
        Remove-Item "tfplan" -ErrorAction SilentlyContinue
        exit 0
    }
}

# Apply deployment
Write-ColorOutput "`nApplying Terraform deployment..." "Yellow"
if ($AutoApprove) {
    terraform apply -auto-approve
} else {
    terraform apply tfplan
}

if ($LASTEXITCODE -eq 0) {
    Write-ColorOutput "Infrastructure deployed successfully!" "Green"
    Remove-Item "tfplan" -ErrorAction SilentlyContinue
} else {
    Write-ColorOutput "Infrastructure deployment failed!" "Red"
    Remove-Item "tfplan" -ErrorAction SilentlyContinue
    exit 1
}

# Display outputs
Write-ColorOutput "`nRetrieving deployment outputs..." "Yellow"
terraform output

# Display mission status
Write-ColorOutput "`nMission DB007 Infrastructure Status:" "Green"
Write-ColorOutput "====================================" "Green"

try {
    $VpcId = terraform output -raw vpc_id 2>$null
    $RdsEndpoint = terraform output -raw rds_endpoint 2>$null
    $PrimaryAz = terraform output -raw primary_availability_zone 2>$null
    $SecondaryAz = terraform output -raw secondary_availability_zone 2>$null
    $DashboardUrl = terraform output -raw dashboard_url 2>$null

    Write-ColorOutput "VPC ID: $VpcId" "Blue"
    Write-ColorOutput "RDS Endpoint: $RdsEndpoint" "Blue"
    Write-ColorOutput "Primary AZ: $PrimaryAz" "Blue"
    Write-ColorOutput "Secondary AZ: $SecondaryAz" "Blue"
    Write-ColorOutput "Dashboard URL: $DashboardUrl" "Blue"
} catch {
    Write-ColorOutput "Could not retrieve all outputs" "Yellow"
}

Write-ColorOutput "`nMission DB007 deployment completed!" "Green"
Write-ColorOutput "Next steps:" "Yellow"
Write-ColorOutput "1. Configure your application with the RDS endpoint" "White"
Write-ColorOutput "2. Run the DB007 monitoring agent" "White"
Write-ColorOutput "3. Execute failover test when ready" "White"
Write-ColorOutput "`nAgent DB007 standing by for orders..." "Blue"