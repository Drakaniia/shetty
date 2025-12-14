# ===============================
# Terminal AI CLI Tools Setup
# ===============================

# Import common functions
. "$PSScriptRoot\common-functions.ps1"

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