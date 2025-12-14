# ===============================
# System Settings Automation
# ===============================

# Import common functions
. "$PSScriptRoot\common-functions.ps1"

function Set-PerformanceSettings {
    try {
        Write-Info "Configuring system performance settings..."
        
        # Create backup of current settings
        $backupPath = Join-Path $LogsDir "performance-settings-backup.reg"
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