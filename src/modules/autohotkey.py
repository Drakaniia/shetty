"""
AutoHotKey Setup & Script Deployment Module
"""

import os
import shutil
import subprocess
from src.utils.system import SystemUtils
from src.config.settings import AHK_SCRIPT_CONTENT


class AutoHotKeyManager:
    """AutoHotKey setup and script management functionality"""
    
    def __init__(self, system_utils):
        self.system = system_utils
        self.script_content = AHK_SCRIPT_CONTENT
        self.ahk_executable = "AutoHotkey64.exe"
        self.ahk_script_name = "automation.ahk"
    
    def show_autohotkey_menu(self):
        """Display AutoHotKey menu"""
        while True:
            self.system.clear_screen()
            self.system.print_header("AutoHotKey Setup & Management")
            
            print("AutoHotKey Options")
            print("=" * 40)
            print("[1] Install AutoHotKey")
            print("[2] Create/Update Script")
            print("[3] Run Script")
            print("[4] Stop Script")
            print("[5] Add to Startup")
            print("[6] Script Status")
            print("[0] Back to Main Menu")
            
            choice = input("\nSelect option: ").strip()
            
            if choice == "1":
                self.install_autohotkey()
            elif choice == "2":
                self.create_script()
            elif choice == "3":
                self.run_script()
            elif choice == "4":
                self.stop_script()
            elif choice == "5":
                self.add_to_startup()
            elif choice == "6":
                self.show_script_status()
            elif choice == "0":
                return
            else:
                print("❌ Invalid option")
                self.system.pause_execution()
    
    def check_autohotkey_installed(self):
        """Check if AutoHotKey is installed"""
        try:
            result = subprocess.run(
                [self.ahk_executable, "--version"], 
                capture_output=True, 
                text=True, 
                timeout=10
            )
            return result.returncode == 0
        except (FileNotFoundError, subprocess.TimeoutExpired):
            return False
    
    def install_autohotkey(self):
        """Install AutoHotKey using winget"""
        print("\nInstalling AutoHotKey...")
        print("=" * 40)
        
        if self.check_autohotkey_installed():
            print("✅ AutoHotKey is already installed")
            self.system.pause_execution()
            return
        
        # Check if winget is available
        if not self.system.check_program_exists("winget"):
            print("❌ Winget is not available. Please install Windows Package Manager first.")
            print("Alternatively, download AutoHotKey from: https://www.autohotkey.com/")
            self.system.pause_execution()
            return
        
        if not self.system.get_confirmation("Install AutoHotKey using winget?"):
            print("❌ Installation cancelled")
            return
        
        try:
            command = [
                "winget", "install", 
                "--id", "AutoHotkey.AutoHotkey",
                "--accept-package-agreements", 
                "--accept-source-agreements",
                "--silent"
            ]
            
            print(f"🔧 Executing: {' '.join(command)}")
            
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=300
            )
            
            if result.returncode == 0:
                print("✅ AutoHotKey installed successfully")
            else:
                print(f"❌ Failed to install AutoHotKey: {result.stderr}")
                
        except subprocess.TimeoutExpired:
            print("❌ AutoHotKey installation timed out")
        except Exception as e:
            print(f"❌ Error installing AutoHotKey: {e}")
        
        self.system.pause_execution()
    
    def create_script(self):
        """Create or update the AutoHotKey script"""
        print("\n📝 Creating AutoHotKey Script...")
        print("=" * 40)
        
        # Create AutoHotKey directory
        ahk_dir = os.path.join(self.system.documents_folder, "AutoHotKey")
        
        if not self.system.ensure_directory_exists(ahk_dir):
            print("❌ Failed to create AutoHotKey directory")
            self.system.pause_execution()
            return
        
        script_path = os.path.join(ahk_dir, self.ahk_script_name)
        
        try:
            with open(script_path, 'w', encoding='utf-8') as f:
                f.write(self.script_content)
            
            print(f"✅ AutoHotKey script created at: {script_path}")
            print("\n📄 Script Content:")
            print("-" * 40)
            print(self.script_content)
            print("-" * 40)
            
        except Exception as e:
            print(f"❌ Error creating AutoHotKey script: {e}")
        
        self.system.pause_execution()
    
    def run_script(self):
        """Run the AutoHotKey script"""
        print("\n▶️ Running AutoHotKey Script...")
        print("=" * 40)
        
        if not self.check_autohotkey_installed():
            print("❌ AutoHotKey is not installed. Please install it first.")
            self.system.pause_execution()
            return
        
        script_path = self.get_script_path()
        if not script_path:
            print("❌ AutoHotKey script not found. Please create it first.")
            self.system.pause_execution()
            return
        
        if self.is_script_running():
            print("ℹ️ Script is already running")
            self.system.pause_execution()
            return
        
        try:
            print(f"🔧 Starting script: {script_path}")
            
            # Start AutoHotKey script
            subprocess.Popen([self.ahk_executable, script_path])
            
            # Give it a moment to start
            import time
            time.sleep(2)
            
            if self.is_script_running():
                print("✅ AutoHotKey script is now running")
                print("\nActive Features:")
                print("• F3 → Left Mouse Button (hold/drag)")
                print("• Middle Mouse → Browser Back")
            else:
                print("❌ Failed to start script")
                
        except Exception as e:
            print(f"❌ Error running script: {e}")
        
        self.system.pause_execution()
    
    def stop_script(self):
        """Stop the AutoHotKey script"""
        print("\n⏹️ Stopping AutoHotKey Script...")
        print("=" * 40)
        
        if not self.is_script_running():
            print("ℹ️ No AutoHotKey script is currently running")
            self.system.pause_execution()
            return
        
        try:
            # Find and kill AutoHotKey processes
            result = subprocess.run(
                ["tasklist", "/FI", "IMAGENAME eq AutoHotkey64.exe"],
                capture_output=True,
                text=True
            )
            
            if "AutoHotkey64.exe" in result.stdout:
                # Kill all AutoHotKey processes
                subprocess.run(["taskkill", "/F", "/IM", "AutoHotkey64.exe"], 
                             capture_output=True)
                print("✅ AutoHotKey script stopped")
            else:
                print("ℹ️ No AutoHotKey processes found")
                
        except Exception as e:
            print(f"❌ Error stopping script: {e}")
        
        self.system.pause_execution()
    
    def add_to_startup(self):
        """Add AutoHotKey script to Windows startup"""
        print("\nAdding Script to Startup...")
        print("=" * 40)
        
        script_path = self.get_script_path()
        if not script_path:
            print("❌ AutoHotKey script not found. Please create it first.")
            self.system.pause_execution()
            return
        
        startup_folder = self.system.get_system_path("startup")
        if not startup_folder:
            print("❌ Could not find startup folder")
            self.system.pause_execution()
            return
        
        shortcut_path = os.path.join(startup_folder, self.ahk_script_name)
        
        try:
            # Copy script to startup folder
            shutil.copy2(script_path, shortcut_path)
            print(f"✅ Script added to startup: {shortcut_path}")
            print("🔄 The script will automatically start when Windows boots")
            
        except Exception as e:
            print(f"❌ Error adding script to startup: {e}")
        
        self.system.pause_execution()
    
    def remove_from_startup(self):
        """Remove AutoHotKey script from Windows startup"""
        print("\n🗑️ Removing Script from Startup...")
        print("=" * 40)
        
        startup_folder = self.system.get_system_path("startup")
        if not startup_folder:
            print("❌ Could not find startup folder")
            self.system.pause_execution()
            return
        
        shortcut_path = os.path.join(startup_folder, self.ahk_script_name)
        
        try:
            if os.path.exists(shortcut_path):
                os.remove(shortcut_path)
                print(f"✅ Script removed from startup: {shortcut_path}")
            else:
                print("ℹ️ Script not found in startup folder")
                
        except Exception as e:
            print(f"❌ Error removing script from startup: {e}")
        
        self.system.pause_execution()
    
    def show_script_status(self):
        """Show the current status of AutoHotKey and script"""
        print("\n📋 AutoHotKey Status")
        print("=" * 40)
        
        # Check AutoHotKey installation
        ahk_installed = self.check_autohotkey_installed()
        print(f"AutoHotKey: {'✅ Installed' if ahk_installed else '❌ Not Installed'}")
        
        if ahk_installed:
            # Check script existence
            script_path = self.get_script_path()
            script_exists = script_path and os.path.exists(script_path)
            print(f"Script: {'✅ Created' if script_exists else '❌ Not Found'}")
            
            if script_exists:
                print(f"📍 Location: {script_path}")
                
                # Check if script is running
                script_running = self.is_script_running()
                print(f"Status: {'✅ Running' if script_running else '❌ Stopped'}")
                
                # Check startup status
                startup_folder = self.system.get_system_path("startup")
                if startup_folder:
                    shortcut_path = os.path.join(startup_folder, self.ahk_script_name)
                    in_startup = os.path.exists(shortcut_path)
                    print(f"Startup: {'✅ Enabled' if in_startup else '❌ Disabled'}")
        
        self.system.pause_execution()
    
    def get_script_path(self):
        """Get the path to the AutoHotKey script"""
        ahk_dir = os.path.join(self.system.documents_folder, "AutoHotKey")
        return os.path.join(ahk_dir, self.ahk_script_name)
    
    def is_script_running(self):
        """Check if the AutoHotKey script is currently running"""
        try:
            result = subprocess.run(
                ["tasklist", "/FI", "IMAGENAME eq AutoHotkey64.exe"],
                capture_output=True,
                text=True
            )
            return "AutoHotkey64.exe" in result.stdout
        except:
            return False
    
    def edit_script(self):
        """Open the AutoHotKey script in default editor"""
        script_path = self.get_script_path()
        if not script_path or not os.path.exists(script_path):
            print("❌ Script not found. Please create it first.")
            self.system.pause_execution()
            return
        
        try:
            os.startfile(script_path)
            print("✅ Script opened in default editor")
        except Exception as e:
            print(f"❌ Error opening script: {e}")
        
        self.system.pause_execution()
    
    def create_custom_script(self, script_name, script_content):
        """Create a custom AutoHotKey script"""
        ahk_dir = os.path.join(self.system.documents_folder, "AutoHotKey")
        
        if not self.system.ensure_directory_exists(ahk_dir):
            return False
        
        script_path = os.path.join(ahk_dir, f"{script_name}.ahk")
        
        try:
            with open(script_path, 'w', encoding='utf-8') as f:
                f.write(script_content)
            print(f"✅ Custom script created: {script_path}")
            return True
        except Exception as e:
            print(f"❌ Error creating custom script: {e}")
            return False
    
    def list_scripts(self):
        """List all AutoHotKey scripts in the directory"""
        ahk_dir = os.path.join(self.system.documents_folder, "AutoHotKey")
        
        if not os.path.exists(ahk_dir):
            print("❌ AutoHotKey directory not found")
            return []
        
        scripts = []
        try:
            for file in os.listdir(ahk_dir):
                if file.endswith('.ahk'):
                    scripts.append(file)
        except Exception as e:
            print(f"❌ Error listing scripts: {e}")
        
        return scripts