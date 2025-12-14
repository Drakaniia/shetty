# ===============================
# Combined Windows Setup Script
# ===============================
# This script combines all individual setup modules into a single comprehensive script
# Modules: Common Functions, Apps Installation, CLI Tools, AutoHotkey, Power Plan, System Settings, Debloat

param(
    [switch]$SkipApps,
    [switch]$SkipCLI,
    [switch]$SkipAutoHotkey,
    [switch]$SkipPowerPlan,
    [switch]$SkipSystemSettings,
    [switch]$SkipDebloat,
    [string]$DebloatSelections = ""
)

# ===============================
# COMMON FUNCTIONS MODULE
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

# ===============================
# APPLICATIONS INSTALLATION MODULE
# ===============================

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
        VerifyCommand = $null
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
        VerifyCommand = $null
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
        
        $appInstaller = Get-AppxPackage -Name "Microsoft.DesktopAppInstaller" -ErrorAction SilentlyContinue
        
        if (-not $appInstaller) {
            Write-Info "Installing Microsoft App Installer (contains winget)..."
            
            $appInstallerUrl = "https://aka.ms/getwinget"
            $tempFile = Join-Path $env:TEMP "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
            
            if (Download-File -Url $appInstallerUrl -OutputPath $tempFile) {
                Add-AppxPackage -Path $tempFile -ErrorAction SilentlyContinue
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }
        }
        
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
        
        Set-ExecutionPolicy Bypass -Scope Process -Force
        
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
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
    
    if ($installed) {
        Write-Log "SUCCESS" "$($App.Name) installation completed"
    } else {
        Write-Log "ERROR" "$($App.Name) installation failed"
    }
    
    return $installed
}

function Test-ApplicationInstallation {
    param([hashtable]$App)
    
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
        }
    }
    
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

function Install-Applications {
    Write-Header "Essential Applications Installation"
    Write-Log "INFO" "Starting application installation process"
    
    if (-NOT (Test-Administrator)) {
        Write-Error "Administrator privileges required for application installation"
        Write-Log "ERROR" "Application installation requires administrator privileges"
        return $false
    }
    
    if (-not (Test-InternetConnection)) {
        Write-Error "Internet connection required for application installation"
        Write-Log "ERROR" "No internet connection available"
        return $false
    }
    
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
        return $false
    }
    
    $preferredManager = if ($wingetAvailable) { "winget" } else { "chocolatey" }
    Write-Info "Using $preferredManager as primary package manager"
    
    $successfulInstalls = @()
    $failedInstalls = @()
    
    foreach ($app in $Applications) {
        Write-Info "`nProcessing: $($app.Name) - $($app.Description)"
        
        if (Install-Application -App $app -PreferredManager $preferredManager) {
            $successfulInstalls += $app.Name
        } else {
            $failedInstalls += $app.Name
        }
        
        Start-Sleep -Seconds 2
    }
    
    Write-Info "Refreshing environment variables..."
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    
    Write-Header "Installation Verification"
    
    foreach ($app in $Applications) {
        Test-ApplicationInstallation -App $app
    }
    
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
    return $successfulInstalls.Count -gt 0
}

# ===============================
# CLI TOOLS MODULE
# ===============================

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
    
    if (Test-Command "bash") {
        Write-Info "Bash found in PATH"
        return "bash"
    }
    
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
        
        $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
        $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
        
        $env:PATH = $machinePath + ";" + $userPath
        
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
            $bashPath = Test-BashAvailability
            
            if (-not $bashPath) {
                Write-Error "$($Tool.Name) requires bash environment but none found"
                return $false
            }
            
            Write-Info "Installing $($Tool.Name) using bash environment..."
            
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
        Update-EnvironmentPath
        
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

function Install-CLITools {
    Write-Header "Terminal AI CLI Tools Setup"
    Write-Log "INFO" "Starting CLI tools installation"
    
    if (-not (Test-NodeJsInstallation)) {
        Write-Error "Node.js and npm are required for CLI tools installation"
        Write-Info "Please install Node.js first or run the application installation phase"
        Write-Log "ERROR" "Node.js not available for CLI tools installation"
        return $false
    }
    
    if (-not (Test-InternetConnection)) {
        Write-Error "Internet connection required for CLI tools installation"
        Write-Log "ERROR" "No internet connection available"
        return $false
    }
    
    Update-EnvironmentPath
    
    $successfulInstalls = @()
    $failedInstalls = @()
    
    foreach ($tool in $CLITools) {
        Write-Info "`nProcessing: $($tool.Name) - $($tool.Description)"
        
        if (Install-CLITool -Tool $tool) {
            $successfulInstalls += $tool.Name
        } else {
            $failedInstalls += $tool.Name
        }
        
        Start-Sleep -Seconds 2
    }
    
    Update-EnvironmentPath
    
    Write-Header "CLI Tools Verification"
    
    foreach ($tool in $CLITools) {
        Test-CLIToolInstallation -Tool $tool
    }
    
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
    return $successfulInstalls.Count -gt 0
}

# ===============================
# AUTOHOTKEY MODULE
# ===============================

function Test-AutoHotkeyInstallation {
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
        $scriptsDir = Join-Path $env:USERPROFILE "Documents\AutoHotkey"
        
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
; Full F3 -> Left Mouse Button
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
        $scriptPath = Join-Path $ScriptsDirectory "mouse-remap.ahk"
        
        Set-Content -Path $scriptPath -Value $scriptContent -Encoding UTF8
        Write-Success "Created mouse remap script: $scriptPath"
        
        return $scriptPath
    }
    catch {
        Write-Error "Failed to create mouse remap script: $($_.Exception.Message)"
        return $null
    }
}

function Start-AutoHotkeyScript {
    param(
        [string]$ScriptPath,
        [string]$AutoHotkeyPath
    )
    
    try {
        Write-Info "Starting AutoHotkey script..."
        
        $runningProcesses = Get-Process -Name "AutoHotkey*" -ErrorAction SilentlyContinue
        if ($runningProcesses) {
            Write-Info "AutoHotkey processes already running. Stopping existing processes..."
            $runningProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
        
        Start-Process -FilePath $AutoHotkeyPath -ArgumentList "`"$ScriptPath`"" -WindowStyle Hidden
        
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
    
    Write-Info "Would you like to add the AutoHotkey script to Windows startup?"
    Write-Host "This will automatically start the mouse remapping when Windows starts." -ForegroundColor Yellow
    
    $response = Read-Host "Add to startup? (y/N)"
    
    if ($response -match "^[Yy]$") {
        try {
            $startupFolder = [System.Environment]::GetFolderPath("Startup")
            $shortcutPath = Join-Path $startupFolder "AutoHotkey-MouseRemap.lnk"
            
            $WshShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($shortcutPath)
            $Shortcut.TargetPath = $ScriptPath
            $Shortcut.WorkingDirectory = Split-Path $ScriptPath -Parent
            $Shortcut.Description = "AutoHotkey Mouse Remap Script"
            $Shortcut.Save()
            
            Write-Success "Added AutoHotkey script to Windows startup"
            Write-Log "INFO" "AutoHotkey script added to startup: $shortcutPath"
            return $true
        }
        catch {
            Write-Error "Failed to add script to startup: $($_.Exception.Message)"
            return $false
        }
    } else {
        Write-Info "Skipping startup integration"
        return $false
    }
}

function Setup-AutoHotkey {
    Write-Header "AutoHotkey Setup & Script Deployment"
    Write-Log "INFO" "Starting AutoHotkey setup"
    
    $ahkInfo = Test-AutoHotkeyInstallation
    
    if (-not $ahkInfo.Installed) {
        Write-Error "AutoHotkey not found. Please install AutoHotkey v2 first."
        Write-Info "You can install it via: winget install AutoHotkey.AutoHotkey"
        Write-Log "ERROR" "AutoHotkey not found"
        return $false
    }
    
    if ($ahkInfo.Version -eq 1) {
        Write-Error "AutoHotkey v1 detected, but v2 is required for this script."
        Write-Info "Please install AutoHotkey v2: winget install AutoHotkey.AutoHotkey"
        Write-Log "ERROR" "AutoHotkey v1 detected, v2 required"
        return $false
    }
    
    if ($ahkInfo.Version -eq 0) {
        Write-Warning "Could not determine AutoHotkey version. Proceeding with caution..."
    }
    
    Write-Success "AutoHotkey v2 detected at: $($ahkInfo.Path)"
    
    if ($ahkInfo.Path -ne "AutoHotkey") {
        Set-AutoHotkeyFileAssociation -AutoHotkeyPath $ahkInfo.Path
    }
    
    $scriptsDir = New-AutoHotkeyScriptsDirectory
    if (-not $scriptsDir) {
        Write-Log "ERROR" "Failed to create scripts directory"
        return $false
    }
    
    $scriptPath = New-MouseRemapScript -ScriptsDirectory $scriptsDir
    if (-not $scriptPath) {
        Write-Log "ERROR" "Failed to create mouse remap script"
        return $false
    }
    
    $scriptStarted = Start-AutoHotkeyScript -ScriptPath $scriptPath -AutoHotkeyPath $ahkInfo.Path
    
    if ($scriptStarted) {
        Add-StartupIntegration -ScriptPath $scriptPath
        
        Write-Host "`nYour AutoHotkey script is now active with the following features:" -ForegroundColor Green
        Write-Host ""
        Write-Host "🖱️  Mouse Remapping:" -ForegroundColor Cyan
        Write-Host "   • Press and hold F3 → Acts as left mouse button" -ForegroundColor White
        Write-Host "   • You can click, hold, and drag using F3" -ForegroundColor White
        Write-Host "   • Middle mouse button → Browser back navigation" -ForegroundColor White
        Write-Host ""
        Write-Host "📁 Script Location:" -ForegroundColor Cyan
        Write-Host "   • Documents\AutoHotkey\mouse-remap.ahk" -ForegroundColor White
        Write-Host ""
        
        Write-Success "AutoHotkey setup completed successfully"
        Write-Log "SUCCESS" "AutoHotkey setup and script deployment completed"
    } else {
        Write-Warning "AutoHotkey script created but may not be running properly"
        Write-Info "You can manually start it by double-clicking: $scriptPath"
        Write-Log "WARNING" "AutoHotkey script created but startup failed"
    }
    
    Write-Log "INFO" "AutoHotkey setup phase completed"
    return $scriptStarted
}

# ===============================
# POWER PLAN MODULE
# ===============================

function Test-UltimatePerformanceAvailable {
    try {
        $existingPlans = powercfg /list
        if ($existingPlans -match "Ultimate Performance") {
            Write-Info "Ultimate Performance power plan already exists"
            return $true
        }
        
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
        
        $output = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to unlock Ultimate Performance power plan: $output"
        }
        
        $guidMatch = $output | Select-String -Pattern "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})"
        
        if ($guidMatch) {
            $guid = $guidMatch.Matches[0].Groups[1].Value
            Write-Success "Ultimate Performance power plan unlocked with GUID: $guid"
            return $guid
        } else {
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

function Setup-PowerPlan {
    Write-Header "Ultimate Performance Power Plan Setup"
    Write-Log "INFO" "Starting power plan configuration"
    
    if (-NOT (Test-Administrator)) {
        Write-Error "Administrator privileges required for power plan configuration"
        Write-Log "ERROR" "Power plan setup requires administrator privileges"
        return $false
    }
    
    $currentPlan = Get-ActivePowerPlan
    if ($currentPlan) {
        Write-Info "Current active power plan: $($currentPlan.Name) ($($currentPlan.Guid))"
    }
    
    if (Test-UltimatePerformanceAvailable) {
        $guid = Enable-UltimatePerformance
        
        if ($guid) {
            if (Set-ActivePowerPlan -Guid $guid) {
                $newPlan = Get-ActivePowerPlan
                if ($newPlan) {
                    Write-Success "Power plan successfully changed to: $($newPlan.Name)"
                    Write-Log "SUCCESS" "Ultimate Performance power plan activated: $($newPlan.Name)"
                }
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
    return $true
}

# ===============================
# SYSTEM SETTINGS MODULE
# ===============================

function Set-PerformanceSettings {
    try {
        Write-Info "Configuring system performance settings..."
        
        $backupPath = Join-Path $LogsDir "performance-settings-backup.reg"
        Backup-RegistryKey -KeyPath "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -BackupPath $backupPath
        
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        
        Set-ItemProperty -Path $regPath -Name "VisualFXSetting" -Value 2 -Type DWord
        Write-Success "Visual effects set to 'Adjust for best performance'"
        
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
        
        $telemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        if (-not (Test-Path $telemetryPath)) {
            New-Item -Path $telemetryPath -Force | Out-Null
        }
        
        Set-ItemProperty -Path $telemetryPath -Name "AllowTelemetry" -Value 1 -Type DWord
        
        $advertisingPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
        if (-not (Test-Path $advertisingPath)) {
            New-Item -Path $advertisingPath -Force | Out-Null
        }
        Set-ItemProperty -Path $advertisingPath -Name "Enabled" -Value 0 -Type DWord
        
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
        
        Set-ItemProperty -Path $explorerPath -Name "HideFileExt" -Value 0 -Type DWord
        Set-ItemProperty -Path $explorerPath -Name "Hidden" -Value 1 -Type DWord
        Set-ItemProperty -Path $explorerPath -Name "DisableThumbnailCache" -Value 1 -Type DWord
        Set-ItemProperty -Path $explorerPath -Name "ShowFullPath" -Value 1 -Type DWord
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
        
        $startupApps = Get-CimInstance -ClassName Win32_StartupCommand
        
        if ($startupApps) {
            Write-Info "Current startup programs:"
            foreach ($app in $startupApps) {
                Write-Host "  • $($app.Name) - $($app.Location)" -ForegroundColor Gray
            }
            
            Write-Info "Consider reviewing startup programs in Task Manager > Startup tab"
        }
        
        Write-Success "Startup optimization review completed"
        return $true
    }
    catch {
        Write-Error "Failed to optimize startup: $($_.Exception.Message)"
        return $false
    }
}

function Set-PowerSettings {
    try {
        Write-Info "Configuring additional power settings..."
        
        powercfg -setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
        powercfg -setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
        
        powercfg -setacvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0
        powercfg -setdcvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0
        
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
        
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        
        foreach ($adapter in $adapters) {
            try {
                netsh int tcp set global chimney=disabled 2>$null
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
        
        $gameModePath = "HKCU:\Software\Microsoft\GameBar"
        if (-not (Test-Path $gameModePath)) {
            New-Item -Path $gameModePath -Force | Out-Null
        }
        
        Set-ItemProperty -Path $gameModePath -Name "AllowAutoGameMode" -Value 1 -Type DWord
        Set-ItemProperty -Path $gameModePath -Name "AutoGameModeEnabled" -Value 1 -Type DWord
        Set-ItemProperty -Path $gameModePath -Name "UseNexusForGameBarEnabled" -Value 0 -Type DWord
        
        Write-Success "Game Mode settings configured"
        return $true
    }
    catch {
        Write-Error "Failed to configure Game Mode: $($_.Exception.Message)"
        return $false
    }
}

function Setup-SystemSettings {
    Write-Header "System Settings Automation"
    Write-Log "INFO" "Starting system settings configuration"
    
    $isAdmin = Test-Administrator
    if (-not $isAdmin) {
        Write-Warning "Some settings require Administrator privileges and will be skipped"
    }
    
    Write-Info "Applying automated registry settings..."
    
    $settingsResults = @()
    
    $settingsResults += @{ Name = "Performance Settings"; Success = (Set-PerformanceSettings) }
    
    if ($isAdmin) {
        $settingsResults += @{ Name = "Privacy Settings"; Success = (Set-PrivacySettings) }
    } else {
        Write-Warning "Skipping privacy settings (requires Administrator privileges)"
    }
    
    $settingsResults += @{ Name = "Explorer Settings"; Success = (Set-ExplorerSettings) }
    $settingsResults += @{ Name = "Startup Optimization"; Success = (Set-StartupOptimization) }
    
    if ($isAdmin) {
        $settingsResults += @{ Name = "Power Settings"; Success = (Set-PowerSettings) }
        $settingsResults += @{ Name = "Network Optimization"; Success = (Set-NetworkOptimization) }
    } else {
        Write-Warning "Skipping power and network settings optimization (requires Administrator privileges)"
    }
    
    $settingsResults += @{ Name = "Game Mode Settings"; Success = (Set-GameModeSettings) }
    
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
    return $successCount -gt 0
}

# ===============================
# DEBLOAT MODULE
# ===============================

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

function Setup-Debloat {
    param([string]$Selections = "")
    
    Write-Log "INFO" "Starting debloat script selection"
    
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "⚠️  Administrator privileges required for debloat scripts." -ForegroundColor Red
        Write-Log "ERROR" "Debloat scripts require administrator privileges"
        return $false
    }
    
    Show-SecurityWarning
    
    $scripts = Get-DebloatScripts
    
    if ([string]::IsNullOrEmpty($Selections)) {
        Write-Host "Available debloat/tweak options:" -ForegroundColor Cyan
        foreach ($key in $scripts.Keys | Sort-Object) {
            $script = $scripts[$key]
            Write-Host "$key) " -NoNewline -ForegroundColor White
            Write-Host $script.Name -NoNewline -ForegroundColor Yellow
            Write-Host " - " -NoNewline -ForegroundColor Gray
            Write-Host $script.Description -ForegroundColor Gray
        }
        Write-Host "5) Skip all debloat scripts" -ForegroundColor White
        
        $Selections = Read-Host "`nSelect options (comma-separated, e.g., 1,2 or 5 to skip)"
    }
    
    if ($Selections -eq "5") {
        Write-Host "`nSkipping all debloat scripts." -ForegroundColor Yellow
        Write-Log "INFO" "User chose to skip all debloat scripts"
        return $true
    }
    
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
    return $true
}

# ===============================
# MAIN EXECUTION
# ===============================

function Show-Usage {
    Write-Host "Combined Windows Setup Script" -ForegroundColor Cyan
    Write-Host "Usage: .\combined-setup.ps1 [options]" -ForegroundColor White
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -SkipApps         Skip application installation" -ForegroundColor White
    Write-Host "  -SkipCLI          Skip CLI tools installation" -ForegroundColor White
    Write-Host "  -SkipAutoHotkey   Skip AutoHotkey setup" -ForegroundColor White
    Write-Host "  -SkipPowerPlan    Skip power plan configuration" -ForegroundColor White
    Write-Host "  -SkipSystemSettings Skip system settings configuration" -ForegroundColor White
    Write-Host "  -SkipDebloat      Skip debloat scripts" -ForegroundColor White
    Write-Host "  -DebloatSelections '1,2,3'  Pre-select debloat options" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\combined-setup.ps1" -ForegroundColor Gray
    Write-Host "  .\combined-setup.ps1 -SkipDebloat" -ForegroundColor Gray
    Write-Host "  .\combined-setup.ps1 -DebloatSelections '1,2'" -ForegroundColor Gray
}

function Main {
    Write-Header "Combined Windows Setup Script"
    Write-Log "INFO" "Starting combined Windows setup script"
    
    Write-Host "This script will configure your Windows system with optimal settings." -ForegroundColor Green
    Write-Host "The following modules will be executed:" -ForegroundColor Cyan
    Write-Host "  1. Essential Applications Installation" -ForegroundColor White
    Write-Host "  2. CLI Tools Setup" -ForegroundColor White
    Write-Host "  3. AutoHotkey Setup" -ForegroundColor White
    Write-Host "  4. Power Plan Configuration" -ForegroundColor White
    Write-Host "  5. System Settings Optimization" -ForegroundColor White
    Write-Host "  6. Debloat Scripts (optional)" -ForegroundColor White
    Write-Host ""
    
    $results = @()
    
    # Module 1: Applications Installation
    if (-not $SkipApps) {
        $results += @{ Module = "Applications Installation"; Success = (Install-Applications) }
    } else {
        Write-Info "Skipping Applications Installation"
        $results += @{ Module = "Applications Installation"; Success = $true; Skipped = $true }
    }
    
    # Module 2: CLI Tools
    if (-not $SkipCLI) {
        $results += @{ Module = "CLI Tools Setup"; Success = (Install-CLITools) }
    } else {
        Write-Info "Skipping CLI Tools Setup"
        $results += @{ Module = "CLI Tools Setup"; Success = $true; Skipped = $true }
    }
    
    # Module 3: AutoHotkey
    if (-not $SkipAutoHotkey) {
        $results += @{ Module = "AutoHotkey Setup"; Success = (Setup-AutoHotkey) }
    } else {
        Write-Info "Skipping AutoHotkey Setup"
        $results += @{ Module = "AutoHotkey Setup"; Success = $true; Skipped = $true }
    }
    
    # Module 4: Power Plan
    if (-not $SkipPowerPlan) {
        $results += @{ Module = "Power Plan Configuration"; Success = (Setup-PowerPlan) }
    } else {
        Write-Info "Skipping Power Plan Configuration"
        $results += @{ Module = "Power Plan Configuration"; Success = $true; Skipped = $true }
    }
    
    # Module 5: System Settings
    if (-not $SkipSystemSettings) {
        $results += @{ Module = "System Settings"; Success = (Setup-SystemSettings) }
    } else {
        Write-Info "Skipping System Settings"
        $results += @{ Module = "System Settings"; Success = $true; Skipped = $true }
    }
    
    # Module 6: Debloat
    if (-not $SkipDebloat) {
        $results += @{ Module = "Debloat Scripts"; Success = (Setup-Debloat -Selections $DebloatSelections) }
    } else {
        Write-Info "Skipping Debloat Scripts"
        $results += @{ Module = "Debloat Scripts"; Success = $true; Skipped = $true }
    }
    
    # Final Summary
    Write-Header "Setup Summary"
    
    $successCount = 0
    $failCount = 0
    $skipCount = 0
    
    foreach ($result in $results) {
        if ($result.Skipped) {
            Write-Host "  ⏭ $($result.Module) (Skipped)" -ForegroundColor Yellow
            $skipCount++
        } elseif ($result.Success) {
            Write-Host "  ✓ $($result.Module)" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "  ✗ $($result.Module)" -ForegroundColor Red
            $failCount++
        }
    }
    
    Write-Host ""
    Write-Success "Setup completed: $successCount modules successful, $failCount failed, $skipCount skipped"
    
    if ($failCount -eq 0) {
        Write-Success "All executed modules completed successfully!"
        Write-Host "`n🎉 Your Windows system has been optimized!" -ForegroundColor Green
        Write-Host "Some changes may require a system restart to take full effect." -ForegroundColor Yellow
    } else {
        Write-Warning "Some modules failed. Please review the logs for details."
    }
    
    Write-Log "INFO" "Combined Windows setup script completed"
    
    if ($failCount -gt 0) {
        exit 1
    }
}

# Check for help parameter
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "-h") {
    Show-Usage
    exit 0
}

# Execute main function
Main