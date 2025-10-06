# Mission DB007 - RDS Status Check (PowerShell)
# Check RDS instance status for quick demo

param(
    [string]$ProjectName = "db007-mission"
)

# Colors for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "Mission DB007 - RDS Status Check" "Blue"
Write-ColorOutput "====================================" "Blue"

# Load environment variables if .env exists
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
    $ProjectName = $env:PROJECT_NAME ?? $ProjectName
}

$RdsInstanceId = "$ProjectName-postgres"

Write-ColorOutput "`nChecking RDS instance: $RdsInstanceId" "Yellow"

# Check if RDS instance exists
try {
    $RdsInfo = aws rds describe-db-instances --db-instance-identifier $RdsInstanceId --query 'DBInstances[0]' 2>$null | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        throw "RDS instance not found"
    }
} catch {
    Write-ColorOutput "ERROR: RDS instance '$RdsInstanceId' not found" "Red"
    Write-ColorOutput "Make sure the infrastructure is deployed and PROJECT_NAME is correct" "Yellow"
    exit 1
}

# Extract key information
$Status = $RdsInfo.DBInstanceStatus
$MultiAZ = $RdsInfo.MultiAZ
$Engine = $RdsInfo.Engine
$EngineVersion = $RdsInfo.EngineVersion
$Endpoint = $RdsInfo.Endpoint.Address
$Port = $RdsInfo.Endpoint.Port
$AZ = $RdsInfo.AvailabilityZone
$PublicAccess = $RdsInfo.PubliclyAccessible

Write-ColorOutput "RDS Instance Status" "Green"
Write-ColorOutput "  Instance ID: $RdsInstanceId" "White"
Write-ColorOutput "  Status: $Status" "White"
Write-ColorOutput "  Engine: $Engine $EngineVersion" "White"
Write-ColorOutput "  Endpoint: $Endpoint`:$Port" "White"
Write-ColorOutput "  Current AZ: $AZ" "White"
Write-ColorOutput "  Multi-AZ: $MultiAZ" "White"
Write-ColorOutput "  Public Access: $PublicAccess" "White"

# Check Multi-AZ status
if ($MultiAZ -eq $true) {
    Write-ColorOutput "Multi-AZ is ENABLED" "Green"
} else {
    Write-ColorOutput "ERROR: Multi-AZ is DISABLED" "Red"
    Write-ColorOutput "This demo requires Multi-AZ to be enabled!" "Yellow"
}

# Check public access for quick demo
if ($PublicAccess -eq $true) {
    Write-ColorOutput "Public access is ENABLED (Quick Demo Mode)" "Green"
} else {
    Write-ColorOutput "WARNING: Public access is DISABLED" "Yellow"
    Write-ColorOutput "Quick demo requires public access to be enabled" "Yellow"
}

Write-ColorOutput "`nReady for Mission DB007 Quick Demo!" "Blue"