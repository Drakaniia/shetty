# ===============================
# Common PowerShell Functions
# ===============================

# Get script directory and project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$LogsDir = Join-Path $ProjectRoot "logs"

# Ensure logs directory exists
if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
}

# Get current session log file
$SessionLog = Get-ChildItem -Path $LogsDir -Filter "setup-session-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $SessionLog) {
    $SessionLog = Join-Path $LogsDir "setup-session-$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
}

# Logging function
function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to log file
    Add-Content -Path $SessionLog -Value $logEntry -Encoding UTF8
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

# Execute command with error handling
function Invoke-SafeCommand {
    param(
        [string]$Command,
        [string]$Description = "Command",
        [switch]$IgnoreErrors
    )
    
    try {
        Write-Info "Executing: $Description"
        $result = Invoke-Expression $Command
        Write-Success "$Description completed successfully"
        return @{ Success = $true; Output = $result }
    }
    catch {
        if ($IgnoreErrors) {
            Write-Warning "$Description failed but continuing: $($_.Exception.Message)"
            return @{ Success = $false; Output = $null; Error = $_.Exception.Message }
        } else {
            Write-Error "$Description failed: $($_.Exception.Message)"
            throw
        }
    }
}

# Check if a Windows feature is enabled
function Test-WindowsFeature {
    param([string]$FeatureName)
    
    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName -ErrorAction SilentlyContinue
        return $feature.State -eq "Enabled"
    }
    catch {
        return $false
    }
}

# Get Windows version information
function Get-WindowsVersion {
    try {
        $version = Get-WmiObject -Class Win32_OperatingSystem
        return @{
            Caption = $version.Caption
            Version = $version.Version
            BuildNumber = $version.BuildNumber
            Architecture = $version.OSArchitecture
        }
    }
    catch {
        return $null
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

# Create backup of registry key
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

# Wait for user input with timeout
function Wait-ForUserInput {
    param(
        [string]$Message = "Press any key to continue...",
        [int]$TimeoutSeconds = 0
    )
    
    Write-Host $Message -ForegroundColor Cyan
    
    if ($TimeoutSeconds -gt 0) {
        $timeout = New-TimeSpan -Seconds $TimeoutSeconds
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        while ($stopwatch.Elapsed -lt $timeout) {
            if ([Console]::KeyAvailable) {
                $null = [Console]::ReadKey($true)
                break
            }
            Start-Sleep -Milliseconds 100
        }
        $stopwatch.Stop()
    } else {
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# Export functions for use in other scripts
Export-ModuleMember -Function *