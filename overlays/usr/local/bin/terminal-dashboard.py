#!/usr/bin/env python3

"""
Terminal-based Dashboard for Raspberry Pi 3B
Fallback interface if GUI fails
"""

import subprocess
import time
import os
import sys
from datetime import datetime

class TerminalDashboard:
    def __init__(self):
        self.running = True
        
    def clear_screen(self):
        """Clear the terminal screen"""
        os.system('clear')
        
    def print_header(self):
        """Print the dashboard header"""
        print("=" * 80)
        print("🍓 RASPBERRY PI 3B - TERMINAL DASHBOARD")
        print("=" * 80)
        print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 80)
        print()
        
    def get_system_info(self):
        """Get and display system information"""
        print("📊 SYSTEM STATUS")
        print("-" * 40)
        
        try:
            # CPU Temperature
            try:
                with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
                    temp = int(f.read()) / 1000.0
                    print(f"CPU Temperature: {temp:.1f}°C")
            except:
                print("CPU Temperature: N/A")
            
            # Memory Usage
            try:
                with open('/proc/meminfo', 'r') as f:
                    lines = f.readlines()
                    mem_total = int(lines[0].split()[1])
                    mem_free = int(lines[1].split()[1])
                    mem_available = int(lines[2].split()[1])
                    mem_used = mem_total - mem_available
                    mem_percent = (mem_used / mem_total) * 100
                    
                    print(f"Memory Usage: {mem_percent:.1f}% ({mem_used // 1024:.1f}MB / {mem_total // 1024:.1f}MB)")
            except:
                print("Memory Usage: N/A")
            
            # Disk Usage
            try:
                df = subprocess.run(['df', '-h', '/'], capture_output=True, text=True)
                lines = df.stdout.strip().split('\n')
                if len(lines) >= 2:
                    parts = lines[1].split()
                    if len(parts) >= 5:
                        print(f"Disk Usage: {parts[4]} ({parts[2]} / {parts[1]})")
            except:
                print("Disk Usage: N/A")
            
            # Uptime
            try:
                with open('/proc/uptime', 'r') as f:
                    uptime_seconds = float(f.readline().split()[0])
                    days = int(uptime_seconds // 86400)
                    hours = int((uptime_seconds % 86400) // 3600)
                    minutes = int((uptime_seconds % 3600) // 60)
                    print(f"System Uptime: {days}d {hours}h {minutes}m")
            except:
                print("System Uptime: N/A")
            
        except Exception as e:
            print(f"Error getting system info: {e}")
            
        print()
        
    def get_service_status(self):
        """Get and display service status"""
        print("🔧 SERVICES STATUS")
        print("-" * 40)
        
        services = [
            ('shairport-sync', '🎵 AirPlay Receiver'),
            ('google-cast', '📱 Google Cast'),
            ('wifi-tools', '🔒 WiFi Security Tools'),
            ('smbd', '📁 File Server'),
            ('remote-control', '🌐 Remote Control')
        ]
        
        for service_name, display_name in services:
            try:
                result = subprocess.run(['systemctl', 'is-active', service_name], 
                                      capture_output=True, text=True, timeout=5)
                status = "🟢 Running" if result.returncode == 0 else "🔴 Stopped"
                print(f"{display_name}: {status}")
            except:
                print(f"{display_name}: ❓ Unknown")
                
        print()
        
    def get_network_info(self):
        """Get and display network information"""
        print("🌐 NETWORK STATUS")
        print("-" * 40)
        
        try:
            # IP Address
            result = subprocess.run(['hostname', '-I'], capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                ip = result.stdout.strip().split()[0] if result.stdout.strip() else "Not Connected"
                print(f"IP Address: {ip}")
            else:
                print("IP Address: Not Connected")
            
            # WiFi Status
            try:
                result = subprocess.run(['iwconfig', 'wlan0'], capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    for line in result.stdout.split('\n'):
                        if 'ESSID:' in line:
                            ssid = line.split('"')[1] if '"' in line else 'Unknown'
                            print(f"WiFi Network: {ssid}")
                            break
                    else:
                        print("WiFi Network: Not Connected")
                else:
                    print("WiFi Network: Not Connected")
            except:
                print("WiFi Network: Not Connected")
                
        except Exception as e:
            print(f"Error getting network info: {e}")
            
        print()
        
    def get_wifi_networks(self):
        """Scan and display available WiFi networks"""
        print("📡 AVAILABLE WIFI NETWORKS")
        print("-" * 40)
        
        try:
            result = subprocess.run(['sudo', 'iwlist', 'wlan0', 'scan'], 
                                  capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                networks = []
                lines = result.stdout.split('\n')
                current_network = {}
                
                for line in lines:
                    if 'Cell' in line and 'Address' in line:
                        if current_network:
                            networks.append(current_network)
                        current_network = {}
                    elif 'ESSID:' in line:
                        ssid = line.split('"')[1] if '"' in line else 'Unknown'
                        current_network['ssid'] = ssid
                    elif 'Encryption key:' in line:
                        encrypted = 'on' in line
                        current_network['encrypted'] = encrypted
                    elif 'Signal level=' in line:
                        signal = line.split('=')[1].split()[0]
                        current_network['signal'] = signal
                
                if current_network:
                    networks.append(current_network)
                
                # Display networks
                for i, network in enumerate(networks, 1):
                    if 'ssid' in network and network['ssid'] != 'Unknown':
                        encrypted = "🔒" if network.get('encrypted', False) else "🔓"
                        signal = network.get('signal', 'N/A')
                        print(f"{i}. {encrypted} {network['ssid']} (Signal: {signal})")
                        
                if not networks:
                    print("No networks found")
            else:
                print("Failed to scan networks")
                
        except Exception as e:
            print(f"Error scanning networks: {e}")
            
        print()
        
    def show_help(self):
        """Show available commands"""
        print("💡 AVAILABLE COMMANDS")
        print("-" * 40)
        print("Commands you can run in another terminal:")
        print()
        print("WiFi Management:")
        print("  sudo /usr/local/bin/wifi-setup.py add <ssid> <password>")
        print("  sudo iwlist wlan0 scan")
        print("  sudo iwconfig wlan0")
        print()
        print("Service Control:")
        print("  sudo systemctl start/stop/restart shairport-sync")
        print("  sudo systemctl start/stop/restart google-cast")
        print("  sudo systemctl start/stop/restart wifi-tools")
        print()
        print("System Control:")
        print("  sudo reboot")
        print("  sudo shutdown -h now")
        print("  sudo systemctl status <service>")
        print()
        print("Network Info:")
        print("  hostname -I")
        print("  ifconfig wlan0")
        print("  route -n")
        print()
        print("Press Ctrl+C to exit this dashboard")
        print()
        
    def run_dashboard(self):
        """Run the main dashboard loop"""
        try:
            while self.running:
                self.clear_screen()
                self.print_header()
                self.get_system_info()
                self.get_service_status()
                self.get_network_info()
                self.get_wifi_networks()
                self.show_help()
                
                # Update every 10 seconds
                time.sleep(10)
                
        except KeyboardInterrupt:
            print("\n\nExiting dashboard...")
            print("You can restart it with: python3 /usr/local/bin/terminal-dashboard.py")
        except Exception as e:
            print(f"\nError in dashboard: {e}")
            print("Restarting in 5 seconds...")
            time.sleep(5)
            self.run_dashboard()

def main():
    """Main entry point"""
    print("Starting Terminal Dashboard...")
    dashboard = TerminalDashboard()
    dashboard.run_dashboard()

if __name__ == "__main__":
    main()