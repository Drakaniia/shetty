# ===============================
# Essential Applications Installation
# ===============================

# Import common functions
. "$PSScriptRoot\common-functions.ps1"

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