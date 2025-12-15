"""
System utilities for Windows Automation Toolkit
"""

import os
import sys
import ctypes
import subprocess
from pathlib import Path


class SystemUtils:
    """Core system utilities for Windows automation"""
    
    def __init__(self):
        self.is_admin = self.check_admin_privileges()
        self.user_profile = os.path.expanduser("~")
        self.documents_folder = os.path.join(self.user_profile, "Documents")
    
    def check_admin_privileges(self):
        """Check if the script is running with administrator privileges"""
        try:
            return ctypes.windll.shell32.IsUserAnAdmin()
        except:
            return False
    
    def relaunch_as_admin(self):
        """Relaunch the script with administrator privileges"""
        if not self.is_admin:
            try:
                ctypes.windll.shell32.ShellExecuteW(
                    None, "runas", sys.executable, " ".join(sys.argv), None, 1
                )
                sys.exit(0)
            except Exception as e:
                print(f"❌ Failed to relaunch as admin: {e}")
                return False
        return True
    
    def clear_screen(self):
        """Clear the console screen"""
        os.system('cls' if os.name == 'nt' else 'clear')
    
    def pause_execution(self):
        """Pause execution and wait for user input"""
        input("\n⏸️ Press Enter to continue...")
    
    def get_confirmation(self, message):
        """Get user confirmation for potentially risky operations"""
        while True:
            response = input(f"\n⚠️ {message} (y/n): ").lower().strip()
            if response in ['y', 'yes']:
                return True
            elif response in ['n', 'no']:
                return False
            else:
                print("Please enter 'y' for yes or 'n' for no")
    
    def run_powershell_command(self, command, bypass_policy=True, timeout=300):
        """Execute a PowerShell command with optional execution policy bypass"""
        try:
            ps_command = command
            if bypass_policy:
                ps_command = f"-ExecutionPolicy Bypass -Command \"{command}\""
            
            print(f"🔧 Executing: {command}")
            result = subprocess.run(
                ["powershell", ps_command],
                capture_output=True,
                text=True,
                timeout=timeout
            )
            
            if result.returncode == 0:
                print("✅ Command executed successfully")
                if result.stdout.strip():
                    print(f"📄 Output: {result.stdout.strip()}")
                return True, result.stdout
            else:
                print(f"❌ Command failed: {result.stderr.strip()}")
                return False, result.stderr
                
        except subprocess.TimeoutExpired:
            print("❌ Command timed out")
            return False, "Command timed out"
        except Exception as e:
            print(f"❌ Error executing command: {e}")
            return False, str(e)
    
    def run_powershell_script(self, script_url, description):
        """Execute a PowerShell script from URL"""
        print(f"\n{description}")
        print("=" * 50)
        
        if not self.get_confirmation(f"Run {description}? This will execute PowerShell scripts from the internet."):
            print("❌ Operation cancelled by user")
            return False
        
        command = f"[scriptblock]::Create((irm \"{script_url}\"))"
        success, output = self.run_powershell_command(command)
        return success
    
    def run_command(self, command, shell=True, timeout=60):
        """Run a system command"""
        try:
            print(f"🔧 Executing: {command}")
            result = subprocess.run(
                command,
                shell=shell,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            
            if result.returncode == 0:
                print("✅ Command executed successfully")
                if result.stdout.strip():
                    print(f"📄 Output: {result.stdout.strip()}")
                return True, result.stdout
            else:
                print(f"❌ Command failed: {result.stderr.strip()}")
                return False, result.stderr
                
        except subprocess.TimeoutExpired:
            print("❌ Command timed out")
            return False, "Command timed out"
        except Exception as e:
            print(f"❌ Error executing command: {e}")
            return False, str(e)
    
    def check_program_exists(self, program_name):
        """Check if a program is available in the system PATH"""
        try:
            subprocess.run([program_name, "--version"], 
                         capture_output=True, check=True, timeout=10)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
            return False
    
    def ensure_directory_exists(self, directory_path):
        """Ensure a directory exists, create if it doesn't"""
        try:
            Path(directory_path).mkdir(parents=True, exist_ok=True)
            return True
        except Exception as e:
            print(f"❌ Failed to create directory {directory_path}: {e}")
            return False
    
    def get_system_path(self, path_key):
        """Get system path by key"""
        paths = {
            "documents": os.path.join(self.user_profile, "Documents"),
            "startup": os.path.join(
                os.environ.get('APPDATA', ''), 
                'Microsoft', 'Windows', 'Start Menu', 'Programs', 'Startup'
            ),
            "temp": os.environ.get('TEMP', ''),
            "desktop": os.path.join(self.user_profile, "Desktop"),
            "downloads": os.path.join(self.user_profile, "Downloads")
        }
        return paths.get(path_key, "")
    
    def print_header(self, title, subtitle=""):
        """Print a formatted header"""
        self.clear_screen()
        border = "╔" + "═" * (len(title) + 4) + "╗"
        footer = "╚" + "═" * (len(title) + 4) + "╝"
        
        print(border)
        print(f"║  {title}  ║")
        if subtitle:
            subtitle_border = "╠" + "═" * (len(subtitle) + 4) + "╣"
            print(subtitle_border)
            print(f"║  {subtitle}  ║")
        print(footer)
        print(f"Running as: {'Administrator' if self.is_admin else 'User'}")
        print()
    
    def print_menu(self, title, options):
        """Print a formatted menu with left-aligned numbers and padding"""
        # Calculate the width of the longest option
        max_option_length = len(title)
        for key, option in options.items():
            option_text = f"[{key}] {option.get('title', 'Unknown')}"
            max_option_length = max(max_option_length, len(option_text))

        # Pad to ensure minimum width
        max_option_length = max(max_option_length, 40)

        # Print title with padding for alignment
        print(f"{title:<{max_option_length}}")
        print("-" * max_option_length)

        # Print each option with left-aligned numbers and padding
        for key, option in options.items():
            option_text = f"[{key}] {option.get('title', 'Unknown')}"
            print(f"{option_text:<{max_option_length}}")

        print()
    
    def get_menu_choice(self, options):
        """Get and validate menu choice with single key press on Windows or input with Enter on other systems"""
        import sys

        # Try to use Windows-specific input for single key press
        try:
            import msvcrt  # Windows-specific module

            print(f"Select option by pressing the number key: ", end="", flush=True)

            while True:
                if msvcrt.kbhit():
                    key = msvcrt.getch().decode('utf-8')
                    if key in options:
                        print(key)  # Echo the selected key
                        return key
                    elif key.lower() == 'q':  # Allow 'q' to quit
                        print("\nExiting...")
                        sys.exit(0)
                    else:
                        print(f"\n❌ Invalid option '{key}'. Please try again.")
                        print(f"Select option by pressing the number key: ", end="", flush=True)
        except ImportError:
            # Fallback to regular input for non-Windows systems
            while True:
                choice = input("Select option by typing the number and pressing Enter: ").strip()
                if choice in options:
                    return choice
                else:
                    print("❌ Invalid option. Please try again.")
                    self.pause_execution()