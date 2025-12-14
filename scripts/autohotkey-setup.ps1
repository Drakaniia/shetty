# ===============================
# AutoHotkey Setup & Script Deployment
# ===============================

# Import common functions
. "$PSScriptRoot\common-functions.ps1"

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
    
    Write-Info "Would you like to add the AutoHotkey script to Windows startup?"
    Write-Host "This will automatically start the mouse remapping when Windows starts." -ForegroundColor Yellow
    
    $response = Read-Host "Add to startup? (y/N)"
    
    if ($response -match "^[Yy]$") {
        try {
            # Create startup shortcut
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
        # Offer startup integration
        Add-StartupIntegration -ScriptPath $scriptPath
        
        # Show instructions
        Show-ScriptInstructions
        
        Write-Success "AutoHotkey setup completed successfully"
        Write-Log "SUCCESS" "AutoHotkey setup and script deployment completed"
    } else {
        Write-Warning "AutoHotkey script created but may not be running properly"
        Write-Info "You can manually start it by double-clicking: $scriptPath"
        Write-Log "WARNING" "AutoHotkey script created but startup failed"
    }
    
    Write-Log "INFO" "AutoHotkey setup phase completed"
}

# Execute main function
Main