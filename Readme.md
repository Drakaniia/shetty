# Post-Installation Automation Script

A comprehensive Windows post-installation automation script that minimizes manual setup time while maintaining system safety, clarity, and user control.

## Features

- **Modular Design**: 7 distinct phases that can be run independently
- **Safety First**: Explicit confirmations for risky operations and comprehensive logging
- **Mixed Automation**: PowerShell for system tasks with minimal GUI automation
- **User Control**: Optional components with clear selection menus

## Quick Start

1. **Prerequisites**:
   - Windows 10 or Windows 11
   - Git Bash, WSL, or similar bash environment
   - Internet connection

2. **Run the script**:
   ```bash
   # For full functionality (recommended)
   # Run PowerShell as Administrator, then:
   cd "C:\Project Files\Power Es Aech"
   bash bin/run.sh
   
   # Or from PowerShell:
   Start-Process powershell -Verb RunAs -ArgumentList '-Command "cd \"C:\Project Files\Power Es Aech\"; bash bin/run.sh"'
   ```

## What It Does

### Phase 1: Environment Validation
- **[AUTO]** Checks Windows version compatibility
- **[AUTO]** Validates bash environment
- **[AUTO]** Creates logging infrastructure

### Phase 2: Optional Debloat & Tweaks
- **[USER]** Interactive menu for debloat script selection
- **[ADMIN]** Administrator PowerShell required
- **Available Options**:
  - Win11 Debloat (raphi.re) - Removes bloatware and telemetry
  - Windows Tweaks (Chris Titus Tech) - Performance and privacy tweaks
  - Debloat11 Script - Alternative debloat approach
  - Windows Activation Script - KMS activation (legal warning included)

### Phase 3: Ultimate Performance Power Plan
- **[AUTO]** Unlocks and activates Ultimate Performance power plan
- **[ADMIN]** Administrator PowerShell required
- **[FALLBACK]** Uses High Performance if Ultimate Performance unavailable
- **[MANUAL]** Opens Windows Settings for visual confirmation

### Phase 4: Essential Applications
- **[AUTO]** Installs via winget/chocolatey with fallbacks
- **[ADMIN]** Administrator PowerShell required
- **Applications Installed**:
  - Visual Studio Code
  - Yandex Browser
  - Node.js LTS
  - Git
  - AutoHotkey v2

### Phase 5: Terminal AI CLI Tools
- **[AUTO]** Installs global npm packages and bash tools
- **Tools Installed**:
  - OpenCode AI (`npm i -g opencode-ai`)
  - Qwen Code CLI (`npm install -g @qwen-code/qwen-code@latest`)
  - iFlow CLI (bash installation)

### Phase 6: AutoHotkey Setup
- **[AUTO]** Creates and deploys mouse remapping script
- **[OPTIONAL]** Startup integration (user choice)
- **Script Features**:
  - F3 key → Left mouse button (click/hold/drag)
  - Middle mouse button → Browser back navigation

### Phase 7: System Settings
- **[AUTO]** Registry-based performance and privacy settings
- **[MANUAL]** Opens SystemPropertiesPerformance for user configuration
- **[MIXED]** Some settings require Administrator privileges

## Legend

- **[AUTO]** Runs without user input
- **[USER]** Requires explicit user approval
- **[MANUAL]** User must manually verify/configure
- **[OPTIONAL]** User can choose to skip
- **[ADMIN]** Requires Administrator privileges
- **[FALLBACK]** Has alternative if primary method fails
- **[MIXED]** Combination of automatic and manual steps

## Safety Features

1. **Comprehensive Logging**: All actions logged to `logs/setup-session-[timestamp].log`
2. **Modular Execution**: Each phase can be skipped or re-run independently
3. **Error Handling**: Graceful failure handling with clear error messages
4. **Security Warnings**: Explicit warnings for remote script execution
5. **Registry Backups**: Automatic backups before making registry changes

## File Structure

```
C:\Project Files\Power Es Aech\
├── bin/
│   └── run.sh                    # Main bash orchestration script
├── scripts/
│   ├── common-functions.ps1      # Shared PowerShell utilities & logging
│   ├── debloat-selection.ps1     # Interactive debloat script selection
│   ├── power-plan.ps1           # Ultimate Performance power plan setup
│   ├── install-apps.ps1         # Essential applications installation
│   ├── cli-tools.ps1            # Terminal AI CLI tools setup
│   ├── autohotkey-setup.ps1     # AutoHotkey configuration & deployment
│   ├── system-settings.ps1      # System settings automation
│   └── mouse-remap.ahk          # AutoHotkey script template
├── logs/                        # Auto-created for session logs & backups
├── execution-plan.md            # Detailed execution plan documentation
└── README.md                    # This file
```

## Expected Runtime

- **Full execution**: 15-30 minutes
- **Minimal setup** (skip debloat): 5-10 minutes
- **User interaction time**: 2-5 minutes total

**Note:** Runtime may vary based on:
- Internet connection speed
- System performance
- Package availability
- User response time for confirmations

## Troubleshooting

### Common Issues

1. **"PowerShell not found"**
   - Ensure you're running on Windows with PowerShell installed
   - Try running from Git Bash or WSL

2. **"Administrator privileges required"**
   - Run PowerShell as Administrator
   - Use the provided elevation command in the script output

3. **"Package manager not available"**
   - The script will attempt to install winget and/or chocolatey automatically
   - Ensure internet connection is available

4. **"AutoHotkey script not working"**
   - Verify AutoHotkey v2 is installed (not v1)
   - Check if antivirus is blocking the script
   - Manually run the script from `Documents\AutoHotkey\mouse-remap.ahk`

### Log Files

Check the session log for detailed information:
```
logs/setup-session-[timestamp].log
```

## Manual Verification Steps

After running the script, manually verify:

1. **Power Plan**: Settings > System > Power & battery → "Ultimate Performance" selected
2. **Applications**: All installed applications launch correctly
3. **AutoHotkey**: F3 acts as left mouse button, middle mouse goes back
4. **CLI Tools**: Open new terminal and test:
   ```bash
   opencode --version
   qwen-code --version
   iflow --version
   ```

## Implementation Details

### Smart Package Management
- Primary: Winget (Windows Package Manager)
- Fallback: Chocolatey package manager
- Direct downloads: For critical applications when package managers fail
- Cross-platform: Supports PowerShell, Git Bash, and WSL environments

### Error Handling & Recovery
- Comprehensive logging to timestamped log files
- Graceful degradation when Administrator privileges unavailable
- Automatic retries for network-dependent operations
- Registry backups before making system changes
- Process validation after each installation

### Security Features
- Explicit warnings before executing remote scripts
- User confirmation required for potentially risky operations
- No automatic execution of untrusted code
- Registry change backups for rollback capability
- Antivirus compatibility considerations

## Customization

To modify the script behavior:

1. **Add/Remove Applications**: Edit the `$Applications` array in `scripts/install-apps.ps1`
2. **Add/Remove CLI Tools**: Edit the `$CLITools` array in `scripts/cli-tools.ps1`
3. **Modify AutoHotkey Script**: Edit the script content in `scripts/autohotkey-setup.ps1`
4. **Change System Settings**: Modify registry operations in `scripts/system-settings.ps1`
5. **Adjust Debloat Options**: Edit available scripts in `scripts/debloat-selection.ps1`

### Advanced Customization
- **Logging Configuration**: Modify logging levels and output locations in `scripts/common-functions.ps1`
- **Error Handling**: Adjust retry logic and timeout values in individual modules
- **Registry Settings**: Add custom registry modifications to the system settings module
- **Network Configuration**: Modify download sources and fallback URLs

## Security Considerations

- **Remote Scripts**: The debloat options download and execute scripts from remote sources
- **Registry Changes**: The script modifies Windows registry for performance optimizations
- **Administrator Access**: Many features require elevated privileges
- **Antivirus**: Some antivirus software may flag AutoHotkey scripts

Always review the code before running and ensure you trust the remote script sources if you choose to use them.

## Requirements & Dependencies

### System Requirements
- **Operating System**: Windows 10 or Windows 11
- **Processor**: x64 or ARM64 architecture
- **RAM**: Minimum 4GB (8GB recommended)
- **Storage**: 2GB free space for applications and logs

### Software Dependencies
- **PowerShell 5.1+** (included with Windows)
- **Git Bash, WSL, or equivalent bash environment**
- **Internet connection** for downloading applications and tools

### Optional Dependencies
- **Administrator privileges** for full functionality
- **Windows Package Manager (winget)** - auto-installed if missing
- **Chocolatey** - fallback package manager, auto-installed if needed

## License

This script is provided as-is for educational and personal use. Use at your own risk and ensure you understand what each component does before execution.

## Support & Updates

For issues, feature requests, or contributions:
1. Check the session log files for detailed error information
2. Review the execution plan for understanding each phase
3. Test individual PowerShell modules separately for troubleshooting
4. Ensure all prerequisites are met before running the full script

## Changelog

**v1.0.0** - Initial Release
- 7-phase modular automation system
- Comprehensive application installation
- AutoHotkey script deployment
- Terminal AI CLI tools setup
- System optimization and security hardening
- Cross-shell compatibility support