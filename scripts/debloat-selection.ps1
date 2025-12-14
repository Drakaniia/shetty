# ===============================
# Debloat Script Selection Module
# ===============================

param(
    [string]$Selections = ""
)

# Import common functions
. "$PSScriptRoot\common-functions.ps1"

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
        exit 1
    }
    
    Show-SecurityWarning
    
    $scripts = Get-DebloatScripts
    
    # If selections provided as parameter, use them
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