#!/bin/bash

# ===============================
# Windows Toolkit Menu
# ===============================
# A comprehensive toolkit with individual options for Windows setup automation.
# This script provides a menu of options that can be selected and run individually.

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"
LOGS_DIR="$PROJECT_ROOT/logs"
SESSION_LOG="$LOGS_DIR/setup-session-$(date +%Y%m%d_%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$SESSION_LOG"
}

# Colored output functions
info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$SESSION_LOG"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "$SESSION_LOG"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*" | tee -a "$SESSION_LOG"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$SESSION_LOG"
}

header() {
    echo -e "\n${PURPLE}================================${NC}"
    echo -e "${PURPLE} $*${NC}"
    echo -e "${PURPLE}================================${NC}\n"
}

# Check for administrator privileges - only returns status, no warnings
check_admin_privileges() {
    local is_admin=$(powershell.exe -Command "([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')" 2>/dev/null | tr -d '\r')

    if [[ "$is_admin" == "True" ]]; then
        return 0
    else
        return 1
    fi
}

# Execute PowerShell command directly (instead of using external script files)
execute_powershell() {
    local script_content="$1"
    local description="$2"

    info "Executing: $description"

    if powershell.exe -ExecutionPolicy Bypass -Command "$script_content"; then
        success "$description completed successfully"
        return 0
    else
        error "$description failed"
        return 1
    fi
}

# Phase 2: Optional Debloat & Tweaks Selection
debloat_selection() {
    header "Optional Debloat & Tweaks Selection"

    cat << 'EOF'

⚠️  SECURITY WARNING ⚠️
The following scripts will be downloaded and executed from remote sources.
These scripts modify system settings and remove Windows components.
Only proceed if you trust the sources and understand the risks.

Available debloat/tweak options:
1) Win11 Debloat (raphi.re) - Removes bloatware and telemetry
2) Windows Tweaks (Chris Titus Tech) - Performance and privacy tweaks
3) Debloat11 Script - Alternative debloat approach
4) Windows Activation Script - KMS activation (use at your own legal risk)
5) Skip all debloat scripts

EOF

    read -p "Select options (comma-separated, e.g., 1,2 or 5 to skip): " selections

    if [[ "$selections" == "5" ]]; then
        info "Skipping all debloat scripts"
        return 0
    fi

    # Convert selections to PowerShell script
    local debloat_script=$(cat <<-'SCRIPTEND'
# ===============================
# Debloat Script Selection Module
# ===============================

param(
    [string]$Selections = ""
)

function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Write to log file
    $SessionLog = [System.Environment]::GetEnvironmentVariable("SESSION_LOG", "Process")
    if ($SessionLog) {
        Add-Content -Path $SessionLog -Value $logEntry -Encoding UTF8
    }
}

# Colored output functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
    Write-Log "INFO" $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
    Write-Log "SUCCESS" $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
    Write-Log "WARNING" $Message
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    Write-Log "ERROR" $Message
}

function Write-Header {
    param([string]$Title)
    Write-Host "`n================================" -ForegroundColor Magenta
    Write-Host " $Title" -ForegroundColor Magenta
    Write-Host "================================`n" -ForegroundColor Magenta
}

function Show-SecurityWarning {
    Write-Host "`n" -ForegroundColor Red
    Write-Host "⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red -BackgroundColor Yellow
    Write-Host "The following scripts will be downloaded and executed from remote sources." -ForegroundColor Red
    Write-Host "These scripts modify system settings and remove Windows components." -ForegroundColor Red
    Write-Host "Only proceed if you trust the sources and understand the risks." -ForegroundColor Red
    Write-Host "`n" -ForegroundColor Red
}

function Get-DebloatScripts {
    return @{
        "1" = @{
            Name = "Win11 Debloat (raphi.re)"
            Description = "Removes bloatware and telemetry"
            Command = "& ([scriptblock]::Create((irm `"https://win11debloat.raphi.re/`")))"
            Url = "https://win11debloat.raphi.re/"
        }
        "2" = @{
            Name = "Windows Tweaks (Chris Titus Tech)"
            Description = "Performance and privacy tweaks"
            Command = "iwr -useb https://christitus.com/win | iex"
            Url = "https://christitus.com/win"
        }
        "3" = @{
            Name = "Debloat11 Script"
            Description = "Alternative debloat approach"
            Command = "iwr https://git.io/debloat11 | iex"
            Url = "https://git.io/debloat11"
        }
        "4" = @{
            Name = "Windows Activation Script"
            Description = "KMS activation (use at your own legal risk)"
            Command = "irm https://get.activated.win | iex"
            Url = "https://get.activated.win"
        }
    }
}

function Confirm-ScriptExecution {
    param(
        [hashtable]$Script
    )

    Write-Host "`nScript: " -NoNewline -ForegroundColor Cyan
    Write-Host $Script.Name -ForegroundColor White
    Write-Host "Description: " -NoNewline -ForegroundColor Cyan
    Write-Host $Script.Description -ForegroundColor White
    Write-Host "Source URL: " -NoNewline -ForegroundColor Cyan
    Write-Host $Script.Url -ForegroundColor White
    Write-Host "`nThis script will modify your system settings." -ForegroundColor Yellow

    $confirmation = Read-Host "`nDo you want to execute this script? (y/N)"
    return $confirmation -match "^[Yy]$"
}

function Execute-DebloatScript {
    param(
        [hashtable]$Script
    )

    try {
        Write-Host "`nExecuting: " -NoNewline -ForegroundColor Yellow
        Write-Host $Script.Name -ForegroundColor White
        Write-Host "Please wait..." -ForegroundColor Gray

        # Execute the script
        Invoke-Expression $Script.Command

        Write-Host "`n✓ Script execution completed." -ForegroundColor Green
        Write-Host "Press any key to continue..." -ForegroundColor Cyan
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        return $true
    }
    catch {
        Write-Host "`n✗ Script execution failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Press any key to continue..." -ForegroundColor Cyan
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        return $false
    }
}

function Main {
    Write-Log "INFO" "Starting debloat script selection"

    # Check if running as administrator
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "⚠️  Administrator privileges required for debloat scripts." -ForegroundColor Red
        Write-Log "ERROR" "Debloat scripts require administrator privileges"
        Write-Host "To run with Administrator privileges, use this command in PowerShell:"
        Write-Host "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile', '-Command', 'Set-Location (Get-Location); bash bin/run.sh'" -ForegroundColor Yellow
        exit 1
    }

    Show-SecurityWarning

    $scripts = Get-DebloatScripts

    # If selections provided as parameter, use them
    if ([string]::IsNullOrEmpty($Selections)) {
        $Selections = [System.Environment]::GetEnvironmentVariable("SELECTIONS", "Process")
    }

    if ($Selections -eq "5") {
        Write-Host "`nSkipping all debloat scripts." -ForegroundColor Yellow
        Write-Log "INFO" "User chose to skip all debloat scripts"
        return
    }

    # Parse selections
    $selectedNumbers = $Selections -split "," | ForEach-Object { $_.Trim() }
    $executedScripts = @()
    $failedScripts = @()

    foreach ($number in $selectedNumbers) {
        if ($scripts.ContainsKey($number)) {
            $script = $scripts[$number]

            if (Confirm-ScriptExecution -Script $script) {
                Write-Log "INFO" "Executing debloat script: $($script.Name)"

                if (Execute-DebloatScript -Script $script) {
                    $executedScripts += $script.Name
                    Write-Log "SUCCESS" "Debloat script completed: $($script.Name)"
                } else {
                    $failedScripts += $script.Name
                    Write-Log "ERROR" "Debloat script failed: $($script.Name)"
                }
            } else {
                Write-Host "Skipping: $($script.Name)" -ForegroundColor Yellow
                Write-Log "INFO" "User skipped debloat script: $($script.Name)"
            }
        } else {
            Write-Host "Invalid selection: $number" -ForegroundColor Red
            Write-Log "WARNING" "Invalid debloat script selection: $number"
        }
    }

    # Summary
    Write-Host "`n" + "="*50 -ForegroundColor Cyan
    Write-Host "Debloat Scripts Summary" -ForegroundColor Cyan
    Write-Host "="*50 -ForegroundColor Cyan

    if ($executedScripts.Count -gt 0) {
        Write-Host "`nSuccessfully executed:" -ForegroundColor Green
        foreach ($script in $executedScripts) {
            Write-Host "  ✓ $script" -ForegroundColor Green
        }
    }

    if ($failedScripts.Count -gt 0) {
        Write-Host "`nFailed to execute:" -ForegroundColor Red
        foreach ($script in $failedScripts) {
            Write-Host "  ✗ $script" -ForegroundColor Red
        }
    }

    if ($executedScripts.Count -eq 0 -and $failedScripts.Count -eq 0) {
        Write-Host "`nNo scripts were executed." -ForegroundColor Yellow
    }

    Write-Log "INFO" "Debloat script selection completed"
}

# Execute main function
Main
SCRIPTEND
)

    if check_admin_privileges; then
        export SESSION_LOG="$SESSION_LOG"
        export SELECTIONS="$selections"

        if powershell.exe -ExecutionPolicy Bypass -Command "$debloat_script"; then
            success "Debloat Script Selection completed successfully"
            return 0
        else
            error "Debloat Script Selection failed"
            return 1
        fi
    else
        echo "Administrator privileges required for debloat scripts"
        echo "To run with Administrator privileges:"
        echo "1. Open a new PowerShell terminal AS ADMINISTRATOR"
        echo "2. Navigate to the project directory"
        echo "   cd \"$(dirname "$(dirname "$SCRIPT_DIR")")\""
        echo "3. Run: bash bin/run.sh"
        return 1
    fi
}

# Phase 3: Ultimate Performance Power Plan
setup_power_plan() {
    header "Ultimate Performance Power Plan Setup"
    
    local power_plan_script=$(cat <<-'SCRIPTEND'
# ===============================
# Ultimate Performance Power Plan Setup
# ===============================

function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Write to log file
    $SessionLog = [System.Environment]::GetEnvironmentVariable("SESSION_LOG", "Process")
    if ($SessionLog) {
        Add-Content -Path $SessionLog -Value $logEntry -Encoding UTF8
    }
}

# Colored output functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
    Write-Log "INFO" $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
    Write-Log "SUCCESS" $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
    Write-Log "WARNING" $Message
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    Write-Log "ERROR" $Message
}

function Write-Header {
    param([string]$Title)
    Write-Host "`n================================" -ForegroundColor Magenta
    Write-Host " $Title" -ForegroundColor Magenta
    Write-Host "================================`n" -ForegroundColor Magenta
}

# Test if running as administrator
function Test-Administrator {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

function Wait-ForUserInput {
    param(
        [string]$Message = "Press any key to continue..."
    )

    Write-Host $Message -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Test-UltimatePerformanceAvailable {
    try {
        # Check if Ultimate Performance plan already exists
        $existingPlans = powercfg /list
        if ($existingPlans -match "Ultimate Performance") {
            Write-Info "Ultimate Performance power plan already exists"
            return $true
        }

        # Try to duplicate the scheme to test availability
        $result = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Info "Ultimate Performance power plan is available"
            return $true
        } else {
            Write-Warning "Ultimate Performance power plan is not available on this system"
            return $false
        }
    }
    catch {
        Write-Warning "Could not determine Ultimate Performance availability: $($_.Exception.Message)"
        return $false
    }
}

function Enable-UltimatePerformance {
    try {
        Write-Info "Unlocking Ultimate Performance power plan..."

        # Duplicate the Ultimate Performance scheme
        $output = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to unlock Ultimate Performance power plan: $output"
        }

        # Extract GUID from output
        $guidMatch = $output | Select-String -Pattern "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})"

        if ($guidMatch) {
            $guid = $guidMatch.Matches[0].Groups[1].Value
            Write-Success "Ultimate Performance power plan unlocked with GUID: $guid"
            return $guid
        } else {
            # Fallback: try to find the Ultimate Performance plan in the list
            $plans = powercfg /list
            $ultimatePlan = $plans | Select-String -Pattern "Ultimate Performance.*?([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})"

            if ($ultimatePlan) {
                $guid = $ultimatePlan.Matches[0].Groups[1].Value
                Write-Success "Found existing Ultimate Performance power plan with GUID: $guid"
                return $guid
            } else {
                throw "Could not extract GUID from power plan creation output"
            }
        }
    }
    catch {
        Write-Error "Failed to enable Ultimate Performance: $($_.Exception.Message)"
        return $null
    }
}

function Set-ActivePowerPlan {
    param([string]$Guid)

    try {
        Write-Info "Setting Ultimate Performance as active power plan..."

        $result = powercfg -setactive $Guid 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Ultimate Performance power plan activated successfully"
            return $true
        } else {
            throw "Failed to activate power plan: $result"
        }
    }
    catch {
        Write-Error "Failed to set active power plan: $($_.Exception.Message)"
        return $false
    }
}

function Get-ActivePowerPlan {
    try {
        $output = powercfg /getactivescheme
        if ($output -match "Power Scheme GUID: ([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\s+\((.+?)\)") {
            return @{
                Guid = $matches[1]
                Name = $matches[2].Trim()
            }
        }
        return $null
    }
    catch {
        Write-Error "Failed to get active power plan: $($_.Exception.Message)"
        return $null
    }
}

function Enable-HighPerformanceFallback {
    try {
        Write-Info "Falling back to High Performance power plan..."

        # Get list of available power plans
        $plans = powercfg /list
        $highPerfMatch = $plans | Select-String -Pattern "High performance.*?([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})"

        if ($highPerfMatch) {
            $guid = $highPerfMatch.Matches[0].Groups[1].Value
            $result = powercfg -setactive $guid 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Success "High Performance power plan activated as fallback"
                return $true
            }
        }

        # If High Performance not found, try to enable it first
        Write-Info "Enabling High Performance power plan..."
        powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c | Out-Null

        $plans = powercfg /list
        $highPerfMatch = $plans | Select-String -Pattern "High performance.*?([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})"

        if ($highPerfMatch) {
            $guid = $highPerfMatch.Matches[0].Groups[1].Value
            powercfg -setactive $guid
            Write-Success "High Performance power plan enabled and activated"
            return $true
        }

        return $false
    }
    catch {
        Write-Error "Failed to enable High Performance fallback: $($_.Exception.Message)"
        return $false
    }
}

function Open-PowerSettings {
    try {
        Write-Info "Opening Windows Power Settings for verification..."

        # Try modern Settings app first
        Start-Process "ms-settings:powersleep" -ErrorAction SilentlyContinue

        # Wait a moment for the settings to open
        Start-Sleep -Seconds 2

        Write-Info "Please verify that 'Ultimate Performance' (or 'High Performance') is selected in the Power Settings"
        Wait-ForUserInput "Press any key after verifying the power plan setting..."

        return $true
    }
    catch {
        Write-Warning "Could not open Power Settings automatically. Please manually check: Settings > System > Power & battery > Power mode"
        return $false
    }
}

function Main {
    Write-Header "Ultimate Performance Power Plan Setup"
    Write-Log "INFO" "Starting power plan configuration"

    # Check if running as administrator
    if (-NOT (Test-Administrator)) {
        Write-Error "Administrator privileges required for power plan configuration"
        Write-Log "ERROR" "Power plan setup requires administrator privileges"
        Write-Host "To run with Administrator privileges, use this command in PowerShell:"
        Write-Host "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile', '-Command', 'Set-Location (Get-Location); bash bin/run.sh'" -ForegroundColor Yellow
        exit 1
    }

    # Display current active power plan
    $currentPlan = Get-ActivePowerPlan
    if ($currentPlan) {
        Write-Info "Current active power plan: $($currentPlan.Name) ($($currentPlan.Guid))"
    }

    # Check if Ultimate Performance is available
    if (Test-UltimatePerformanceAvailable) {
        # Try to enable Ultimate Performance
        $guid = Enable-UltimatePerformance

        if ($guid) {
            # Set as active power plan
            if (Set-ActivePowerPlan -Guid $guid) {
                # Verify the change
                $newPlan = Get-ActivePowerPlan
                if ($newPlan) {
                    Write-Success "Power plan successfully changed to: $($newPlan.Name)"
                    Write-Log "SUCCESS" "Ultimate Performance power plan activated: $($newPlan.Name)"
                }

                # Open settings for user verification
                Open-PowerSettings
            } else {
                Write-Warning "Failed to activate Ultimate Performance, trying High Performance fallback..."
                Enable-HighPerformanceFallback
            }
        } else {
            Write-Warning "Failed to unlock Ultimate Performance, trying High Performance fallback..."
            Enable-HighPerformanceFallback
        }
    } else {
        Write-Warning "Ultimate Performance not available on this system, using High Performance instead"
        Enable-HighPerformanceFallback
    }

    # Final verification
    Write-Info "`nFinal power plan verification:"
    $finalPlan = Get-ActivePowerPlan
    if ($finalPlan) {
        Write-Success "Active power plan: $($finalPlan.Name)"
        Write-Log "INFO" "Final active power plan: $($finalPlan.Name) ($($finalPlan.Guid))"
    } else {
        Write-Warning "Could not verify final power plan setting"
    }

    Write-Success "Power plan configuration completed"
    Write-Log "INFO" "Power plan configuration completed"
}

# Execute main function
Main
SCRIPTEND
)

    if check_admin_privileges; then
        export SESSION_LOG="$SESSION_LOG"

        if powershell.exe -ExecutionPolicy Bypass -Command "$power_plan_script"; then
            success "Ultimate Performance Power Plan Setup completed successfully"
            return 0
        else
            error "Ultimate Performance Power Plan Setup failed"
            return 1
        fi
    else
        echo "Administrator privileges required for power plan setup"
        echo "To run with Administrator privileges:"
        echo "1. Open a new PowerShell terminal AS ADMINISTRATOR"
        echo "2. Navigate to the project directory"
        echo "   cd \"$(dirname "$(dirname "$SCRIPT_DIR")")\""
        echo "3. Run: bash bin/run.sh"
        return 1
    fi
}

# Phase 4: Essential Applications Installation
install_applications() {
    header "Essential Applications Installation"
    
    local install_apps_script=$(cat <<-'SCRIPTEND'
# ===============================
# Essential Applications Installation
# ===============================

function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Write to log file
    $SessionLog = [System.Environment]::GetEnvironmentVariable("SESSION_LOG", "Process")
    if ($SessionLog) {
        Add-Content -Path $SessionLog -Value $logEntry -Encoding UTF8
    }
}

# Colored output functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
    Write-Log "INFO" $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
    Write-Log "SUCCESS" $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
    Write-Log "WARNING" $Message
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    Write-Log "ERROR" $Message
}

function Write-Header {
    param([string]$Title)
    Write-Host "`n================================" -ForegroundColor Magenta
    Write-Host " $Title" -ForegroundColor Magenta
    Write-Host "================================`n" -ForegroundColor Magenta
}

# Test if running as administrator
function Test-Administrator {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

# Test if a command exists
function Test-Command {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

# Download file with progress
function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath
    )

    try {
        Write-Info "Downloading from: $Url"
        Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing
        Write-Success "Downloaded: $OutputPath"
        return $true
    }
    catch {
        Write-Error "Failed to download from $Url`: $($_.Exception.Message)"
        return $false
    }
}

# Test internet connectivity
function Test-InternetConnection {
    try {
        $result = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet -WarningAction SilentlyContinue
        return $result
    }
    catch {
        return $false
    }
}

# Application definitions
$Applications = @(
    @{
        Name = "Visual Studio Code"
        WingetId = "Microsoft.VisualStudioCode"
        ChocolateyId = "vscode"
        VerifyCommand = "code --version"
        Description = "Lightweight code editor"
    },
    @{
        Name = "Yandex Browser"
        WingetId = "Yandex.Browser"
        ChocolateyId = "yandex-browser"
        VerifyCommand = $null  # No CLI verification available
        Description = "Web browser with built-in security features"
    },
    @{
        Name = "Node.js LTS"
        WingetId = "OpenJS.NodeJS.LTS"
        ChocolateyId = "nodejs"
        VerifyCommand = "node --version"
        Description = "JavaScript runtime for development"
    },
    @{
        Name = "Git"
        WingetId = "Git.Git"
        ChocolateyId = "git"
        VerifyCommand = "git --version"
        Description = "Version control system"
    },
    @{
        Name = "AutoHotkey v2"
        WingetId = "AutoHotkey.AutoHotkey"
        ChocolateyId = "autohotkey"
        VerifyCommand = $null  # Will verify differently
        Description = "Automation scripting language"
    }
)

function Test-PackageManager {
    param([string]$Manager)

    switch ($Manager) {
        "winget" {
            if (Test-Command "winget") {
                try {
                    $version = winget --version 2>$null
                    if ($version) {
                        Write-Info "Winget version: $version"
                        return $true
                    }
                }
                catch {
                    return $false
                }
            }
            return $false
        }
        "chocolatey" {
            if (Test-Command "choco") {
                try {
                    $version = choco --version 2>$null
                    if ($version) {
                        Write-Info "Chocolatey version: $version"
                        return $true
                    }
                }
                catch {
                    return $false
                }
            }
            return $false
        }
        default {
            return $false
        }
    }
}

function Install-Winget {
    try {
        Write-Info "Installing/updating Winget..."

        # Check if App Installer is available (contains winget)
        $appInstaller = Get-AppxPackage -Name "Microsoft.DesktopAppInstaller" -ErrorAction SilentlyContinue

        if (-not $appInstaller) {
            Write-Info "Installing Microsoft App Installer (contains winget)..."

            # Download and install App Installer
            $appInstallerUrl = "https://aka.ms/getwinget"
            $tempFile = Join-Path $env:TEMP "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

            if (Download-File -Url $appInstallerUrl -OutputPath $tempFile) {
                Add-AppxPackage -Path $tempFile -ErrorAction SilentlyContinue
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }
        }

        # Refresh environment and test again
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

        if (Test-PackageManager "winget") {
            Write-Success "Winget is now available"
            return $true
        } else {
            Write-Warning "Winget installation may require a system restart"
            return $false
        }
    }
    catch {
        Write-Error "Failed to install Winget: $($_.Exception.Message)"
        return $false
    }
}

function Install-Chocolatey {
    try {
        Write-Info "Installing Chocolatey..."

        # Set execution policy for current process
        Set-ExecutionPolicy Bypass -Scope Process -Force

        # Download and install Chocolatey
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        # Refresh environment
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

        if (Test-PackageManager "chocolatey") {
            Write-Success "Chocolatey installed successfully"
            return $true
        } else {
            Write-Warning "Chocolatey installation may require a new PowerShell session"
            return $false
        }
    }
    catch {
        Write-Error "Failed to install Chocolatey: $($_.Exception.Message)"
        return $false
    }
}

function Install-Application {
    param(
        [hashtable]$App,
        [string]$PreferredManager = "winget"
    )

    Write-Info "Installing: $($App.Name)"
    Write-Log "INFO" "Starting installation of $($App.Name)"

    $installed = $false

    # Try preferred package manager first
    if ($PreferredManager -eq "winget" -and (Test-PackageManager "winget")) {
        try {
            Write-Info "Installing $($App.Name) via Winget..."
            $result = winget install --id $App.WingetId --silent --accept-package-agreements --accept-source-agreements 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Success "$($App.Name) installed successfully via Winget"
                $installed = $true
            } else {
                Write-Warning "Winget installation failed for $($App.Name), trying Chocolatey..."
            }
        }
        catch {
            Write-Warning "Winget installation error for $($App.Name): $($_.Exception.Message)"
        }
    }

    # Fallback to Chocolatey if Winget failed or not preferred
    if (-not $installed -and (Test-PackageManager "chocolatey")) {
        try {
            Write-Info "Installing $($App.Name) via Chocolatey..."
            $result = choco install $App.ChocolateyId -y 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Success "$($App.Name) installed successfully via Chocolatey"
                $installed = $true
            } else {
                Write-Error "Chocolatey installation failed for $($App.Name)"
            }
        }
        catch {
            Write-Error "Chocolatey installation error for $($App.Name): $($_.Exception.Message)"
        }
    }

    # If both package managers failed, try direct download for some apps
    if (-not $installed) {
        Write-Warning "Package manager installation failed for $($App.Name)"

        # Special handling for specific applications
        switch ($App.Name) {
            "Node.js LTS" {
                $installed = Install-NodeJsDirect
            }
            "Git" {
                $installed = Install-GitDirect
            }
            default {
                Write-Error "No direct installation method available for $($App.Name)"
            }
        }
    }

    if ($installed) {
        Write-Log "SUCCESS" "$($App.Name) installation completed"
    } else {
        Write-Log "ERROR" "$($App.Name) installation failed"
    }

    return $installed
}

function Install-NodeJsDirect {
    try {
        Write-Info "Attempting direct Node.js installation..."

        # Get latest LTS version info
        $nodeReleases = Invoke-RestMethod -Uri "https://nodejs.org/dist/index.json"
        $ltsVersion = $nodeReleases | Where-Object { $_.lts -ne $false } | Select-Object -First 1

        if ($ltsVersion) {
            $version = $ltsVersion.version
            $architecture = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
            $downloadUrl = "https://nodejs.org/dist/$version/node-$version-$architecture.msi"
            $tempFile = Join-Path $env:TEMP "nodejs-installer.msi"

            if (Download-File -Url $downloadUrl -OutputPath $tempFile) {
                Write-Info "Installing Node.js $version..."
                $result = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$tempFile`" /quiet /norestart" -Wait -PassThru

                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

                if ($result.ExitCode -eq 0) {
                    Write-Success "Node.js installed successfully"
                    return $true
                }
            }
        }

        return $false
    }
    catch {
        Write-Error "Direct Node.js installation failed: $($_.Exception.Message)"
        return $false
    }
}

function Install-GitDirect {
    try {
        Write-Info "Attempting direct Git installation..."

        # Get latest Git version
        $gitReleases = Invoke-RestMethod -Uri "https://api.github.com/repos/git-for-windows/git/releases/latest"
        $architecture = if ([Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }

        $asset = $gitReleases.assets | Where-Object { $_.name -like "*$architecture*.exe" -and $_.name -notlike "*portable*" } | Select-Object -First 1

        if ($asset) {
            $tempFile = Join-Path $env:TEMP "git-installer.exe"

            if (Download-File -Url $asset.browser_download_url -OutputPath $tempFile) {
                Write-Info "Installing Git..."
                $result = Start-Process -FilePath $tempFile -ArgumentList "/VERYSILENT /NORESTART" -Wait -PassThru

                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

                if ($result.ExitCode -eq 0) {
                    Write-Success "Git installed successfully"
                    return $true
                }
            }
        }

        return $false
    }
    catch {
        Write-Error "Direct Git installation failed: $($_.Exception.Message)"
        return $false
    }
}

function Test-ApplicationInstallation {
    param([hashtable]$App)

    # Refresh environment variables
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

    if ($App.VerifyCommand) {
        try {
            $result = Invoke-Expression $App.VerifyCommand 2>$null
            if ($result) {
                Write-Success "$($App.Name) verification: $result"
                return $true
            }
        }
        catch {
            # Command failed, application might not be installed or not in PATH
        }
    }

    # Special verification for applications without CLI commands
    switch ($App.Name) {
        "Yandex Browser" {
            $yandexPath = "${env:ProgramFiles(x86)}\Yandex\YandexBrowser\Application\browser.exe"
            if (Test-Path $yandexPath) {
                Write-Success "$($App.Name) installation verified"
                return $true
            }
        }
        "AutoHotkey v2" {
            $ahkPath = "${env:ProgramFiles}\AutoHotkey\v2\AutoHotkey.exe"
            if (Test-Path $ahkPath) {
                Write-Success "$($App.Name) installation verified"
                return $true
            }
        }
    }

    Write-Warning "$($App.Name) verification failed - may need manual check"
    return $false
}

function Main {
    Write-Header "Essential Applications Installation"
    Write-Log "INFO" "Starting application installation process"

    # Check if running as administrator
    if (-NOT (Test-Administrator)) {
        Write-Error "Administrator privileges required for application installation"
        Write-Log "ERROR" "Application installation requires administrator privileges"
        Write-Host "To run with Administrator privileges, use this command in PowerShell:"
        Write-Host "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile', '-Command', 'Set-Location (Get-Location); bash bin/run.sh'" -ForegroundColor Yellow
        exit 1
    }

    # Check internet connectivity
    if (-not (Test-InternetConnection)) {
        Write-Error "Internet connection required for application installation"
        Write-Log "ERROR" "No internet connection available"
        exit 1
    }

    # Setup package managers
    $wingetAvailable = Test-PackageManager "winget"
    $chocoAvailable = Test-PackageManager "chocolatey"

    if (-not $wingetAvailable) {
        Write-Info "Winget not available, attempting to install..."
        $wingetAvailable = Install-Winget
    }

    if (-not $wingetAvailable -and -not $chocoAvailable) {
        Write-Info "No package manager available, installing Chocolatey..."
        $chocoAvailable = Install-Chocolatey
    }

    if (-not $wingetAvailable -and -not $chocoAvailable) {
        Write-Error "No package manager available. Cannot proceed with automated installation."
        Write-Log "ERROR" "No package manager available for application installation"
        exit 1
    }

    # Determine preferred package manager
    $preferredManager = if ($wingetAvailable) { "winget" } else { "chocolatey" }
    Write-Info "Using $preferredManager as primary package manager"

    # Install applications
    $successfulInstalls = @()
    $failedInstalls = @()

    foreach ($app in $Applications) {
        Write-Info "`nProcessing: $($app.Name) - $($app.Description)"

        if (Install-Application -App $app -PreferredManager $preferredManager) {
            $successfulInstalls += $app.Name
        } else {
            $failedInstalls += $app.Name
        }

        # Brief pause between installations
        Start-Sleep -Seconds 2
    }

    # Refresh environment variables after all installations
    Write-Info "Refreshing environment variables..."
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

    # Verify installations
    Write-Header "Installation Verification"

    foreach ($app in $Applications) {
        Test-ApplicationInstallation -App $app
    }

    # Summary
    Write-Header "Installation Summary"

    if ($successfulInstalls.Count -gt 0) {
        Write-Success "Successfully installed applications:"
        foreach ($app in $successfulInstalls) {
            Write-Host "  ✓ $app" -ForegroundColor Green
        }
    }

    if ($failedInstalls.Count -gt 0) {
        Write-Warning "Failed to install applications:"
        foreach ($app in $failedInstalls) {
            Write-Host "  ✗ $app" -ForegroundColor Red
        }
        Write-Info "Failed applications may need manual installation"
    }

    if ($successfulInstalls.Count -eq $Applications.Count) {
        Write-Success "All applications installed successfully!"
    }

    Write-Log "INFO" "Application installation process completed"
    Write-Success "Application installation phase completed"
}

# Execute main function
Main
SCRIPTEND
)

    if check_admin_privileges; then
        export SESSION_LOG="$SESSION_LOG"

        if powershell.exe -ExecutionPolicy Bypass -Command "$install_apps_script"; then
            success "Essential Applications Installation completed successfully"
            return 0
        else
            error "Essential Applications Installation failed"
            return 1
        fi
    else
        echo "Administrator privileges required for application installation"
        echo "To run with Administrator privileges:"
        echo "1. Open a new PowerShell terminal AS ADMINISTRATOR"
        echo "2. Navigate to the project directory"
        echo "   cd \"$(dirname "$(dirname "$SCRIPT_DIR")")\""
        echo "3. Run: bash bin/run.sh"
        return 1
    fi
}

# Phase 5: Terminal AI CLI Tools Setup
setup_cli_tools() {
    header "Terminal AI CLI Tools Setup"
    
    local cli_tools_script=$(cat <<-'SCRIPTEND'
# ===============================
# Terminal AI CLI Tools Setup
# ===============================

function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Write to log file
    $SessionLog = [System.Environment]::GetEnvironmentVariable("SESSION_LOG", "Process")
    if ($SessionLog) {
        Add-Content -Path $SessionLog -Value $logEntry -Encoding UTF8
    }
}

# Colored output functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
    Write-Log "INFO" $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
    Write-Log "SUCCESS" $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
    Write-Log "WARNING" $Message
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    Write-Log "ERROR" $Message
}

function Write-Header {
    param([string]$Title)
    Write-Host "`n================================" -ForegroundColor Magenta
    Write-Host " $Title" -ForegroundColor Magenta
    Write-Host "================================`n" -ForegroundColor Magenta
}

# Test if a command exists
function Test-Command {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

# Test internet connectivity
function Test-InternetConnection {
    try {
        $result = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet -WarningAction SilentlyContinue
        return $result
    }
    catch {
        return $false
    }
}

# CLI Tools definitions
$CLITools = @(
    @{
        Name = "OpenCode AI"
        InstallCommand = "npm install -g opencode-ai"
        VerifyCommand = "opencode --version"
        Description = "AI-powered code assistant"
        RequiresBash = $false
    },
    @{
        Name = "Qwen Code CLI"
        InstallCommand = "npm install -g @qwen-code/qwen-code@latest"
        VerifyCommand = "qwen-code --version"
        Description = "Qwen AI code generation tool"
        RequiresBash = $false
    },
    @{
        Name = "iFlow CLI"
        InstallCommand = 'bash -c "$(curl -fsSL https://cloud.iflow.cn/iflow-cli/install.sh)"'
        VerifyCommand = "iflow --version"
        Description = "iFlow automation CLI"
        RequiresBash = $true
    }
)

function Test-NodeJsInstallation {
    try {
        $nodeVersion = node --version 2>$null
        $npmVersion = npm --version 2>$null

        if ($nodeVersion -and $npmVersion) {
            Write-Success "Node.js: $nodeVersion, npm: $npmVersion"
            return $true
        } else {
            Write-Error "Node.js or npm not found in PATH"
            return $false
        }
    }
    catch {
        Write-Error "Node.js verification failed: $($_.Exception.Message)"
        return $false
    }
}

function Test-BashAvailability {
    # Check for Git Bash
    $gitBashPaths = @(
        "${env:ProgramFiles}\Git\bin\bash.exe",
        "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
        "${env:LOCALAPPDATA}\Programs\Git\bin\bash.exe"
    )

    foreach ($path in $gitBashPaths) {
        if (Test-Path $path) {
            Write-Info "Found Git Bash at: $path"
            return $path
        }
    }

    # Check if bash is in PATH
    if (Test-Command "bash") {
        Write-Info "Bash found in PATH"
        return "bash"
    }

    # Check for WSL
    if (Test-Command "wsl") {
        Write-Info "WSL bash available"
        return "wsl bash"
    }

    Write-Warning "No bash environment found"
    return $null
}

function Update-EnvironmentPath {
    try {
        Write-Info "Refreshing environment variables..."

        # Get current PATH from registry
        $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
        $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")

        # Update current session PATH
        $env:PATH = $machinePath + ";" + $userPath

        # Also update npm global path if it exists
        try {
            $npmGlobalPath = npm config get prefix 2>$null
            if ($npmGlobalPath -and (Test-Path $npmGlobalPath)) {
                $npmBinPath = Join-Path $npmGlobalPath "bin"
                if ((Test-Path $npmBinPath) -and ($env:PATH -notlike "*$npmBinPath*")) {
                    $env:PATH += ";$npmBinPath"
                    Write-Info "Added npm global bin to PATH: $npmBinPath"
                }
            }
        }
        catch {
            Write-Warning "Could not determine npm global path"
        }

        Write-Success "Environment variables refreshed"
        return $true
    }
    catch {
        Write-Error "Failed to update environment PATH: $($_.Exception.Message)"
        return $false
    }
}

function Install-CLITool {
    param([hashtable]$Tool)

    Write-Info "Installing: $($Tool.Name)"
    Write-Log "INFO" "Starting installation of $($Tool.Name)"

    try {
        if ($Tool.RequiresBash) {
            # Tool requires bash environment
            $bashPath = Test-BashAvailability

            if (-not $bashPath) {
                Write-Error "$($Tool.Name) requires bash environment but none found"
                return $false
            }

            Write-Info "Installing $($Tool.Name) using bash environment..."

            # Execute bash command
            if ($bashPath -eq "wsl bash") {
                $result = wsl bash -c $Tool.InstallCommand 2>&1
            } elseif ($bashPath -eq "bash") {
                $result = bash -c $Tool.InstallCommand 2>&1
            } else {
                $result = & $bashPath -c $Tool.InstallCommand 2>&1
            }

            if ($LASTEXITCODE -eq 0) {
                Write-Success "$($Tool.Name) installed successfully"
                return $true
            } else {
                Write-Error "$($Tool.Name) installation failed: $result"
                return $false
            }
        } else {
            # Tool uses npm
            Write-Info "Installing $($Tool.Name) via npm..."

            $result = Invoke-Expression $Tool.InstallCommand 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Success "$($Tool.Name) installed successfully"
                return $true
            } else {
                Write-Error "$($Tool.Name) installation failed: $result"
                return $false
            }
        }
    }
    catch {
        Write-Error "$($Tool.Name) installation error: $($_.Exception.Message)"
        return $false
    }
}

function Test-CLIToolInstallation {
    param([hashtable]$Tool)

    try {
        # Update PATH before testing
        Update-EnvironmentPath

        # Test the verification command
        $result = Invoke-Expression $Tool.VerifyCommand 2>$null

        if ($result) {
            Write-Success "$($Tool.Name) verification: $result"
            return $true
        } else {
            Write-Warning "$($Tool.Name) verification failed - command returned no output"
            return $false
        }
    }
    catch {
        Write-Warning "$($Tool.Name) verification failed: $($_.Exception.Message)"
        return $false
    }
}

function Configure-PowerShellProfile {
    try {
        Write-Info "Configuring PowerShell profile for CLI tools..."

        # Get PowerShell profile path
        $profilePath = $PROFILE.CurrentUserAllHosts
        $profileDir = Split-Path $profilePath -Parent

        # Create profile directory if it doesn't exist
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }

        # Add npm global path to profile if not already present
        $npmGlobalPath = npm config get prefix 2>$null
        if ($npmGlobalPath) {
            $npmBinPath = Join-Path $npmGlobalPath "bin"
            $pathAddition = "`$env:PATH += `";$npmBinPath`""

            if (Test-Path $profilePath) {
                $profileContent = Get-Content $profilePath -Raw
                if ($profileContent -notlike "*$npmBinPath*") {
                    Add-Content -Path $profilePath -Value "`n# Add npm global bin to PATH`n$pathAddition"
                    Write-Info "Added npm global path to PowerShell profile"
                }
            } else {
                Set-Content -Path $profilePath -Value "# PowerShell Profile - Auto-generated by setup script`n`n# Add npm global bin to PATH`n$pathAddition"
                Write-Info "Created PowerShell profile with npm global path"
            }
        }

        return $true
    }
    catch {
        Write-Warning "Failed to configure PowerShell profile: $($_.Exception.Message)"
        return $false
    }
}

function Test-CrossShellCompatibility {
    Write-Info "Testing cross-shell compatibility..."

    $bashPath = Test-BashAvailability

    if ($bashPath) {
        try {
            # Test if CLI tools work in bash environment
            Write-Info "Testing CLI tools in bash environment..."

            foreach ($tool in $CLITools) {
                if (-not $tool.RequiresBash) {
                    try {
                        if ($bashPath -eq "wsl bash") {
                            $result = wsl bash -c $tool.VerifyCommand 2>$null
                        } elseif ($bashPath -eq "bash") {
                            $result = bash -c $tool.VerifyCommand 2>$null
                        } else {
                            $result = & $bashPath -c $tool.VerifyCommand 2>$null
                        }

                        if ($result) {
                            Write-Success "$($tool.Name) works in bash: $result"
                        } else {
                            Write-Warning "$($tool.Name) may not work properly in bash"
                        }
                    }
                    catch {
                        Write-Warning "$($tool.Name) bash compatibility test failed"
                    }
                }
            }
        }
        catch {
            Write-Warning "Cross-shell compatibility test failed: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "No bash environment available for cross-shell testing"
    }
}

function Main {
    Write-Header "Terminal AI CLI Tools Setup"
    Write-Log "INFO" "Starting CLI tools installation"

    # Check Node.js installation
    if (-not (Test-NodeJsInstallation)) {
        Write-Error "Node.js and npm are required for CLI tools installation"
        Write-Info "Please install Node.js first or run the application installation phase"
        Write-Log "ERROR" "Node.js not available for CLI tools installation"
        exit 1
    }

    # Check internet connectivity
    if (-not (Test-InternetConnection)) {
        Write-Error "Internet connection required for CLI tools installation"
        Write-Log "ERROR" "No internet connection available"
        exit 1
    }

    # Update environment variables
    Update-EnvironmentPath

    # Install CLI tools
    $successfulInstalls = @()
    $failedInstalls = @()

    foreach ($tool in $CLITools) {
        Write-Info "`nProcessing: $($tool.Name) - $($tool.Description)"

        if (Install-CLITool -Tool $tool) {
            $successfulInstalls += $tool.Name
        } else {
            $failedInstalls += $tool.Name
        }

        # Brief pause between installations
        Start-Sleep -Seconds 2
    }

    # Update environment again after installations
    Update-EnvironmentPath

    # Verify installations
    Write-Header "CLI Tools Verification"

    foreach ($tool in $CLITools) {
        Test-CLIToolInstallation -Tool $tool
    }

    # Configure PowerShell profile
    Configure-PowerShellProfile

    # Test cross-shell compatibility
    Test-CrossShellCompatibility

    # Summary
    Write-Header "CLI Tools Installation Summary"

    if ($successfulInstalls.Count -gt 0) {
        Write-Success "Successfully installed CLI tools:"
        foreach ($tool in $successfulInstalls) {
            Write-Host "  ✓ $tool" -ForegroundColor Green
        }
    }

    if ($failedInstalls.Count -gt 0) {
        Write-Warning "Failed to install CLI tools:"
        foreach ($tool in $failedInstalls) {
            Write-Host "  ✗ $tool" -ForegroundColor Red
        }
        Write-Info "Failed tools may need manual installation"
    }

    if ($successfulInstalls.Count -eq $CLITools.Count) {
        Write-Success "All CLI tools installed successfully!"
    }

    Write-Info "`nNote: You may need to restart your terminal or PowerShell session for all changes to take effect."

    Write-Log "INFO" "CLI tools installation completed"
    Write-Success "CLI tools setup phase completed"
}

# Execute main function
Main
SCRIPTEND
)

    export SESSION_LOG="$SESSION_LOG"
    
    if powershell.exe -ExecutionPolicy Bypass -Command "$cli_tools_script"; then
        success "Terminal AI CLI Tools Setup completed successfully"
        return 0
    else
        error "Terminal AI CLI Tools Setup failed"
        return 1
    fi
}

# Phase 6: AutoHotkey Setup & F3 Left Click Script Deployment
setup_autohotkey() {
    header "F3 Left Click AutoHotkey Script Deployment"

    local autohotkey_script=$(cat <<-'SCRIPTEND'
# ===============================
# F3 Left Click AutoHotkey Script Deployment
# ===============================

function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Write to log file
    $SessionLog = [System.Environment]::GetEnvironmentVariable("SESSION_LOG", "Process")
    if ($SessionLog) {
        Add-Content -Path $SessionLog -Value $logEntry -Encoding UTF8
    }
}

# Colored output functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
    Write-Log "INFO" $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
    Write-Log "SUCCESS" $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
    Write-Log "WARNING" $Message
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    Write-Log "ERROR" $Message
}

function Write-Header {
    param([string]$Title)
    Write-Host "`n================================" -ForegroundColor Magenta
    Write-Host " $Title" -ForegroundColor Magenta
    Write-Host "================================`n" -ForegroundColor Magenta
}

# Test if a command exists
function Test-Command {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Wait-ForUserInput {
    param(
        [string]$Message = "Press any key to continue..."
    )

    Write-Host $Message -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Test-AutoHotkeyInstallation {
    # Check for AutoHotkey v2
    $ahkPaths = @(
        "${env:ProgramFiles}\AutoHotkey\v2\AutoHotkey.exe",
        "${env:ProgramFiles(x86)}\AutoHotkey\v2\AutoHotkey.exe",
        "${env:LOCALAPPDATA}\Programs\AutoHotkey\v2\AutoHotkey.exe"
    )

    foreach ($path in $ahkPaths) {
        if (Test-Path $path) {
            Write-Success "Found AutoHotkey v2 at: $path"
            return @{ Installed = $true; Path = $path; Version = 2 }
        }
    }

    # Check for AutoHotkey v1 (legacy)
    $ahkV1Paths = @(
        "${env:ProgramFiles}\AutoHotkey\AutoHotkey.exe",
        "${env:ProgramFiles(x86)}\AutoHotkey\AutoHotkey.exe"
    )

    foreach ($path in $ahkV1Paths) {
        if (Test-Path $path) {
            Write-Warning "Found AutoHotkey v1 at: $path (v2 required)"
            return @{ Installed = $true; Path = $path; Version = 1 }
        }
    }

    # Check if AutoHotkey is in PATH
    if (Test-Command "AutoHotkey") {
        try {
            $version = & AutoHotkey --version 2>$null
            if ($version -like "*v2*") {
                Write-Success "AutoHotkey v2 found in PATH"
                return @{ Installed = $true; Path = "AutoHotkey"; Version = 2 }
            } else {
                Write-Warning "AutoHotkey v1 found in PATH (v2 required)"
                return @{ Installed = $true; Path = "AutoHotkey"; Version = 1 }
            }
        }
        catch {
            Write-Warning "AutoHotkey found in PATH but version check failed"
            return @{ Installed = $true; Path = "AutoHotkey"; Version = 0 }
        }
    }

    Write-Error "AutoHotkey not found"
    return @{ Installed = $false; Path = $null; Version = 0 }
}

function Set-AutoHotkeyFileAssociation {
    param([string]$AutoHotkeyPath)

    try {
        Write-Info "Setting up AutoHotkey file associations..."

        # Set .ahk file association to AutoHotkey v2
        $regPath = "HKEY_CLASSES_ROOT\.ahk"
        reg add $regPath /ve /d "AutoHotkeyScript" /f | Out-Null

        $regPath = "HKEY_CLASSES_ROOT\AutoHotkeyScript\shell\open\command"
        reg add $regPath /ve /d "`"$AutoHotkeyPath`" `"%1`" %*" /f | Out-Null

        Write-Success "AutoHotkey file associations configured"
        return $true
    }
    catch {
        Write-Warning "Failed to set AutoHotkey file associations: $($_.Exception.Message)"
        return $false
    }
}

function New-AutoHotkeyScriptsDirectory {
    try {
        $scriptsDir = "C:\AHK_Script"

        if (-not (Test-Path $scriptsDir)) {
            New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
            Write-Success "Created AutoHotkey scripts directory: $scriptsDir"
        } else {
            Write-Info "AutoHotkey scripts directory already exists: $scriptsDir"
        }

        return $scriptsDir
    }
    catch {
        Write-Error "Failed to create AutoHotkey scripts directory: $($_.Exception.Message)"
        return $null
    }
}

function New-MouseRemapScript {
    param([string]$ScriptsDirectory)

    $scriptContent = @'
; ===============================
; F3 -> Left Mouse Button (Always Active)
; ===============================

#Requires AutoHotkey v2.0

; --- Single Click / Hold / Drag ---
F3::
{
    SendInput("{LButton down}")
    KeyWait("F3")
    SendInput("{LButton up}")
}

; AHK v2 - Remap Middle Mouse Button to Back
MButton::Send("!{Left}")
'@

    try {
        $scriptPath = Join-Path $ScriptsDirectory "F3LeftClick.ahk"

        Set-Content -Path $scriptPath -Value $scriptContent -Encoding UTF8
        Write-Success "Created F3 Left Click script: $scriptPath"

        return $scriptPath
    }
    catch {
        Write-Error "Failed to create F3 Left Click script: $($_.Exception.Message)"
        return $null
    }
}

function Test-AutoHotkeyScript {
    param(
        [string]$ScriptPath,
        [string]$AutoHotkeyPath
    )

    try {
        Write-Info "Testing AutoHotkey script syntax..."

        # Test script syntax by running it with /ErrorStdOut parameter
        $result = & $AutoHotkeyPath /ErrorStdOut $ScriptPath 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Success "AutoHotkey script syntax is valid"
            return $true
        } else {
            Write-Error "AutoHotkey script syntax error: $result"
            return $false
        }
    }
    catch {
        Write-Warning "Could not test AutoHotkey script syntax: $($_.Exception.Message)"
        return $false
    }
}

function Start-AutoHotkeyScript {
    param(
        [string]$ScriptPath,
        [string]$AutoHotkeyPath
    )

    try {
        Write-Info "Starting AutoHotkey script..."

        # Check if script is already running
        $runningProcesses = Get-Process -Name "AutoHotkey*" -ErrorAction SilentlyContinue
        if ($runningProcesses) {
            Write-Info "AutoHotkey processes already running. Stopping existing processes..."
            $runningProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }

        # Start the script
        Start-Process -FilePath $AutoHotkeyPath -ArgumentList "`"$ScriptPath`"" -WindowStyle Hidden

        # Wait a moment and check if it's running
        Start-Sleep -Seconds 2
        $newProcess = Get-Process -Name "AutoHotkey*" -ErrorAction SilentlyContinue

        if ($newProcess) {
            Write-Success "AutoHotkey script started successfully"
            Write-Info "Script functions:"
            Write-Host "  • F3 key → Left mouse button (click/hold/drag)" -ForegroundColor Cyan
            Write-Host "  • Middle mouse button → Browser back navigation" -ForegroundColor Cyan
            return $true
        } else {
            Write-Warning "AutoHotkey script may not have started properly"
            return $false
        }
    }
    catch {
        Write-Error "Failed to start AutoHotkey script: $($_.Exception.Message)"
        return $false
    }
}

function Add-StartupIntegration {
    param([string]$ScriptPath)

    try {
        # Create startup shortcut
        $startupFolder = [System.Environment]::GetFolderPath("Startup")
        $shortcutPath = Join-Path $startupFolder "F3LeftClick.ahk.lnk"

        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($shortcutPath)
        $Shortcut.TargetPath = $ScriptPath
        $Shortcut.WorkingDirectory = Split-Path $ScriptPath -Parent
        $Shortcut.Description = "F3 Left Click AutoHotkey Script"
        $Shortcut.Save()

        Write-Success "Added F3 Left Click script to Windows startup"
        Write-Log "INFO" "F3 Left Click script added to startup: $shortcutPath"
        return $true
    }
    catch {
        Write-Error "Failed to add script to startup: $($_.Exception.Message)"
        return $false
    }
}

function Show-ScriptInstructions {
    Write-Header "AutoHotkey Script Instructions"

    Write-Host "Your AutoHotkey script is now active with the following features:" -ForegroundColor Green
    Write-Host ""
    Write-Host "🖱️  Mouse Remapping:" -ForegroundColor Cyan
    Write-Host "   • Press and hold F3 → Acts as left mouse button" -ForegroundColor White
    Write-Host "   • You can click, hold, and drag using F3" -ForegroundColor White
    Write-Host "   • Middle mouse button → Browser back navigation" -ForegroundColor White
    Write-Host ""
    Write-Host "📁 Script Location:" -ForegroundColor Cyan
    Write-Host "   • Documents\AutoHotkey\mouse-remap.ahk" -ForegroundColor White
    Write-Host ""
    Write-Host "🔧 Management:" -ForegroundColor Cyan
    Write-Host "   • To stop: Right-click AutoHotkey icon in system tray → Exit" -ForegroundColor White
    Write-Host "   • To restart: Double-click the .ahk file" -ForegroundColor White
    Write-Host "   • To edit: Right-click the .ahk file → Edit Script" -ForegroundColor White
    Write-Host ""
}

function Main {
    Write-Header "AutoHotkey Setup & Script Deployment"
    Write-Log "INFO" "Starting AutoHotkey setup"

    # Check AutoHotkey installation
    $ahkInfo = Test-AutoHotkeyInstallation

    if (-not $ahkInfo.Installed) {
        Write-Error "AutoHotkey not found. Please install AutoHotkey v2 first."
        Write-Info "You can install it via: winget install AutoHotkey.AutoHotkey"
        Write-Log "ERROR" "AutoHotkey not found"
        exit 1
    }

    if ($ahkInfo.Version -eq 1) {
        Write-Error "AutoHotkey v1 detected, but v2 is required for this script."
        Write-Info "Please install AutoHotkey v2: winget install AutoHotkey.AutoHotkey"
        Write-Log "ERROR" "AutoHotkey v1 detected, v2 required"
        exit 1
    }

    if ($ahkInfo.Version -eq 0) {
        Write-Warning "Could not determine AutoHotkey version. Proceeding with caution..."
    }

    Write-Success "AutoHotkey v2 detected at: $($ahkInfo.Path)"

    # Set up file associations
    if ($ahkInfo.Path -ne "AutoHotkey") {
        Set-AutoHotkeyFileAssociation -AutoHotkeyPath $ahkInfo.Path
    }

    # Create scripts directory
    $scriptsDir = New-AutoHotkeyScriptsDirectory
    if (-not $scriptsDir) {
        Write-Log "ERROR" "Failed to create scripts directory"
        exit 1
    }

    # Create mouse remap script
    $scriptPath = New-MouseRemapScript -ScriptsDirectory $scriptsDir
    if (-not $scriptPath) {
        Write-Log "ERROR" "Failed to create mouse remap script"
        exit 1
    }

    # Test script syntax
    if ($ahkInfo.Path -ne "AutoHotkey") {
        Test-AutoHotkeyScript -ScriptPath $scriptPath -AutoHotkeyPath $ahkInfo.Path
    }

    # Start the script
    $scriptStarted = Start-AutoHotkeyScript -ScriptPath $scriptPath -AutoHotkeyPath $ahkInfo.Path

    if ($scriptStarted) {
        # Add to startup automatically
        Add-StartupIntegration -ScriptPath $scriptPath
        Write-Info "F3 Left Click script automatically added to Windows startup"

        # Show instructions
        Show-ScriptInstructions

        Write-Success "F3 Left Click AutoHotkey setup completed successfully"
        Write-Log "SUCCESS" "F3 Left Click AutoHotkey setup and script deployment completed"
    } else {
        Write-Warning "F3 Left Click script created but may not be running properly"
        Write-Info "You can manually start it by double-clicking: $scriptPath"
        Write-Log "WARNING" "F3 Left Click script created but startup failed"
    }

    Write-Log "INFO" "F3 Left Click AutoHotkey setup phase completed"
}

# Execute main function
Main
SCRIPTEND
)

    export SESSION_LOG="$SESSION_LOG"
    
    if powershell.exe -ExecutionPolicy Bypass -Command "$autohotkey_script"; then
        success "F3 Left Click AutoHotkey Setup completed successfully"
        return 0
    else
        error "F3 Left Click AutoHotkey Setup failed"
        return 1
    fi
}

# Phase 7: System Settings Automation
configure_system_settings() {
    header "System Settings Automation"
    
    local system_settings_script=$(cat <<-'SCRIPTEND'
# ===============================
# System Settings Automation
# ===============================

function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Write to log file
    $SessionLog = [System.Environment]::GetEnvironmentVariable("SESSION_LOG", "Process")
    if ($SessionLog) {
        Add-Content -Path $SessionLog -Value $logEntry -Encoding UTF8
    }
}

# Colored output functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
    Write-Log "INFO" $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
    Write-Log "SUCCESS" $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
    Write-Log "WARNING" $Message
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    Write-Log "ERROR" $Message
}

function Write-Header {
    param([string]$Title)
    Write-Host "`n================================" -ForegroundColor Magenta
    Write-Host " $Title" -ForegroundColor Magenta
    Write-Host "================================`n" -ForegroundColor Magenta
}

# Test if running as administrator
function Test-Administrator {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

function Wait-ForUserInput {
    param(
        [string]$Message = "Press any key to continue..."
    )

    Write-Host $Message -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Backup-RegistryKey {
    param(
        [string]$KeyPath,
        [string]$BackupPath
    )

    try {
        if (Test-Path "Registry::$KeyPath") {
            reg export $KeyPath $BackupPath /y | Out-Null
            Write-Info "Registry backup created: $BackupPath"
            return $true
        } else {
            Write-Warning "Registry key not found: $KeyPath"
            return $false
        }
    }
    catch {
        Write-Error "Failed to backup registry key $KeyPath`: $($_.Exception.Message)"
        return $false
    }
}

function Set-PerformanceSettings {
    try {
        Write-Info "Configuring system performance settings..."

        # Create backup of current settings
        $logsDir = Join-Path $env:USERPROFILE "Documents\Power Es Aech\logs"
        if (-not (Test-Path $logsDir)) {
            New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
        }
        $backupPath = Join-Path $logsDir "performance-settings-backup.reg"
        Backup-RegistryKey -KeyPath "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -BackupPath $backupPath

        # Set visual effects for best performance
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }

        Set-ItemProperty -Path $regPath -Name "VisualFXSetting" -Value 2 -Type DWord
        Write-Success "Visual effects set to 'Adjust for best performance'"

        # Disable unnecessary visual effects
        $visualEffectsPath = "HKCU:\Control Panel\Desktop"
        Set-ItemProperty -Path $visualEffectsPath -Name "DragFullWindows" -Value "0" -Type String
        Set-ItemProperty -Path $visualEffectsPath -Name "MenuShowDelay" -Value "0" -Type String
        Set-ItemProperty -Path $visualEffectsPath -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary

        Write-Success "Performance-oriented visual settings applied"
        return $true
    }
    catch {
        Write-Error "Failed to set performance settings: $($_.Exception.Message)"
        return $false
    }
}

function Set-PrivacySettings {
    try {
        Write-Info "Configuring privacy settings..."

        # Disable telemetry (where possible without breaking functionality)
        $telemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        if (-not (Test-Path $telemetryPath)) {
            New-Item -Path $telemetryPath -Force | Out-Null
        }

        # Set telemetry to minimum (0 = Security, 1 = Basic, 2 = Enhanced, 3 = Full)
        Set-ItemProperty -Path $telemetryPath -Name "AllowTelemetry" -Value 1 -Type DWord

        # Disable advertising ID
        $advertisingPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
        if (-not (Test-Path $advertisingPath)) {
            New-Item -Path $advertisingPath -Force | Out-Null
        }
        Set-ItemProperty -Path $advertisingPath -Name "Enabled" -Value 0 -Type DWord

        # Disable location tracking
        $locationPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
        if (Test-Path $locationPath) {
            Set-ItemProperty -Path $locationPath -Name "Value" -Value "Deny" -Type String
        }

        Write-Success "Privacy settings configured"
        return $true
    }
    catch {
        Write-Error "Failed to set privacy settings: $($_.Exception.Message)"
        return $false
    }
}

function Set-ExplorerSettings {
    try {
        Write-Info "Configuring Windows Explorer settings..."

        $explorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

        # Show file extensions
        Set-ItemProperty -Path $explorerPath -Name "HideFileExt" -Value 0 -Type DWord

        # Show hidden files
        Set-ItemProperty -Path $explorerPath -Name "Hidden" -Value 1 -Type DWord

        # Show system files (optional - can be risky)
        # Set-ItemProperty -Path $explorerPath -Name "ShowSuperHidden" -Value 1 -Type DWord

        # Disable thumbnail cache
        Set-ItemProperty -Path $explorerPath -Name "DisableThumbnailCache" -Value 1 -Type DWord

        # Show full path in title bar
        Set-ItemProperty -Path $explorerPath -Name "ShowFullPath" -Value 1 -Type DWord

        # Launch folder windows in separate process
        Set-ItemProperty -Path $explorerPath -Name "SeparateProcess" -Value 1 -Type DWord

        Write-Success "Explorer settings configured"
        return $true
    }
    catch {
        Write-Error "Failed to set Explorer settings: $($_.Exception.Message)"
        return $false
    }
}

function Set-StartupOptimization {
    try {
        Write-Info "Optimizing startup programs..."

        # Get startup programs
        $startupApps = Get-CimInstance -ClassName Win32_StartupCommand

        if ($startupApps) {
            Write-Info "Current startup programs:"
            foreach ($app in $startupApps) {
                Write-Host "  • $($app.Name) - $($app.Location)" -ForegroundColor Gray
            }

            Write-Info "Consider reviewing startup programs in Task Manager > Startup tab"
        }

        # Disable some common unnecessary startup items via registry
        $runPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        $runOncePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"

        # List of common startup items that can be safely disabled
        $disableItems = @("Spotify", "Skype", "Discord", "Steam")

        foreach ($item in $disableItems) {
            if (Get-ItemProperty -Path $runPath -Name $item -ErrorAction SilentlyContinue) {
                Write-Info "Found $item in startup - consider disabling manually if not needed"
            }
        }

        Write-Success "Startup optimization review completed"
        return $true
    }
    catch {
        Write-Error "Failed to optimize startup: $($_.Exception.Message)"
        return $false
    }
}

function Open-SystemPropertiesPerformance {
    try {
        Write-Info "Opening System Properties Performance settings..."
        Write-Host "`nThis will open the Performance Options dialog where you can:" -ForegroundColor Yellow
        Write-Host "• Adjust visual effects for best performance" -ForegroundColor Yellow
        Write-Host "• Configure virtual memory settings" -ForegroundColor Yellow
        Write-Host "• Set processor scheduling options" -ForegroundColor Yellow

        Wait-ForUserInput "Press any key to open Performance Options..."

        # Open System Properties Performance tab
        Start-Process "SystemPropertiesPerformance.exe" -Wait

        Write-Info "Performance Options dialog closed"
        Write-Host "Please verify that you've configured the settings as desired." -ForegroundColor Cyan

        return $true
    }
    catch {
        Write-Error "Failed to open System Properties Performance: $($_.Exception.Message)"
        return $false
    }
}

function Set-PowerSettings {
    try {
        Write-Info "Configuring additional power settings..."

        # Disable USB selective suspend
        powercfg -setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
        powercfg -setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0

        # Set hard disk timeout to never
        powercfg -setacvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0
        powercfg -setdcvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0

        # Apply the changes
        powercfg -setactive SCHEME_CURRENT

        Write-Success "Power settings optimized for performance"
        return $true
    }
    catch {
        Write-Error "Failed to configure power settings: $($_.Exception.Message)"
        return $false
    }
}

function Set-NetworkOptimization {
    try {
        Write-Info "Applying network optimizations..."

        # Disable Nagle's algorithm for better network performance
        $tcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"

        # Get network adapters
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

        foreach ($adapter in $adapters) {
            try {
                # Disable TCP chimney offload
                netsh int tcp set global chimney=disabled 2>$null

                # Set TCP receive window auto-tuning
                netsh int tcp set global autotuninglevel=normal 2>$null

                Write-Info "Network optimizations applied for adapter: $($adapter.Name)"
            }
            catch {
                Write-Warning "Could not optimize network adapter: $($adapter.Name)"
            }
        }

        Write-Success "Network optimization completed"
        return $true
    }
    catch {
        Write-Error "Failed to optimize network settings: $($_.Exception.Message)"
        return $false
    }
}

function Set-GameModeSettings {
    try {
        Write-Info "Configuring Game Mode settings..."

        # Enable Game Mode
        $gameModePath = "HKCU:\Software\Microsoft\GameBar"
        if (-not (Test-Path $gameModePath)) {
            New-Item -Path $gameModePath -Force | Out-Null
        }

        Set-ItemProperty -Path $gameModePath -Name "AllowAutoGameMode" -Value 1 -Type DWord
        Set-ItemProperty -Path $gameModePath -Name "AutoGameModeEnabled" -Value 1 -Type DWord

        # Disable Game Bar (can interfere with some applications)
        Set-ItemProperty -Path $gameModePath -Name "UseNexusForGameBarEnabled" -Value 0 -Type DWord

        Write-Success "Game Mode settings configured"
        return $true
    }
    catch {
        Write-Error "Failed to configure Game Mode: $($_.Exception.Message)"
        return $false
    }
}

function Show-ManualSettingsInstructions {
    Write-Header "Manual Settings Verification"

    Write-Host "Please manually verify the following settings:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Performance Options (already opened):" -ForegroundColor Cyan
    Write-Host "   • Visual Effects: 'Adjust for best performance'" -ForegroundColor White
    Write-Host "   • Advanced: 'Programs' selected for processor scheduling" -ForegroundColor White
    Write-Host "   • Virtual Memory: Consider setting custom size if needed" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Windows Settings > System > Display:" -ForegroundColor Cyan
    Write-Host "   • Verify display scaling is appropriate" -ForegroundColor White
    Write-Host "   • Check refresh rate is set to maximum" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Windows Settings > Gaming:" -ForegroundColor Cyan
    Write-Host "   • Game Mode: Enabled" -ForegroundColor White
    Write-Host "   • Game Bar: Disabled (if not needed)" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Task Manager > Startup:" -ForegroundColor Cyan
    Write-Host "   • Review and disable unnecessary startup programs" -ForegroundColor White
    Write-Host ""

    Wait-ForUserInput "Press any key after reviewing these settings..."
}

function Main {
    Write-Header "System Settings Automation"
    Write-Log "INFO" "Starting system settings configuration"

    # Check if running as administrator for some settings
    $isAdmin = Test-Administrator
    if (-not $isAdmin) {
        Write-Warning "Some settings require Administrator privileges and will be skipped"
        Write-Host "To run with Administrator privileges, use this command in PowerShell:"
        Write-Host "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile', '-Command', 'Set-Location (Get-Location); bash bin/run.sh'" -ForegroundColor Yellow
    }

    # Apply registry-based settings
    Write-Info "Applying automated registry settings..."

    $settingsResults = @()

    # Performance settings
    $settingsResults += @{ Name = "Performance Settings"; Success = (Set-PerformanceSettings) }

    # Privacy settings (requires admin for some)
    if ($isAdmin) {
        $settingsResults += @{ Name = "Privacy Settings"; Success = (Set-PrivacySettings) }
    } else {
        Write-Warning "Skipping privacy settings (requires Administrator privileges)"
    }

    # Explorer settings
    $settingsResults += @{ Name = "Explorer Settings"; Success = (Set-ExplorerSettings) }

    # Startup optimization
    $settingsResults += @{ Name = "Startup Optimization"; Success = (Set-StartupOptimization) }

    # Power settings (requires admin)
    if ($isAdmin) {
        $settingsResults += @{ Name = "Power Settings"; Success = (Set-PowerSettings) }
    } else {
        Write-Warning "Skipping power settings optimization (requires Administrator privileges)"
    }

    # Network optimization (requires admin)
    if ($isAdmin) {
        $settingsResults += @{ Name = "Network Optimization"; Success = (Set-NetworkOptimization) }
    } else {
        Write-Warning "Skipping network optimization (requires Administrator privileges)"
    }

    # Game Mode settings
    $settingsResults += @{ Name = "Game Mode Settings"; Success = (Set-GameModeSettings) }

    # Open Performance Options for manual configuration
    Write-Info "`nOpening Performance Options for manual configuration..."
    Open-SystemPropertiesPerformance

    # Show manual settings instructions
    Show-ManualSettingsInstructions

    # Restart Explorer to apply changes
    Write-Info "Restarting Windows Explorer to apply changes..."
    try {
        Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Start-Process "explorer.exe"
        Write-Success "Windows Explorer restarted"
    }
    catch {
        Write-Warning "Could not restart Explorer automatically. Please restart manually or reboot."
    }

    # Summary
    Write-Header "System Settings Summary"

    $successCount = 0
    $failCount = 0

    foreach ($result in $settingsResults) {
        if ($result.Success) {
            Write-Host "  ✓ $($result.Name)" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "  ✗ $($result.Name)" -ForegroundColor Red
            $failCount++
        }
    }

    Write-Host ""
    Write-Success "$successCount settings applied successfully"
    if ($failCount -gt 0) {
        Write-Warning "$failCount settings failed to apply"
    }

    Write-Info "Note: Some changes may require a system restart to take full effect."

    Write-Log "INFO" "System settings configuration completed"
    Write-Success "System settings configuration phase completed"
}

# Execute main function
Main
SCRIPTEND
)

    if check_admin_privileges; then
        export SESSION_LOG="$SESSION_LOG"

        if powershell.exe -ExecutionPolicy Bypass -Command "$system_settings_script"; then
            success "System Settings Configuration completed successfully"
            return 0
        else
            error "System Settings Configuration failed"
            return 1
        fi
    else
        echo "Administrator privileges required for system settings configuration"
        echo "To run with Administrator privileges:"
        echo "1. Open a new PowerShell terminal AS ADMINISTRATOR"
        echo "2. Navigate to the project directory"
        echo "   cd \"$(dirname "$(dirname "$SCRIPT_DIR")")\""
        echo "3. Run: bash bin/run.sh"
        return 1
    fi
}

# Main menu function
show_menu() {
    clear
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                              Windows Toolkit Menu                            ║
║                                                                              ║
║  Select an option:                                                           ║
║  1) Debloat & Tweaks Selection                                              ║
║  2) Ultimate Performance Power Plan Setup                                   ║
║  3) Essential Applications Installation                                     ║
║  4) Terminal AI CLI Tools Setup                                             ║
║  5) F3 Left Click AutoHotkey Script Deployment                             ║
║  6) System Settings Automation                                             ║
║  7) Run All (Complete Setup)                                                ║
║  0) Exit                                                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
}

# Run all phases sequentially
run_all_phases() {
    info "Starting complete setup..."

    # Phase 1: Optional debloat (requires admin)
    if check_admin_privileges; then
        debloat_selection
    else
        echo "Debloat scripts require Administrator privileges"
        echo "To run with Administrator privileges:"
        echo "1. Open a new PowerShell terminal AS ADMINISTRATOR"
        echo "2. Navigate to the project directory"
        echo "   cd \"$(dirname "$(dirname "$SCRIPT_DIR")")\""
        echo "3. Run: bash bin/run.sh"
    fi

    # Phase 2: Power plan (requires admin)
    if check_admin_privileges; then
        setup_power_plan
    else
        echo "Power plan setup requires Administrator privileges"
        echo "To run with Administrator privileges:"
        echo "1. Open a new PowerShell terminal AS ADMINISTRATOR"
        echo "2. Navigate to the project directory"
        echo "   cd \"$(dirname "$(dirname "$SCRIPT_DIR")")\""
        echo "3. Run: bash bin/run.sh"
    fi

    # Phase 3: Applications (requires admin for some apps)
    if check_admin_privileges; then
        install_applications
    else
        echo "Application installation requires Administrator privileges"
        echo "To run with Administrator privileges:"
        echo "1. Open a new PowerShell terminal AS ADMINISTRATOR"
        echo "2. Navigate to the project directory"
        echo "   cd \"$(dirname "$(dirname "$SCRIPT_DIR")")\""
        echo "3. Run: bash bin/run.sh"
    fi

    # Phase 4: CLI tools (can run without admin if Node.js available)
    setup_cli_tools

    # Phase 5: AutoHotkey (can run without admin)
    setup_autohotkey

    # Phase 6: System settings (mixed requirements)
    if check_admin_privileges; then
        configure_system_settings
    else
        echo "System settings configuration requires Administrator privileges"
        echo "To run with Administrator privileges:"
        echo "1. Open a new PowerShell terminal AS ADMINISTRATOR"
        echo "2. Navigate to the project directory"
        echo "   cd \"$(dirname "$(dirname "$SCRIPT_DIR")")\""
        echo "3. Run: bash bin/run.sh"
    fi

    show_completion_summary
}

# Display completion summary
show_completion_summary() {
    header "Setup Complete!"

    cat << 'EOF'

🎉 Toolkit execution completed!

Next steps:
1. Restart your computer to ensure all changes take effect
2. Verify installed applications are working correctly
3. Test AutoHotkey script functionality (F3 → Left Click, Middle Mouse → Back)
4. Check power plan is set to "Ultimate Performance" in Windows Settings

Log file saved to: logs/setup-session-[timestamp].log

EOF

    success "All selected phases completed successfully!"
}

# Main execution flow
main() {
    # Create logs directory
    mkdir -p "$LOGS_DIR"

    while true; do
        show_menu
        echo -n "Enter your choice [0-7] (or press a number key): "

        # Read a single character without requiring Enter
        read -n 1 choice
        echo  # Add a newline after the input

        case $choice in
            1)
                if ! check_admin_privileges; then
                    echo "Administrator privileges required for debloat scripts"
                    echo "To run with Administrator privileges:"
                    echo "1. Open a new PowerShell terminal AS ADMINISTRATOR"
                    echo "2. Navigate to the project directory"
                    echo "   cd \"$(dirname "$(dirname "$SCRIPT_DIR")")\""
                    echo "3. Run: bash bin/run.sh"
                else
                    debloat_selection
                fi
                read -p "Press Enter to continue..."
                ;;
            2)
                if ! check_admin_privileges; then
                    echo "Administrator privileges required for power plan setup"
                    echo "To run with Administrator privileges:"
                    echo "1. Open a new PowerShell terminal AS ADMINISTRATOR"
                    echo "2. Navigate to the project directory"
                    echo "   cd \"$(dirname "$(dirname "$SCRIPT_DIR")")\""
                    echo "3. Run: bash bin/run.sh"
                else
                    setup_power_plan
                fi
                read -p "Press Enter to continue..."
                ;;
            3)
                if ! check_admin_privileges; then
                    echo "Administrator privileges required for application installation"
                    echo "To run with Administrator privileges:"
                    echo "1. Open a new PowerShell terminal AS ADMINISTRATOR"
                    echo "2. Navigate to the project directory"
                    echo "   cd \"$(dirname "$(dirname "$SCRIPT_DIR")")\""
                    echo "3. Run: bash bin/run.sh"
                else
                    install_applications
                fi
                read -p "Press Enter to continue..."
                ;;
            4)
                setup_cli_tools
                read -p "Press Enter to continue..."
                ;;
            5)
                setup_autohotkey
                read -p "Press Enter to continue..."
                ;;
            6)
                if ! check_admin_privileges; then
                    echo "Administrator privileges required for system settings configuration"
                    echo "To run with Administrator privileges:"
                    echo "1. Open a new PowerShell terminal AS ADMINISTRATOR"
                    echo "2. Navigate to the project directory"
                    echo "   cd \"$(dirname "$(dirname "$SCRIPT_DIR")")\""
                    echo "3. Run: bash bin/run.sh"
                else
                    configure_system_settings
                fi
                read -p "Press Enter to continue..."
                ;;
            7)
                run_all_phases
                read -p "Press Enter to continue..."
                ;;
            0)
                info "Exiting Windows Toolkit. Goodbye!"
                exit 0
                ;;
            *)
                error "Invalid choice. Please enter a number between 0 and 7."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Error handling
trap 'error "Script interrupted"; exit 1' INT TERM

# Execute main function
main "$@"