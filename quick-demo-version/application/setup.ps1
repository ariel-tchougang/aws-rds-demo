# Mission DB007 - Quick Demo Setup (PowerShell)
# Setup script for Windows environments

param(
    [switch]$SkipPython
)

# Colors for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "Mission DB007 - Quick Demo Setup" "Blue"
Write-ColorOutput "====================================" "Blue"

# Check Python installation
if (-not $SkipPython) {
    Write-ColorOutput "Checking Python installation..." "Yellow"
    try {
        $pythonVersion = python --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "Python found: $pythonVersion" "Green"
        } else {
            throw "Python not found"
        }
    } catch {
        Write-ColorOutput "ERROR: Python 3.7+ is required but not found" "Red"
        Write-ColorOutput "Please install Python from: https://www.python.org/downloads/" "Yellow"
        Write-ColorOutput "Make sure to check 'Add Python to PATH' during installation" "Yellow"
        exit 1
    }
}

# Create virtual environment
Write-ColorOutput "Setting up Python virtual environment..." "Yellow"
python -m venv .venv

# Activate virtual environment
Write-ColorOutput "Activating virtual environment..." "Yellow"
& ".\.venv\Scripts\Activate.ps1"

# Upgrade pip and install dependencies
Write-ColorOutput "Installing Python dependencies..." "Yellow"
python -m pip install --upgrade pip
pip install -r requirements.txt

# Setup environment file
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-ColorOutput "Created .env file" "Green"
    Write-ColorOutput "IMPORTANT: Edit .env with your RDS endpoint and credentials" "Yellow"
} else {
    Write-ColorOutput ".env file already exists" "Green"
}

# Get current directory for aliases
$CurrentDir = Get-Location

# Setup PowerShell profile aliases
Write-ColorOutput "Setting up PowerShell aliases..." "Yellow"
$ProfilePath = $PROFILE.CurrentUserAllHosts
$ProfileDir = Split-Path $ProfilePath -Parent

# Create profile directory if it doesn't exist
if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
}

# Add aliases to PowerShell profile
$AliasContent = @"

# Mission DB007 aliases
function demo-activate { Set-Location '$CurrentDir'; & '.\.venv\Scripts\Activate.ps1' }
function demo-start { Set-Location '$CurrentDir'; & '.\.venv\Scripts\Activate.ps1'; python main.py }
function demo-status { Set-Location '$CurrentDir'; & '.\check-rds.ps1' }
function demo-failover { Set-Location '$CurrentDir'; & '.\trigger-failover.ps1' }
"@

Add-Content -Path $ProfilePath -Value $AliasContent

Write-ColorOutput "Setup completed!" "Green"
Write-ColorOutput "" "White"
Write-ColorOutput "Next steps:" "Yellow"
Write-ColorOutput "1. Edit .env with your RDS endpoint and credentials" "White"
Write-ColorOutput "2. Restart PowerShell or run: . `$PROFILE" "White"
Write-ColorOutput "3. Run: demo-start" "White"
Write-ColorOutput "" "White"
Write-ColorOutput "Available commands:" "Yellow"
Write-ColorOutput "  demo-activate  - Activate Python environment" "White"
Write-ColorOutput "  demo-start     - Start DB007 agent" "White"
Write-ColorOutput "  demo-status    - Check RDS status" "White"
Write-ColorOutput "  demo-failover  - Trigger controlled failover" "White"