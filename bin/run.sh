#!/bin/bash

# ===============================
# Post-Installation Automation Script
# ===============================
# Comprehensive Windows setup automation using Administrator PowerShell
# with support for limited GUI and keyboard automation where required.

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

# Check if running in appropriate environment
check_environment() {
    header "Phase 1: Environment Validation"
    
    # Check Windows version
    if ! command -v powershell.exe &> /dev/null; then
        error "PowerShell not found. This script requires Windows with PowerShell."
        exit 1
    fi
    
    # Check Windows version
    local windows_version=$(powershell.exe -Command "(Get-WmiObject -Class Win32_OperatingSystem).Caption" 2>/dev/null | tr -d '\r')
    info "Detected: $windows_version"
    
    if [[ ! "$windows_version" =~ (Windows 10|Windows 11) ]]; then
        warning "This script is designed for Windows 10/11. Detected: $windows_version"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Create logs directory
    mkdir -p "$LOGS_DIR"
    
    success "Environment validation completed"
    log "INFO" "Session started - Windows version: $windows_version"
}

# Check for administrator privileges
check_admin_privileges() {
    header "Administrator Elevation Check"
    
    local is_admin=$(powershell.exe -Command "([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')" 2>/dev/null | tr -d '\r')
    
    if [[ "$is_admin" == "True" ]]; then
        success "Running with Administrator privileges"
        return 0
    else
        warning "Administrator privileges required for full functionality"
        echo
        echo "To run with Administrator privileges, execute this command in PowerShell:"
        echo -e "${CYAN}Start-Process powershell -Verb RunAs -ArgumentList '-Command \"cd \\\"$(pwd)\\\"; bash bin/run.sh\"'${NC}"
        echo
        read -p "Continue without Administrator privileges? (some features will be skipped) (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
        warning "Continuing without Administrator privileges - some features will be skipped"
        return 1
    fi
}

# Execute PowerShell script
execute_powershell() {
    local script_path="$1"
    local description="$2"
    
    info "Executing: $description"
    
    if [[ ! -f "$script_path" ]]; then
        error "PowerShell script not found: $script_path"
        return 1
    fi
    
    if powershell.exe -ExecutionPolicy Bypass -File "$script_path"; then
        success "$description completed successfully"
        return 0
    else
        error "$description failed"
        return 1
    fi
}

# Phase 2: Optional Debloat & Tweaks Selection
debloat_selection() {
    header "Phase 2: Optional Debloat & Tweaks Selection"
    
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
    
    execute_powershell "$SCRIPTS_DIR/debloat-selection.ps1" "Debloat Script Selection" "$selections"
}

# Phase 3: Ultimate Performance Power Plan
setup_power_plan() {
    header "Phase 3: Ultimate Performance Power Plan Setup"
    execute_powershell "$SCRIPTS_DIR/power-plan.ps1" "Ultimate Performance Power Plan Setup"
}

# Phase 4: Essential Applications Installation
install_applications() {
    header "Phase 4: Essential Applications Installation"
    execute_powershell "$SCRIPTS_DIR/install-apps.ps1" "Essential Applications Installation"
}

# Phase 5: Terminal AI CLI Tools Setup
setup_cli_tools() {
    header "Phase 5: Terminal AI CLI Tools Setup"
    
    # Check if Node.js is available
    if ! command -v node &> /dev/null; then
        warning "Node.js not found. Installing applications first..."
        install_applications
    fi
    
    execute_powershell "$SCRIPTS_DIR/cli-tools.ps1" "CLI Tools Installation"
}

# Phase 6: AutoHotkey Setup & Script Deployment
setup_autohotkey() {
    header "Phase 6: AutoHotkey Setup & Script Deployment"
    execute_powershell "$SCRIPTS_DIR/autohotkey-setup.ps1" "AutoHotkey Setup and Script Deployment"
}

# Phase 7: System Settings Automation
configure_system_settings() {
    header "Phase 7: System Settings Automation"
    execute_powershell "$SCRIPTS_DIR/system-settings.ps1" "System Settings Configuration"
}

# Display completion summary
show_completion_summary() {
    header "Setup Complete!"
    
    cat << 'EOF'

🎉 Post-installation automation completed!

Summary of actions performed:
✓ Environment validation
✓ Administrator privilege check
✓ Optional debloat scripts (if selected)
✓ Ultimate Performance power plan activation
✓ Essential applications installation
✓ Terminal AI CLI tools setup
✓ AutoHotkey configuration and script deployment
✓ System settings optimization

Next steps:
1. Restart your computer to ensure all changes take effect
2. Verify installed applications are working correctly
3. Test AutoHotkey script functionality (F3 → Left Click, Middle Mouse → Back)
4. Check power plan is set to "Ultimate Performance" in Windows Settings

Log file saved to: logs/setup-session-[timestamp].log

EOF

    success "All phases completed successfully!"
}

# Main execution flow
main() {
    clear
    
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                    Post-Installation Automation Script                      ║
║                                                                              ║
║  Comprehensive Windows setup automation using Administrator PowerShell      ║
║  with support for limited GUI and keyboard automation where required.       ║
║                                                                              ║
║  Goal: Minimize manual setup time while maintaining system safety,          ║
║        clarity, and user control.                                           ║
╚══════════════════════════════════════════════════════════════════════════════╝

EOF

    info "Starting post-installation automation..."
    
    # Phase 1: Environment validation
    check_environment
    
    # Check for admin privileges (store result for conditional execution)
    local has_admin=false
    if check_admin_privileges; then
        has_admin=true
    fi
    
    # Phase 2: Optional debloat (requires admin)
    if [[ "$has_admin" == true ]]; then
        debloat_selection
    else
        warning "Skipping debloat scripts (requires Administrator privileges)"
    fi
    
    # Phase 3: Power plan (requires admin)
    if [[ "$has_admin" == true ]]; then
        setup_power_plan
    else
        warning "Skipping power plan setup (requires Administrator privileges)"
    fi
    
    # Phase 4: Applications (requires admin for some apps)
    if [[ "$has_admin" == true ]]; then
        install_applications
    else
        warning "Skipping application installation (requires Administrator privileges)"
    fi
    
    # Phase 5: CLI tools (can run without admin if Node.js available)
    setup_cli_tools
    
    # Phase 6: AutoHotkey (can run without admin)
    setup_autohotkey
    
    # Phase 7: System settings (mixed requirements)
    if [[ "$has_admin" == true ]]; then
        configure_system_settings
    else
        warning "Skipping system settings configuration (requires Administrator privileges)"
    fi
    
    # Show completion summary
    show_completion_summary
    
    log "INFO" "Session completed successfully"
}

# Error handling
trap 'error "Script interrupted"; exit 1' INT TERM

# Execute main function
main "$@"