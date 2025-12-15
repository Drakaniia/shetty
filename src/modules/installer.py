"""
App Installer Module
"""

import time
import subprocess
from src.utils.system import SystemUtils
from src.config.settings import ESSENTIAL_APPS


class AppInstaller:
    """Application installation functionality"""
    
    def __init__(self, system_utils):
        self.system = system_utils
        self.apps = ESSENTIAL_APPS
    
    def show_installer_menu(self):
        """Display app installer menu"""
        while True:
            self.system.clear_screen()
            self.system.print_header("Essential Apps Installer")
            
            # Check if winget is available
            winget_available = self.check_winget_available()
            if not winget_available:
                print("❌ Winget is not available. Please install Windows Package Manager first.")
                self.system.pause_execution()
                return
            
            print("Available Apps to Install")
            print("=" * 40)
            
            for i, app in enumerate(self.apps, 1):
                print(f"[{i}] {app['name']}")
            
            print("\n[0] Back to Main Menu")
            print("[99] Install All Apps")
            
            choice = input("\nSelect option: ").strip()
            
            if choice == "0":
                return
            elif choice == "99":
                self.install_all_apps()
            elif choice.isdigit() and 1 <= int(choice) <= len(self.apps):
                self.install_single_app(int(choice) - 1)
            else:
                print("❌ Invalid option")
                self.system.pause_execution()
    
    def check_winget_available(self):
        """Check if winget is available on the system"""
        return self.system.check_program_exists("winget")
    
    def install_single_app(self, app_index):
        """Install a single application"""
        if 0 <= app_index < len(self.apps):
            app = self.apps[app_index]
            self.install_app_winget(app['id'], app['name'])
        else:
            print("❌ Invalid app index")
            self.system.pause_execution()
    
    def install_all_apps(self):
        """Install all essential apps"""
        if not self.system.get_confirmation("Install all essential apps? This may take several minutes."):
            print("❌ Operation cancelled")
            return
        
        for app in self.apps:
            self.install_app_winget(app['id'], app['name'])
            time.sleep(2)  # Brief pause between installations
    
    def install_app_winget(self, app_id, app_name):
        """Install application using winget"""
        print(f"\nInstalling {app_name}...")
        print(f"🔧 Package ID: {app_id}")
        print("-" * 40)
        
        try:
            # Build winget command with all necessary flags
            command = [
                "winget", "install", 
                "--id", app_id,
                "--accept-package-agreements", 
                "--accept-source-agreements",
                "--silent",
                "--ignore-warnings"
            ]
            
            print(f"🔧 Executing: {' '.join(command)}")
            
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=300  # 5 minutes timeout
            )
            
            if result.returncode == 0:
                print(f"✅ {app_name} installed successfully")
                return True
            else:
                # Check if already installed
                if "already installed" in result.stderr.lower() or "already exists" in result.stderr.lower():
                    print(f"ℹ️ {app_name} is already installed")
                    return True
                else:
                    print(f"❌ Failed to install {app_name}")
                    print(f"📄 Error: {result.stderr.strip()}")
                    return False
                    
        except subprocess.TimeoutExpired:
            print(f"❌ Installation of {app_name} timed out")
            return False
        except Exception as e:
            print(f"❌ Error installing {app_name}: {e}")
            return False
    
    def uninstall_app_winget(self, app_id, app_name):
        """Uninstall application using winget"""
        print(f"\n🗑️ Uninstalling {app_name}...")
        
        try:
            command = [
                "winget", "uninstall", 
                "--id", app_id,
                "--accept-source-agreements",
                "--silent",
                "--force"
            ]
            
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=300
            )
            
            if result.returncode == 0:
                print(f"✅ {app_name} uninstalled successfully")
                return True
            else:
                print(f"❌ Failed to uninstall {app_name}")
                print(f"📄 Error: {result.stderr.strip()}")
                return False
                
        except subprocess.TimeoutExpired:
            print(f"❌ Uninstallation of {app_name} timed out")
            return False
        except Exception as e:
            print(f"❌ Error uninstalling {app_name}: {e}")
            return False
    
    def check_app_installed(self, app_id):
        """Check if an app is already installed"""
        try:
            command = ["winget", "list", "--id", app_id, "--exact"]
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            return result.returncode == 0 and app_id in result.stdout
        except:
            return False
    
    def update_app_winget(self, app_id, app_name):
        """Update application using winget"""
        print(f"\n🔄 Updating {app_name}...")
        
        try:
            command = [
                "winget", "upgrade", 
                "--id", app_id,
                "--accept-package-agreements", 
                "--accept-source-agreements",
                "--silent"
            ]
            
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=300
            )
            
            if result.returncode == 0:
                print(f"✅ {app_name} updated successfully")
                return True
            else:
                print(f"❌ Failed to update {app_name}")
                print(f"📄 Error: {result.stderr.strip()}")
                return False
                
        except subprocess.TimeoutExpired:
            print(f"❌ Update of {app_name} timed out")
            return False
        except Exception as e:
            print(f"❌ Error updating {app_name}: {e}")
            return False
    
    def show_installed_apps(self):
        """Show all installed apps from our list"""
        print("\n📋 Installed Apps Status")
        print("=" * 40)
        
        for app in self.apps:
            if self.check_app_installed(app['id']):
                print(f"✅ {app['name']} - Installed")
            else:
                print(f"❌ {app['name']} - Not Installed")
        
        self.system.pause_execution()
    
    def add_custom_app(self, app_id, app_name):
        """Add a custom app to the list"""
        self.apps.append({"id": app_id, "name": app_name})
        print(f"✅ Added custom app: {app_name} ({app_id})")
        return True
    
    def remove_custom_app(self, app_name):
        """Remove a custom app from the list"""
        for i, app in enumerate(self.apps):
            if app['name'] == app_name:
                removed_app = self.apps.pop(i)
                print(f"✅ Removed custom app: {app_name}")
                return True
        
        print(f"❌ App not found: {app_name}")
        return False
    
    def get_available_apps(self):
        """Get list of all available apps"""
        return self.apps.copy()
    
    def search_winget_apps(self, query):
        """Search for apps using winget"""
        try:
            command = ["winget", "search", query]
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if result.returncode == 0:
                print(f"\n🔍 Search results for '{query}':")
                print("-" * 50)
                print(result.stdout)
                return True
            else:
                print(f"❌ Search failed: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ Error searching for apps: {e}")
            return False