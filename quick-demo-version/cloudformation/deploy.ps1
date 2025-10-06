# Mission DB007 - CloudFormation Deployment Script (PowerShell)
# Agent DB007 infrastructure deployment for DataCorp

param(
    [switch]$SkipMonitoring
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
        Write-Host "Please copy config.env.example to config.env and customize your values" -ForegroundColor Yellow
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

Write-ColorOutput "Mission DB007 - Infrastructure Deployment" "Blue"
Write-ColorOutput "=========================================" "Blue"

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

# Deploy Infrastructure Stack
Write-ColorOutput "`nDeploying infrastructure stack..." "Yellow"
$InfraArgs = @(
    "cloudformation", "deploy",
    "--template-file", (Join-Path $ScriptDir "db007-infrastructure.yaml"),
    "--stack-name", $Config.STACK_NAME_INFRASTRUCTURE,
    "--parameter-overrides",
    "ProjectName=$($Config.PROJECT_NAME)",
    "DBInstanceClass=$($Config.DB_INSTANCE_CLASS)",
    "DBName=$($Config.DB_NAME)",
    "DBUsername=$($Config.DB_USERNAME)",
    "DBPassword=$($Config.DB_PASSWORD)",
    "VpcCidr=$($Config.VPC_CIDR)",
    "ClientAccessCidr=$($Config.CLIENT_ACCESS_CIDR)",
    "--capabilities", "CAPABILITY_NAMED_IAM",
    "--tags",
    "Mission=$($Config.TAG_MISSION)",
    "Purpose=$($Config.TAG_PURPOSE)",
    "Environment=$($Config.TAG_ENVIRONMENT)",
    "Owner=$($Config.TAG_OWNER)",
    "--profile", $Config.AWS_PROFILE,
    "--region", $Config.AWS_REGION
)

& aws @InfraArgs
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "Infrastructure stack deployment failed!" "Red"
    exit 1
}

Write-ColorOutput "Infrastructure stack deployed successfully!" "Green"

# Get stack outputs
Write-ColorOutput "`nRetrieving stack outputs..." "Yellow"
$RdsEndpoint = aws cloudformation describe-stacks `
    --stack-name $Config.STACK_NAME_INFRASTRUCTURE `
    --query 'Stacks[0].Outputs[?OutputKey==`RDSEndpoint`].OutputValue' `
    --output text `
    --profile $Config.AWS_PROFILE `
    --region $Config.AWS_REGION

$VpcId = aws cloudformation describe-stacks `
    --stack-name $Config.STACK_NAME_INFRASTRUCTURE `
    --query 'Stacks[0].Outputs[?OutputKey==`VPCId`].OutputValue' `
    --output text `
    --profile $Config.AWS_PROFILE `
    --region $Config.AWS_REGION

$Az1 = aws cloudformation describe-stacks `
    --stack-name $Config.STACK_NAME_INFRASTRUCTURE `
    --query 'Stacks[0].Outputs[?OutputKey==`AvailabilityZone1`].OutputValue' `
    --output text `
    --profile $Config.AWS_PROFILE `
    --region $Config.AWS_REGION

$Az2 = aws cloudformation describe-stacks `
    --stack-name $Config.STACK_NAME_INFRASTRUCTURE `
    --query 'Stacks[0].Outputs[?OutputKey==`AvailabilityZone2`].OutputValue' `
    --output text `
    --profile $Config.AWS_PROFILE `
    --region $Config.AWS_REGION

# Display mission status
Write-ColorOutput "`nMission DB007 Infrastructure Status:" "Green"
Write-ColorOutput "====================================" "Green"
Write-ColorOutput "VPC ID: $VpcId" "Blue"
Write-ColorOutput "RDS Endpoint: $RdsEndpoint" "Blue"
Write-ColorOutput "Primary AZ: $Az1" "Blue"
Write-ColorOutput "Secondary AZ: $Az2" "Blue"
Write-ColorOutput "Database: $($Config.DB_NAME)" "Blue"
Write-ColorOutput "Username: $($Config.DB_USERNAME)" "Blue"

# Check if monitoring stack should be deployed
$MonitoringTemplate = Join-Path $ScriptDir "db007-monitoring.yaml"
if ((Test-Path $MonitoringTemplate) -and -not $SkipMonitoring) {
    Write-ColorOutput "`nDeploying monitoring stack..." "Yellow"
    
    $MonitoringArgs = @(
        "cloudformation", "deploy",
        "--template-file", $MonitoringTemplate,
        "--stack-name", $Config.STACK_NAME_MONITORING,
        "--parameter-overrides",
        "ProjectName=$($Config.PROJECT_NAME)",
        "DashboardName=$($Config.DASHBOARD_NAME)",
        "MetricNamespace=$($Config.METRIC_NAMESPACE)",
        "LogGroupName=$($Config.LOG_GROUP_NAME)",
        "LogRetentionDays=$($Config.LOG_RETENTION_DAYS)",
        "--capabilities", "CAPABILITY_NAMED_IAM",
        "--tags",
        "Mission=$($Config.TAG_MISSION)",
        "Purpose=$($Config.TAG_PURPOSE)",
        "Environment=$($Config.TAG_ENVIRONMENT)",
        "Owner=$($Config.TAG_OWNER)",
        "--profile", $Config.AWS_PROFILE,
        "--region", $Config.AWS_REGION
    )
    
    & aws @MonitoringArgs
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "Monitoring stack deployed successfully!" "Green"
    } else {
        Write-ColorOutput "Warning: Monitoring stack deployment failed, but infrastructure is ready" "Yellow"
    }
}

Write-ColorOutput "`nMission DB007 deployment completed!" "Green"
Write-ColorOutput "Next steps:" "Yellow"
Write-ColorOutput "1. Configure your application with the RDS endpoint: $RdsEndpoint" "Blue"
Write-ColorOutput "2. Run the DB007 monitoring agent" "White"
Write-ColorOutput "3. Execute failover test when ready" "White"
Write-ColorOutput "`nAgent DB007 standing by for orders..." "Blue"