"""
Power Management Module
"""

import subprocess
import re
from src.utils.system import SystemUtils
from src.config.settings import ULTIMATE_PERFORMANCE_GUID


class PowerManagement:
    """Power Management functionality"""
    
    def __init__(self, system_utils):
        self.system = system_utils
        self.ultimate_performance_guid = ULTIMATE_PERFORMANCE_GUID
    
    def show_power_menu(self):
        """Display power management menu"""
        while True:
            self.system.clear_screen()
            self.system.print_header("Power Management")
            
            print("Power Management Options")
            print("=" * 40)
            print("[1] Unlock Ultimate Performance Plan")
            print("[2] List All Power Plans")
            print("[3] Show Active Power Plan")
            print("[4] Switch Power Plan")
            print("[5] Create Custom Power Plan")
            print("[0] Back to Main Menu")
            
            choice = input("\nSelect option: ").strip()
            
            if choice == "1":
                self.unlock_ultimate_performance()
            elif choice == "2":
                self.list_power_plans()
            elif choice == "3":
                self.show_active_plan()
            elif choice == "4":
                self.switch_power_plan()
            elif choice == "5":
                self.create_custom_plan()
            elif choice == "0":
                return
            else:
                print("❌ Invalid option")
                self.system.pause_execution()
    
    def unlock_ultimate_performance(self):
        """Unlock Ultimate Performance power plan"""
        print("\nUltimate Performance Power Plan Unlocker")
        print("=" * 50)
        
        if not self.system.get_confirmation("Unlock Ultimate Performance power plan?"):
            print("❌ Operation cancelled")
            return
        
        # Step 1: Duplicate the scheme
        print("\n🔧 Step 1: Duplicating Ultimate Performance scheme...")
        command = f"powercfg -duplicatescheme {self.ultimate_performance_guid}"
        
        success, output = self.system.run_command(command, shell=False, timeout=30)
        
        if success:
            # Extract GUID from output
            guid = self.extract_guid_from_output(output)
            
            if guid:
                print(f"✅ Power plan created with GUID: {guid}")
                
                # Step 2: Ask if user wants to activate it
                if self.system.get_confirmation(f"Activate the Ultimate Performance plan now?"):
                    if self.activate_power_plan(guid):
                        print("✅ Ultimate Performance plan activated!")
                
                # Step 3: Show active scheme
                print("\n🔍 Current active power scheme:")
                self.show_active_plan()
                
                # Step 4: Open Power Options
                if self.system.get_confirmation("Open Power Options for visual confirmation?"):
                    self.open_power_options()
                    
            else:
                print("❌ Could not extract GUID from output")
        else:
            print("❌ Failed to duplicate power scheme")
        
        self.system.pause_execution()
    
    def extract_guid_from_output(self, output):
        """Extract GUID from powercfg output"""
        # Look for GUID pattern in the output
        guid_pattern = r'\{[0-9a-fA-F-]{36}\}'
        match = re.search(guid_pattern, output)
        return match.group(0) if match else None
    
    def activate_power_plan(self, guid):
        """Activate a power plan by GUID"""
        command = f"powercfg -setactive {guid}"
        success, output = self.system.run_command(command, shell=False)
        return success
    
    def list_power_plans(self):
        """List all available power plans"""
        print("\n📋 Available Power Plans")
        print("=" * 40)
        
        command = "powercfg -list"
        success, output = self.system.run_command(command, shell=False)
        
        if success:
            print(output)
        else:
            print("❌ Failed to list power plans")
        
        self.system.pause_execution()
    
    def show_active_plan(self):
        """Show the currently active power plan"""
        print("\n✅ Active Power Plan")
        print("=" * 30)
        
        command = "powercfg /getactivescheme"
        success, output = self.system.run_command(command, shell=False)
        
        if success:
            print(output)
        else:
            print("❌ Failed to get active power plan")
        
        self.system.pause_execution()
    
    def switch_power_plan(self):
        """Switch to a different power plan"""
        print("\n🔄 Switch Power Plan")
        print("=" * 30)
        
        # First, list all available plans
        command = "powercfg -list"
        success, output = self.system.run_command(command, shell=False)
        
        if not success:
            print("❌ Failed to list power plans")
            self.system.pause_execution()
            return
        
        print("\nAvailable Power Plans:")
        print(output)
        
        # Get user input for GUID
        guid = input("\nEnter the GUID of the power plan to activate: ").strip()
        
        if not guid:
            print("❌ No GUID provided")
            self.system.pause_execution()
            return
        
        # Validate GUID format
        if not re.match(r'^\{[0-9a-fA-F-]{36\}$', guid):
            print("❌ Invalid GUID format")
            self.system.pause_execution()
            return
        
        if self.system.get_confirmation(f"Activate power plan {guid}?"):
            if self.activate_power_plan(guid):
                print("✅ Power plan activated successfully!")
                self.show_active_plan()
            else:
                print("❌ Failed to activate power plan")
        
        self.system.pause_execution()
    
    def create_custom_plan(self):
        """Create a custom power plan"""
        print("\nCreate Custom Power Plan")
        print("=" * 35)
        
        plan_name = input("Enter name for the custom power plan: ").strip()
        if not plan_name:
            print("❌ No plan name provided")
            self.system.pause_execution()
            return
        
        # Get the active plan to use as base
        command = "powercfg /getactivescheme"
        success, output = self.system.run_command(command, shell=False)
        
        if not success:
            print("❌ Failed to get active power plan")
            self.system.pause_execution()
            return
        
        base_guid = self.extract_guid_from_output(output)
        if not base_guid:
            print("❌ Could not extract base plan GUID")
            self.system.pause_execution()
            return
        
        # Create the new plan
        command = f"powercfg -duplicatescheme {base_guid}"
        success, output = self.system.run_command(command, shell=False)
        
        if success:
            new_guid = self.extract_guid_from_output(output)
            if new_guid:
                # Rename the plan
                rename_command = f"powercfg -changename {new_guid} \"{plan_name}\""
                success, _ = self.system.run_command(rename_command, shell=False)
                
                if success:
                    print(f"✅ Custom power plan '{plan_name}' created successfully!")
                    print(f"📋 GUID: {new_guid}")
                    
                    if self.system.get_confirmation("Activate the new custom plan?"):
                        self.activate_power_plan(new_guid)
                        print("✅ Custom plan activated!")
                else:
                    print("❌ Failed to rename the power plan")
            else:
                print("❌ Could not extract new plan GUID")
        else:
            print("❌ Failed to create custom power plan")
        
        self.system.pause_execution()
    
    def open_power_options(self):
        """Open Power Options control panel"""
        try:
            subprocess.Popen(["powercfg.cpl"], shell=True)
            print("✅ Power Options opened")
            return True
        except Exception as e:
            print(f"❌ Failed to open Power Options: {e}")
            return False
    
    def get_power_plan_info(self, guid):
        """Get detailed information about a power plan"""
        command = f"powercfg -query {guid}"
        success, output = self.system.run_command(command, shell=False)
        return output if success else None
    
    def export_power_plan(self, guid, filename):
        """Export a power plan to a file"""
        command = f"powercfg -export {filename} {guid}"
        success, output = self.system.run_command(command, shell=False)
        return success
    
    def import_power_plan(self, filename):
        """Import a power plan from a file"""
        command = f"powercfg -import {filename}"
        success, output = self.system.run_command(command, shell=False)
        return success