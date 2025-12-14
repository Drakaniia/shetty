# ===============================
# Ultimate Performance Power Plan Setup
# ===============================

# Import common functions
. "$PSScriptRoot\common-functions.ps1"

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