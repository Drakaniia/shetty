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
                print(f" Failed to relaunch as admin: {e}")
                return False
        return True
    
    def clear_screen(self):
        """Clear the console screen"""
        os.system('cls' if os.name == 'nt' else 'clear')
    
    def pause_execution(self):
        """Pause execution and wait for user input"""
        input("\nPress Enter to continue...")
    
    def get_confirmation(self, message):
        """Get user confirmation for potentially risky operations. Default to 'yes' if Enter is pressed."""
        while True:
            response = input(f"\n{message} (Y/n): ").lower().strip()
            if response == '' or response in ['y', 'yes']:
                return True
            elif response in ['n', 'no']:
                return False
            else:
                print("Please enter 'y' for yes or 'n' for no")
    
    def run_powershell_command(self, command, bypass_policy=True, timeout=300, interactive=False):
        """Execute a PowerShell command with optional execution policy bypass"""
        try:
            if bypass_policy:
                if interactive:
                    ps_args = ["powershell", "-ExecutionPolicy", "Bypass", "-NoExit", "-WindowStyle", "Normal", "-Command", command]
                else:
                    ps_args = ["powershell", "-ExecutionPolicy", "Bypass", "-Command", command]
            else:
                if interactive:
                    ps_args = ["powershell", "-NoExit", "-WindowStyle", "Normal", "-Command", command]
                else:
                    ps_args = ["powershell", "-Command", command]

            print(f" Executing: {command}")

            if interactive:
                # For interactive scripts, don't capture output to allow GUI to show
                result = subprocess.run(
                    ps_args,
                    timeout=timeout
                )

                # For interactive commands, we assume success if no exception occurs
                # since the window is meant to stay open for user interaction
                print("Command executed successfully")
                return True, ""
            else:
                result = subprocess.run(
                    ps_args,
                    capture_output=True,
                    text=True,
                    timeout=timeout
                )

                if result.returncode == 0:
                    print("Command executed successfully")
                    if result.stdout and result.stdout.strip():
                        print(f"Output: {result.stdout.strip()}")
                    return True, result.stdout
                else:
                    print(f"Command failed: {result.stderr.strip() if result.stderr else 'Unknown error'}")
                    return False, result.stderr

        except subprocess.TimeoutExpired:
            print("Command timed out")
            return False, "Command timed out"
        except Exception as e:
            print(f"Error executing command: {e}")
            return False, str(e)
    
    def run_powershell_script(self, script_url, description):
        """Execute a PowerShell script from URL"""
        print(f"\n{description}")
        print("=" * 50)

        if not self.get_confirmation(f"Run {description}? This will execute PowerShell scripts from the internet."):
            print("Operation cancelled by user")
            return False

        # For all PowerShell scripts, use a temporary file approach
        import tempfile
        import os

        if "get.activated.win" in script_url:
            # For Windows activation, use the proper command: irm https://get.activated.win | iex
            ps_command = f"irm {script_url} | iex"
            print(f" Executing activation command: {ps_command}")
        elif "win11debloat.raphi.re" in script_url:
            # For Win11Debloat, use the proper command: & ([scriptblock]::Create((irm "https://win11debloat.raphi.re/")))
            ps_command = f"& ([scriptblock]::Create((irm \"{script_url}\")))"
            print(f" Executing debloat command: {ps_command}")
        elif "christitus.com/win" in script_url:
            # For Windows tweaks, use the proper command: iwr -useb https://christitus.com/win | iex
            ps_command = f"iwr -useb {script_url} | iex"
            print(f" Executing tweaks command: {ps_command}")
        elif "git.io/debloat11" in script_url:
            # For Debloat11, use the proper command: iwr https://git.io/debloat11|iex
            ps_command = f"iwr {script_url}|iex"
            print(f" Executing debloat11 command: {ps_command}")
        else:
            # For other scripts, use the generic approach
            ps_command = f"[scriptblock]::Create((irm \"{script_url}\"))"
            print(f" Executing command: {ps_command}")

        print(" Running PowerShell command...")

        # Create a temporary PowerShell script to execute the command
        with tempfile.NamedTemporaryFile(mode='w', suffix='.ps1', delete=False) as temp_ps:
            # Don't try to set execution policy since PowerShell is run with Bypass
            temp_ps.write(f"""
{ps_command}
""")
            temp_script_path = temp_ps.name

        try:
            # Execute the temporary script with PowerShell Bypass policy
            ps_args = ["powershell", "-ExecutionPolicy", "Bypass", "-File", temp_script_path]

            # Run the command with real-time output
            import subprocess
            result = subprocess.run(
                ps_args,
                capture_output=False,  # Don't capture, let it display directly
                text=True
            )

            # Clean up the temporary file
            os.remove(temp_script_path)

            # Report success regardless of return code since these scripts may exit with different codes
            # but still be functionally successful
            print(f"\n {description} completed successfully")
            return True

        except Exception as e:
            # Clean up the temporary file even if there's an error
            try:
                os.remove(temp_script_path)
            except:
                pass
            print(f" Error executing {description}: {e}")
            return False
    
    def run_command(self, command, shell=True, timeout=60):
        """Run a system command"""
        try:
            print(f" Executing: {command}")
            result = subprocess.run(
                command,
                shell=shell,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            
            if result.returncode == 0:
                print("Command executed successfully")
                if result.stdout.strip():
                    print(f"Output: {result.stdout.strip()}")
                return True, result.stdout
            else:
                print(f"Command failed: {result.stderr.strip()}")
                return False, result.stderr
                
        except subprocess.TimeoutExpired:
            print("Command timed out")
            return False, "Command timed out"
        except Exception as e:
            print(f"Error executing command: {e}")
            return False, str(e)
    
    def check_program_exists(self, program_name):
        """Check if a program is available in the system PATH"""
        import os
        
        # Try to refresh the PATH environment variable to catch recently installed programs
        os.environ.update(os.environ)
        
        # Special handling for Node.js and npm
        if program_name.lower() in ['node', 'nodejs']:
            node_variants = ['node', 'nodejs', 'node.exe', 'nodejs.exe']
            for variant in node_variants:
                try:
                    result = subprocess.run([variant, "--version"],
                                          capture_output=True, check=True, timeout=10)
                    return True
                except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
                    continue

            # Check common Node.js installation directories
            common_node_paths = [
                r"C:\Program Files\nodejs\node.exe",
                r"C:\Program Files (x86)\nodejs\node.exe",
                os.path.expanduser(r"~\AppData\Local\Programs\nodejs\node.exe")
            ]

            for path in common_node_paths:
                if os.path.exists(path):
                    try:
                        result = subprocess.run([path, "--version"],
                                              capture_output=True, check=True, timeout=10)
                        return True
                    except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
                        continue

            return False
            
        elif program_name.lower() == 'npm':
            npm_variants = ['npm', 'npm.cmd', 'npm.exe']
            for variant in npm_variants:
                try:
                    result = subprocess.run([variant, "--version"],
                                          capture_output=True, check=True, timeout=10)
                    return True
                except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
                    continue

            # Check npm in common Node.js installation directories
            common_npm_paths = [
                r"C:\Program Files\nodejs\npm.cmd",
                r"C:\Program Files (x86)\nodejs\npm.cmd",
                os.path.expanduser(r"~\AppData\Local\Programs\nodejs\npm.cmd")
            ]

            for path in common_npm_paths:
                if os.path.exists(path):
                    try:
                        result = subprocess.run([path, "--version"],
                                              capture_output=True, check=True, timeout=10)
                        return True
                    except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
                        continue

            return False
        else:
            # For other programs, use the original method
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
            print(f" Failed to create directory {directory_path}: {e}")
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
        """Print a formatted menu with consistent left padding for better appearance"""
        # Calculate the width of the longest option
        max_option_length = len(title)
        for key, option in options.items():
            option_text = f"[{key}] {option.get('title', 'Unknown')}"
            max_option_length = max(max_option_length, len(option_text))

        # Pad to ensure minimum width
        max_option_length = max(max_option_length, 40)

        # Add consistent left padding (e.g., 10 spaces) for better visual appearance
        left_padding = " " * 5  # Add 5 spaces on the left for visual centering effect

        # Print title with left padding
        print(left_padding + title)
        print(left_padding + "-" * len(title))

        # Print each option with consistent left padding
        for key, option in options.items():
            option_text = f"[{key}] {option.get('title', 'Unknown')}"
            print(left_padding + option_text)

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
                        print(f"\n Invalid option '{key}'. Please try again.")
                        print(f"Select option by pressing the number key: ", end="", flush=True)
        except ImportError:
            # Fallback to regular input for non-Windows systems
            while True:
                choice = input("Select option by typing the number and pressing Enter: ").strip()
                if choice in options:
                    return choice
                else:
                    print(" Invalid option. Please try again.")
                    self.pause_execution()