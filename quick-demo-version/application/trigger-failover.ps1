# Mission DB007 - Trigger Failover (PowerShell)
# Trigger controlled RDS failover for quick demo

param(
    [string]$ProjectName = "db007-mission",
    [switch]$Force
)

# Colors for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "Mission DB007 - Trigger Failover" "Blue"
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

Write-ColorOutput "`nTarget: $RdsInstanceId" "Yellow"

# Get current RDS status
Write-ColorOutput "Pre-flight checks..." "Yellow"
try {
    $RdsInfo = aws rds describe-db-instances --db-instance-identifier $RdsInstanceId --query 'DBInstances[0]' 2>$null | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        throw "RDS instance not found"
    }
} catch {
    Write-ColorOutput "ERROR: RDS instance '$RdsInstanceId' not found" "Red"
    exit 1
}

$Status = $RdsInfo.DBInstanceStatus
$MultiAZ = $RdsInfo.MultiAZ
$CurrentAZ = $RdsInfo.AvailabilityZone

Write-ColorOutput "  Current Status: $Status" "White"
Write-ColorOutput "  Current AZ: $CurrentAZ" "White"
Write-ColorOutput "  Multi-AZ: $MultiAZ" "White"

# Verify Multi-AZ is enabled
if ($MultiAZ -ne $true) {
    Write-ColorOutput "ERROR: Multi-AZ is not enabled. Cannot perform failover." "Red"
    exit 1
}

# Verify instance is available
if ($Status -ne "available") {
    Write-ColorOutput "ERROR: Instance is not in 'available' state. Current: $Status" "Red"
    exit 1
}

Write-ColorOutput "Pre-flight checks passed" "Green"

# Confirmation prompt
if (-not $Force) {
    Write-ColorOutput "`nWARNING: This will trigger a controlled failover" "Yellow"
    Write-ColorOutput "The database will be temporarily unavailable (typically 60-120 seconds)" "White"
    Write-ColorOutput "Current AZ: $CurrentAZ" "White"
    Write-Host ""
    $Confirm = Read-Host "Continue with failover? (yes/no)"
    
    if ($Confirm -ne "yes") {
        Write-ColorOutput "Failover cancelled." "Blue"
        exit 0
    }
}

# Record start time
$StartTime = Get-Date
Write-ColorOutput "`nInitiating failover at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "Blue"

# Trigger failover
Write-ColorOutput "Executing: aws rds reboot-db-instance --db-instance-identifier $RdsInstanceId --force-failover" "Yellow"

try {
    aws rds reboot-db-instance --db-instance-identifier $RdsInstanceId --force-failover 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "Failover command sent successfully" "Green"
    } else {
        throw "Failed to trigger failover"
    }
} catch {
    Write-ColorOutput "ERROR: Failed to trigger failover" "Red"
    exit 1
}

# Monitor failover progress
Write-ColorOutput "`nMonitoring failover progress..." "Yellow"
Write-ColorOutput "Press Ctrl+C to stop monitoring (failover will continue)" "White"

$PreviousStatus = ""
$PreviousAZ = ""

while ($true) {
    Start-Sleep -Seconds 10
    
    # Get current status
    try {
        $RdsInfo = aws rds describe-db-instances --db-instance-identifier $RdsInstanceId --query 'DBInstances[0]' 2>$null | ConvertFrom-Json
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "❌ Failed to get instance status" "Red"
            continue
        }
    } catch {
        Write-ColorOutput "❌ Failed to get instance status" "Red"
        continue
    }
    
    $CurrentStatus = $RdsInfo.DBInstanceStatus
    $NewAZ = $RdsInfo.AvailabilityZone
    
    # Show status changes
    if ($CurrentStatus -ne $PreviousStatus -or $NewAZ -ne $PreviousAZ) {
        $Elapsed = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
        Write-ColorOutput "  [$($Elapsed)s] Status: $CurrentStatus | AZ: $NewAZ" "White"
        $PreviousStatus = $CurrentStatus
        $PreviousAZ = $NewAZ
    }
    
    # Check if failover is complete
    if ($CurrentStatus -eq "available" -and $NewAZ -ne $CurrentAZ) {
        $TotalTime = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
        Write-ColorOutput "`nFailover completed successfully!" "Green"
        Write-ColorOutput "  Total time: $TotalTime seconds" "White"
        Write-ColorOutput "  Original AZ: $CurrentAZ" "White"
        Write-ColorOutput "  New AZ: $NewAZ" "White"
        break
    }
    
    # Timeout after 10 minutes
    if (((Get-Date) - $StartTime).TotalSeconds -gt 600) {
        Write-ColorOutput "`nMonitoring timeout (10 minutes). Check AWS Console for status." "Yellow"
        break
    }
}

Write-ColorOutput "`nFailover monitoring completed." "Blue"