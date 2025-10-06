# Mission DB007 - Terraform Cleanup Script (PowerShell)
# Agent DB007 resource cleanup for DataCorp

param(
    [switch]$Force,
    [switch]$CleanState
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

Write-ColorOutput "Mission DB007 - Terraform Cleanup" "Blue"
Write-ColorOutput "==================================" "Blue"

# Check if terraform.tfvars exists
$TfVarsPath = Join-Path $ScriptDir "terraform.tfvars"
if (-not (Test-Path $TfVarsPath)) {
    Write-ColorOutput "Error: terraform.tfvars not found" "Red"
    Write-ColorOutput "Please ensure terraform.tfvars exists before cleanup" "Yellow"
    exit 1
}

# Check if Terraform is installed
try {
    terraform version | Out-Null
} catch {
    Write-ColorOutput "Error: Terraform is not installed or not in PATH" "Red"
    exit 1
}

# Check if state file exists
$StateFile = Join-Path $ScriptDir "terraform.tfstate"
if (-not (Test-Path $StateFile)) {
    Write-ColorOutput "Warning: No terraform.tfstate found. Resources may not exist." "Yellow"
}

# Confirmation prompt
if (-not $Force) {
    Write-ColorOutput "`n⚠️  WARNING: This will destroy ALL Mission DB007 Terraform resources" "Yellow"
    Write-ColorOutput "This includes:" "White"
    Write-ColorOutput "  - RDS Multi-AZ PostgreSQL instance" "Blue"
    Write-ColorOutput "  - VPC and networking components" "Blue"
    Write-ColorOutput "  - Security groups and IAM roles" "Blue"
    Write-ColorOutput "  - CloudWatch dashboards and logs" "Blue"
    Write-Host ""
    $Confirm = Read-Host "Are you sure you want to proceed? (yes/no)"
    
    if ($Confirm -ne "yes") {
        Write-ColorOutput "Cleanup cancelled. Resources preserved." "Blue"
        exit 0
    }
}

# Change to terraform directory
Set-Location $ScriptDir

# Initialize Terraform (in case of state changes)
Write-ColorOutput "`nInitializing Terraform..." "Yellow"
terraform init

# Plan destruction
Write-ColorOutput "`nPlanning resource destruction..." "Yellow"
terraform plan -destroy -out=destroy.tfplan

# Show what will be destroyed
Write-ColorOutput "`nResources to be destroyed:" "Yellow"
terraform show destroy.tfplan

# Final confirmation
if (-not $Force) {
    Write-ColorOutput "`nFINAL WARNING: This action cannot be undone!" "Red"
    $FinalConfirm = Read-Host "Type 'DESTROY' to confirm destruction"
    
    if ($FinalConfirm -ne "DESTROY") {
        Write-ColorOutput "Cleanup cancelled. Resources preserved." "Blue"
        Remove-Item "destroy.tfplan" -ErrorAction SilentlyContinue
        exit 0
    }
}

# Execute destruction
Write-ColorOutput "`nDestroying resources..." "Yellow"
terraform apply destroy.tfplan

# Cleanup plan file
Remove-Item "destroy.tfplan" -ErrorAction SilentlyContinue

Write-ColorOutput "`nMission DB007 Terraform cleanup completed!" "Green"
Write-ColorOutput "All resources have been destroyed. Agent DB007 signing off." "Blue"

# Optional: Remove state files
if ($CleanState) {
    Write-ColorOutput "`nCleaning up state files..." "Yellow"
    Remove-Item "terraform.tfstate*" -ErrorAction SilentlyContinue
    Write-ColorOutput "State files cleaned up." "Green"
} else {
    Write-ColorOutput "`nClean up state files? (terraform.tfstate*)" "Yellow"
    $CleanStatePrompt = Read-Host "Remove state files? (yes/no)"
    
    if ($CleanStatePrompt -eq "yes") {
        Remove-Item "terraform.tfstate*" -ErrorAction SilentlyContinue
        Write-ColorOutput "State files cleaned up." "Green"
    }
}