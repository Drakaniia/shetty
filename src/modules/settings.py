"""
Windows Settings & Run Commands Module
"""

import subprocess
from src.utils.system import SystemUtils
from src.config.settings import WINDOWS_COMMANDS


class WindowsSettings:
    """Windows Settings and Run Commands functionality"""
    
    def __init__(self, system_utils):
        self.system = system_utils
        self.commands = WINDOWS_COMMANDS
    
    def show_settings_menu(self):
        """Display Windows settings menu and handle user selection"""
        while True:
            self.system.clear_screen()
            self.system.print_header("Windows Settings & Run Commands")
            
            print("Available Windows Settings")
            print("=" * 40)
            
            options = {
                "1": {"title": "Performance Options", "command": "performance"},
                "2": {"title": "System Properties", "command": "system"},
                "3": {"title": "Power Options", "command": "power"},
                "4": {"title": "Programs and Features", "command": "programs"},
                "5": {"title": "Network Connections", "command": "network"},
                "0": {"title": "Back to Main Menu", "command": "back"}
            }
            
            for key, option in options.items():
                if key == "0":
                    print(f"[{key}] {option['title']}")
                else:
                    print(f"[{key}] {option['title']}")
            
            choice = input("\nSelect option: ").strip()
            
            if choice == "0":
                return
            elif choice in options:
                self.handle_settings_choice(options[choice])
            else:
                print("❌ Invalid option")
                self.system.pause_execution()
    
    def handle_settings_choice(self, option):
        """Handle user's settings choice"""
        command_key = option['command']
        
        if command_key == "back":
            return
        
        if command_key in self.commands:
            command = self.commands[command_key]
            success = self.open_windows_tool(command, option['title'])
            if success:
                print(f"✅ {option['title']} opened successfully")
            else:
                print(f"❌ Failed to open {option['title']}")
            self.system.pause_execution()
        else:
            print(f"❌ Unknown command: {command_key}")
            self.system.pause_execution()
    
    def open_windows_tool(self, command, tool_name):
        """Open a Windows tool using Run command"""
        try:
            print(f"🔧 Opening: {tool_name} ({command})")
            
            # Use subprocess.Popen for non-blocking execution
            subprocess.Popen(
                ["cmd", "/c", "start", command], 
                shell=True,
                creationflags=subprocess.CREATE_NEW_CONSOLE
            )
            
            return True
        except Exception as e:
            print(f"❌ Failed to open {tool_name}: {e}")
            return False
    
    def run_command(self, command_key):
        """Run a specific Windows command"""
        if command_key in self.commands:
            command = self.commands[command_key]
            return self.open_windows_tool(command, command)
        else:
            print(f"❌ Unknown command: {command_key}")
            return False
    
    def open_performance_options(self):
        """Open Performance Options"""
        return self.run_command("performance")
    
    def open_system_properties(self):
        """Open System Properties"""
        return self.run_command("system")
    
    def open_power_options(self):
        """Open Power Options"""
        return self.run_command("power")
    
    def open_programs_features(self):
        """Open Programs and Features"""
        return self.run_command("programs")
    
    def open_network_connections(self):
        """Open Network Connections"""
        return self.run_command("network")
    
    def get_available_commands(self):
        """Get list of all available commands"""
        commands = []
        for key, command in self.commands.items():
            commands.append({
                'key': key,
                'command': command,
                'name': key.replace('_', ' ').title()
            })
        return commands
    
    def add_custom_command(self, key, command, name=None):
        """Add a custom command to the available commands"""
        if name is None:
            name = key.replace('_', ' ').title()
        
        self.commands[key] = command
        print(f"✅ Added custom command: {key} -> {command}")
        return True
    
    def remove_custom_command(self, key):
        """Remove a custom command"""
        if key in self.commands:
            removed_command = self.commands.pop(key)
            print(f"✅ Removed custom command: {key} -> {removed_command}")
            return True
        else:
            print(f"❌ Command not found: {key}")
            return False