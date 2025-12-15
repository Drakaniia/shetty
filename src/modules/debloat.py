"""
Windows Debloat & Tweaks Module
"""

from src.utils.system import SystemUtils
from src.config.settings import POWERSHELL_SCRIPTS


class WindowsDebloat:
    """Windows Debloat and Tweaks functionality"""
    
    def __init__(self, system_utils):
        self.system = system_utils
        self.scripts = POWERSHELL_SCRIPTS
    
    def show_debloat_menu(self):
        """Display debloat menu and handle user selection"""
        while True:
            self.system.clear_screen()
            self.system.print_header("Windows Debloat & Tweaks")
            
            print("Available Debloat & Tweaks Options")
            print("=" * 50)
            
            # Debloat options
            print("\nDebloat Options:")
            for i, (key, script) in enumerate(self.scripts["debloat"].items(), 1):
                print(f"[{i}] {script['name']} - {script['description']}")
            
            # Tweaks options
            print("\nWindows Tweaks:")
            tweak_count = len(self.scripts["debloat"])
            for i, (key, script) in enumerate(self.scripts["tweaks"].items(), tweak_count + 1):
                print(f"[{i}] {script['name']} - {script['description']}")
            
            # Activation options
            print("\n🔑 Windows Activation:")
            activation_count = tweak_count + len(self.scripts["tweaks"])
            for i, (key, script) in enumerate(self.scripts["activation"].items(), activation_count + 1):
                print(f"[{i}] {script['name']} - {script['description']}")
            
            print("\n[0] Back to Main Menu")
            
            choice = input("\nSelect option: ").strip()
            
            if choice == "0":
                return
            elif choice.isdigit():
                self.handle_debloat_choice(int(choice))
            else:
                print("❌ Invalid option")
                self.system.pause_execution()
    
    def handle_debloat_choice(self, choice):
        """Handle user's debloat choice"""
        all_scripts = {}
        
        # Collect all scripts with their menu numbers
        script_index = 1
        
        # Add debloat scripts
        for key, script in self.scripts["debloat"].items():
            all_scripts[script_index] = (script['url'], script['name'])
            script_index += 1
        
        # Add tweak scripts
        for key, script in self.scripts["tweaks"].items():
            all_scripts[script_index] = (script['url'], script['name'])
            script_index += 1
        
        # Add activation scripts
        for key, script in self.scripts["activation"].items():
            all_scripts[script_index] = (script['url'], script['name'])
            script_index += 1
        
        if choice in all_scripts:
            url, name = all_scripts[choice]
            success = self.system.run_powershell_script(url, name)
            if success:
                print(f"✅ {name} completed successfully")
            else:
                print(f"❌ {name} failed")
            self.system.pause_execution()
        else:
            print("❌ Invalid option")
            self.system.pause_execution()
    
    def run_debloat_script(self, script_type, script_key):
        """Run a specific debloat script"""
        if script_type in self.scripts and script_key in self.scripts[script_type]:
            script = self.scripts[script_type][script_key]
            return self.system.run_powershell_script(script['url'], script['name'])
        else:
            print(f"❌ Invalid script: {script_type}.{script_key}")
            return False
    
    def run_win11debloat(self):
        """Run Win11Debloat script"""
        return self.run_debloat_script("debloat", "win11debloat")
    
    def run_debloat11(self):
        """Run Debloat11 script"""
        return self.run_debloat_script("debloat", "debloat11")
    
    def run_windows_tweaks(self):
        """Run Windows Tweaks script"""
        return self.run_debloat_script("tweaks", "windows_tweaks")
    
    def run_windows_activation(self):
        """Run Windows Activation script"""
        return self.run_debloat_script("activation", "activate_windows")
    
    def get_available_scripts(self):
        """Get list of all available scripts"""
        scripts = []
        for category, script_dict in self.scripts.items():
            for key, script in script_dict.items():
                scripts.append({
                    'category': category,
                    'key': key,
                    'name': script['name'],
                    'url': script['url'],
                    'description': script['description']
                })
        return scripts