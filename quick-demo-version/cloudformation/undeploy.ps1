# Mission DB007 - CloudFormation Cleanup Script (PowerShell)
# Agent DB007 resource cleanup for DataCorp

param(
    [switch]$Force
)

# Script configuration
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigFile = Join-Path $ScriptDir "config.env"

# Function to load environment file
function Load-EnvFile {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "Error: Configuration file not found at $FilePath" -ForegroundColor Red
        exit 1
    }
    
    $envVars = @{}
    Get-Content $FilePath | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $envVars[$matches[1]] = $matches[2]
        }
    }
    return $envVars
}

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "Mission DB007 - Resource Cleanup" "Blue"
Write-ColorOutput "================================" "Blue"

# Load configuration
$Config = Load-EnvFile -FilePath $ConfigFile

# Validate AWS CLI and profile
Write-ColorOutput "Validating AWS configuration..." "Yellow"
try {
    $CallerIdentity = aws sts get-caller-identity --profile $Config.AWS_PROFILE --region $Config.AWS_REGION 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI validation failed"
    }
} catch {
    Write-ColorOutput "Error: AWS CLI not configured or invalid profile/region" "Red"
    exit 1
}

Write-ColorOutput "AWS Profile: $($Config.AWS_PROFILE)" "Green"
Write-ColorOutput "AWS Region: $($Config.AWS_REGION)" "Green"

# Confirmation prompt
if (-not $Force) {
    Write-ColorOutput "`n⚠️  WARNING: This will delete ALL Mission DB007 resources" "Yellow"
    Write-ColorOutput "Stacks to be deleted:" "White"
    Write-ColorOutput "  - $($Config.STACK_NAME_INFRASTRUCTURE)" "Blue"
    Write-ColorOutput "  - $($Config.STACK_NAME_MONITORING)" "Blue"
    Write-Host ""
    $Confirm = Read-Host "Are you sure you want to proceed? (yes/no)"
    
    if ($Confirm -ne "yes") {
        Write-ColorOutput "Cleanup cancelled. Resources preserved." "Blue"
        exit 0
    }
}

# Delete monitoring stack first (if exists)
Write-ColorOutput "`nChecking for monitoring stack..." "Yellow"
try {
    aws cloudformation describe-stacks --stack-name $Config.STACK_NAME_MONITORING --profile $Config.AWS_PROFILE --region $Config.AWS_REGION 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "Deleting monitoring stack..." "Yellow"
        aws cloudformation delete-stack `
            --stack-name $Config.STACK_NAME_MONITORING `
            --profile $Config.AWS_PROFILE `
            --region $Config.AWS_REGION
        
        Write-ColorOutput "Waiting for monitoring stack deletion..." "Yellow"
        aws cloudformation wait stack-delete-complete `
            --stack-name $Config.STACK_NAME_MONITORING `
            --profile $Config.AWS_PROFILE `
            --region $Config.AWS_REGION
        
        Write-ColorOutput "Monitoring stack deleted successfully!" "Green"
    }
} catch {
    Write-ColorOutput "Monitoring stack not found, skipping..." "Blue"
}

# Delete infrastructure stack
Write-ColorOutput "`nDeleting infrastructure stack..." "Yellow"
try {
    aws cloudformation describe-stacks --stack-name $Config.STACK_NAME_INFRASTRUCTURE --profile $Config.AWS_PROFILE --region $Config.AWS_REGION 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        aws cloudformation delete-stack `
            --stack-name $Config.STACK_NAME_INFRASTRUCTURE `
            --profile $Config.AWS_PROFILE `
            --region $Config.AWS_REGION
        
        Write-ColorOutput "Waiting for infrastructure stack deletion..." "Yellow"
        aws cloudformation wait stack-delete-complete `
            --stack-name $Config.STACK_NAME_INFRASTRUCTURE `
            --profile $Config.AWS_PROFILE `
            --region $Config.AWS_REGION
        
        Write-ColorOutput "Infrastructure stack deleted successfully!" "Green"
    } else {
        Write-ColorOutput "Infrastructure stack not found!" "Red"
        exit 1
    }
} catch {
    Write-ColorOutput "Error deleting infrastructure stack!" "Red"
    exit 1
}

Write-ColorOutput "`nMission DB007 cleanup completed!" "Green"
Write-ColorOutput "All resources have been terminated. Agent DB007 signing off." "Blue"