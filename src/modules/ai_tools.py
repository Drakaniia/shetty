"""
Terminal AI Tools Installer Module
"""

import subprocess
from src.utils.system import SystemUtils
from src.config.settings import AI_TOOLS


class AIToolsInstaller:
    """Terminal AI Tools installation functionality"""
    
    def __init__(self, system_utils):
        self.system = system_utils
        self.tools = AI_TOOLS
    
    def show_ai_tools_menu(self):
        """Display AI tools installer menu"""
        while True:
            self.system.clear_screen()
            self.system.print_header("Terminal AI Tools Installer")
            
            # Check if Node.js and npm are available
            node_available = self.check_node_npm_available()
            if not node_available:
                print("❌ Node.js and npm are not available.")
                print("Please install Node.js first using the Essential Apps Downloader.")
                self.system.pause_execution()
                return
            
            # Create options dynamically
            options = {}
            for i, tool in enumerate(self.tools, 1):
                options[str(i)] = {"title": tool['name']}
            options["3"] = {"title": "🌊 iFlow CLI"}  # iFlow CLI is special case
            options["0"] = {"title": "Back to Main Menu"}
            options["99"] = {"title": "Install All Tools"}

            self.system.print_menu("AI TOOLS INSTALLER", options)

            choice = self.system.get_menu_choice(options)

            if choice == "0":
                return
            elif choice == "99":
                self.install_all_tools()
            elif choice.isdigit() and 1 <= int(choice) <= len(self.tools):
                self.install_single_tool(int(choice) - 1)
            elif choice == "3":
                self.install_iflow_cli()
    
    def check_node_npm_available(self):
        """Check if Node.js and npm are available"""
        node_available = self.system.check_program_exists("node")
        npm_available = self.system.check_program_exists("npm")
        return node_available and npm_available
    
    def install_single_tool(self, tool_index):
        """Install a single AI tool"""
        if 0 <= tool_index < len(self.tools):
            tool = self.tools[tool_index]
            self.install_npm_tool(tool['package'], tool['name'])
        else:
            print("❌ Invalid tool index")
            self.system.pause_execution()
    
    def install_all_tools(self):
        """Install all AI tools"""
        if not self.system.get_confirmation("Install all AI tools?"):
            print("❌ Operation cancelled")
            return
        
        # Install npm tools
        for tool in self.tools:
            self.install_npm_tool(tool['package'], tool['name'])
        
        # Install iFlow CLI
        self.install_iflow_cli()
    
    def install_npm_tool(self, package, name):
        """Install an npm package globally"""
        print(f"\nInstalling {name}...")
        print(f"🔧 Package: {package}")
        print("-" * 40)
        
        try:
            command = ["npm", "install", "-g", package]
            
            print(f"🔧 Executing: {' '.join(command)}")
            
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=180  # 3 minutes timeout
            )
            
            if result.returncode == 0:
                print(f"✅ {name} installed successfully")
                return True
            else:
                # Check if already installed
                if "already installed" in result.stderr.lower() or "up to date" in result.stderr.lower():
                    print(f"ℹ️ {name} is already installed")
                    return True
                else:
                    print(f"❌ Failed to install {name}")
                    print(f"📄 Error: {result.stderr.strip()}")
                    return False
                    
        except subprocess.TimeoutExpired:
            print(f"❌ Installation of {name} timed out")
            return False
        except Exception as e:
            print(f"❌ Error installing {name}: {e}")
            return False
    
    def uninstall_npm_tool(self, package, name):
        """Uninstall an npm package globally"""
        print(f"\n🗑️ Uninstalling {name}...")
        
        try:
            command = ["npm", "uninstall", "-g", package]
            
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=180
            )
            
            if result.returncode == 0:
                print(f"✅ {name} uninstalled successfully")
                return True
            else:
                print(f"❌ Failed to uninstall {name}")
                print(f"📄 Error: {result.stderr.strip()}")
                return False
                
        except subprocess.TimeoutExpired:
            print(f"❌ Uninstallation of {name} timed out")
            return False
        except Exception as e:
            print(f"❌ Error uninstalling {name}: {e}")
            return False
    
    def update_npm_tool(self, package, name):
        """Update an npm package globally"""
        print(f"\n🔄 Updating {name}...")
        
        try:
            command = ["npm", "update", "-g", package]
            
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=180
            )
            
            if result.returncode == 0:
                print(f"✅ {name} updated successfully")
                return True
            else:
                print(f"❌ Failed to update {name}")
                print(f"📄 Error: {result.stderr.strip()}")
                return False
                
        except subprocess.TimeoutExpired:
            print(f"❌ Update of {name} timed out")
            return False
        except Exception as e:
            print(f"❌ Error updating {name}: {e}")
            return False
    
    def check_npm_tool_installed(self, package):
        """Check if an npm package is installed globally"""
        try:
            command = ["npm", "list", "-g", package, "--depth=0"]
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            return result.returncode == 0 and package in result.stdout
        except:
            return False
    
    def install_iflow_cli(self):
        """Install iFlow CLI"""
        print("\n🌊 Installing iFlow CLI...")
        print("=" * 40)
        
        if self.system.get_confirmation("Install iFlow CLI? This requires bash environment."):
            try:
                # Check if bash is available
                bash_available = self.system.check_program_exists("bash")
                
                if not bash_available:
                    print("⚠️ iFlow CLI requires bash environment (WSL or Git Bash)")
                    print("Please install WSL or Git Bash first.")
                    print("\nAlternative installation method:")
                    print("1. Install WSL from Microsoft Store")
                    print("2. Or install Git for Windows (includes Git Bash)")
                    print("3. Then run this command in bash:")
                    print('curl -fsSL https://cloud.iflow.cn/iflow-cli/install.sh | bash')
                    return False
                
                # Try to install using bash
                install_script = "curl -fsSL https://cloud.iflow.cn/iflow-cli/install.sh | bash"
                success, output = self.system.run_command(install_script, shell=True, timeout=300)
                
                if success:
                    print("✅ iFlow CLI installed successfully")
                    return True
                else:
                    print("❌ Failed to install iFlow CLI")
                    print("Please try manual installation:")
                    print('curl -fsSL https://cloud.iflow.cn/iflow-cli/install.sh | bash')
                    return False
                    
            except Exception as e:
                print(f"❌ Error installing iFlow CLI: {e}")
                return False
        else:
            print("❌ iFlow CLI installation cancelled")
            return False
    
    def show_installed_tools(self):
        """Show status of all AI tools"""
        print("\n📋 AI Tools Status")
        print("=" * 40)
        
        # Check Node.js and npm
        node_available = self.system.check_program_exists("node")
        npm_available = self.system.check_program_exists("npm")
        
        print(f"Node.js: {'✅ Available' if node_available else '❌ Not Available'}")
        print(f"npm: {'✅ Available' if npm_available else '❌ Not Available'}")
        
        if node_available and npm_available:
            print("\nAI Tools:")
            for tool in self.tools:
                if self.check_npm_tool_installed(tool['package']):
                    print(f"✅ {tool['name']} - Installed")
                else:
                    print(f"❌ {tool['name']} - Not Installed")
            
            # Check iFlow CLI
            iflow_available = self.system.check_program_exists("iflow")
            print(f"iFlow CLI: {'✅ Available' if iflow_available else '❌ Not Available'}")
        
        self.system.pause_execution()
    
    def add_custom_tool(self, package, name):
        """Add a custom AI tool to the list"""
        self.tools.append({"package": package, "name": name})
        print(f"✅ Added custom tool: {name} ({package})")
        return True
    
    def remove_custom_tool(self, name):
        """Remove a custom AI tool from the list"""
        for i, tool in enumerate(self.tools):
            if tool['name'] == name:
                removed_tool = self.tools.pop(i)
                print(f"✅ Removed custom tool: {name}")
                return True
        
        print(f"❌ Tool not found: {name}")
        return False
    
    def get_available_tools(self):
        """Get list of all available AI tools"""
        return self.tools.copy()
    
    def search_npm_packages(self, query):
        """Search for npm packages"""
        try:
            command = ["npm", "search", query]
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if result.returncode == 0:
                print(f"\n🔍 Search results for '{query}':")
                print("-" * 50)
                print(result.stdout[:1000] + "..." if len(result.stdout) > 1000 else result.stdout)
                return True
            else:
                print(f"❌ Search failed: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ Error searching for packages: {e}")
            return False