#!/usr/bin/env python3

"""
Simple WiFi Setup for Raspberry Pi 3B
"""

import os
import sys
import subprocess
import json

def add_wifi_network(ssid, password, priority=1):
    """Add WiFi network to wpa_supplicant"""
    try:
        # Read existing config if it exists
        existing_config = ""
        if os.path.exists("/etc/wpa_supplicant/wpa_supplicant.conf"):
            with open("/etc/wpa_supplicant/wpa_supplicant.conf", "r") as f:
                existing_config = f.read()
        
        # If no existing config, create header
        if "country=US" not in existing_config:
            config = """country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

"""
        else:
            # Extract header from existing config
            header_end = existing_config.find("network={")
            if header_end != -1:
                config = existing_config[:header_end]
            else:
                config = existing_config
        
        # Add new network
        network_config = f"""network={{
    ssid="{ssid}"
    psk="{password}"
    key_mgmt=WPA-PSK
    priority={priority}
}}

"""
        
        config += network_config
        
        # Write updated configuration
        with open("/etc/wpa_supplicant/wpa_supplicant.conf", "w") as f:
            f.write(config)
        
        # Restart networking
        subprocess.run(["sudo", "systemctl", "restart", "wpa_supplicant"])
        subprocess.run(["sudo", "systemctl", "restart", "networking"])
        
        print(f"WiFi network {ssid} added successfully with priority {priority}!")
        return True
        
    except Exception as e:
        print(f"Error adding network: {e}")
        return False

def scan_networks():
    """Scan for available WiFi networks"""
    try:
        result = subprocess.run(["sudo", "iwlist", "wlan0", "scan"], 
                              capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            print("Available networks:")
            lines = result.stdout.split('\n')
            for line in lines:
                if 'ESSID:' in line:
                    ssid = line.split('"')[1] if '"' in line else 'Unknown'
                    print(f"  - {ssid}")
        else:
            print("Failed to scan networks")
            
    except Exception as e:
        print(f"Error scanning: {e}")

def main():
    if len(sys.argv) > 1:
        command = sys.argv[1]
        
        if command == "add" and len(sys.argv) >= 4:
            ssid = sys.argv[2]
            password = sys.argv[3]
            priority = int(sys.argv[4]) if len(sys.argv) > 4 else 1
            add_wifi_network(ssid, password, priority)
            
        elif command == "scan":
            scan_networks()
            
        else:
            print("Usage: wifi-setup.py add <ssid> <password> [priority]")
            print("       wifi-setup.py scan")
            print("       wifi-setup.py add 'connection' '12qw34er' 1")
            print("       wifi-setup.py add 'Nomita' '200019981996' 2")
    else:
        print("WiFi Setup Tool")
        print("Usage: wifi-setup.py add <ssid> <password> [priority]")
        print("       wifi-setup.py scan")
        print("")
        print("Examples:")
        print("  wifi-setup.py add 'connection' '12qw34er' 1")
        print("  wifi-setup.py add 'Nomita' '200019981996' 2")

if __name__ == "__main__":
    main()
