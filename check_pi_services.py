#!/usr/bin/env python3

import subprocess
import time
import socket

def check_port(host, port):
    """Check if a port is open on the host"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(3)
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except:
        return False

def run_ssh_command(host, user, password, command):
    """Run a command on the Pi via SSH"""
    try:
        # Use ssh with password authentication
        cmd = f"sshpass -p '{password}' ssh -o StrictHostKeyChecking=no {user}@{host} '{command}'"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
        return result.returncode == 0, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return False, "", "Command timed out"
    except Exception as e:
        return False, "", str(e)

def main():
    PI_IP = "10.123.42.225"
    PI_USER = "pi"
    PI_PASS = "raspberry"
    
    print("🍓 Raspberry Pi Service Checker")
    print("=" * 40)
    print(f"Checking Pi at: {PI_IP}")
    print()
    
    # Check if Pi is reachable
    print("1. Checking Pi connectivity...")
    if check_port(PI_IP, 22):
        print("   ✅ SSH port (22) is open")
    else:
        print("   ❌ SSH port (22) is not accessible")
        return
    
    # Check web dashboard
    print("\n2. Checking web dashboard...")
    if check_port(PI_IP, 8080):
        print("   ✅ Web dashboard (port 8080) is accessible")
        try:
            import requests
            response = requests.get(f"http://{PI_IP}:8080", timeout=5)
            if response.status_code == 200:
                print("   ✅ Web dashboard is responding")
            else:
                print(f"   ⚠️  Web dashboard returned status {response.status_code}")
        except:
            print("   ⚠️  Web dashboard port open but not responding properly")
    else:
        print("   ❌ Web dashboard (port 8080) is not accessible")
    
    # Check Google Cast port
    print("\n3. Checking Google Cast service...")
    if check_port(PI_IP, 8008):
        print("   ✅ Google Cast service (port 8008) is accessible")
    else:
        print("   ❌ Google Cast service (port 8008) is not accessible")
    
    # Try SSH commands
    print("\n4. Checking services via SSH...")
    
    # Check if sshpass is available
    try:
        subprocess.run("which sshpass", shell=True, check=True, capture_output=True)
        sshpass_available = True
    except:
        sshpass_available = False
        print("   ⚠️  sshpass not available, trying alternative method...")
    
    if sshpass_available:
        # Check system info
        success, stdout, stderr = run_ssh_command(PI_IP, PI_USER, PI_PASS, "uptime && whoami")
        if success:
            print("   ✅ SSH connection successful")
            print(f"   System: {stdout.strip()}")
        else:
            print(f"   ❌ SSH connection failed: {stderr}")
        
        # Check running services
        success, stdout, stderr = run_ssh_command(PI_IP, PI_USER, PI_PASS, "systemctl list-units --type=service --state=running | grep -E '(airplay|google-cast|remote-control|ssh)'")
        if success:
            print("   ✅ Services check:")
            for line in stdout.strip().split('\n'):
                if line.strip():
                    print(f"     {line.strip()}")
        else:
            print("   ⚠️  Could not check services via SSH")
        
        # Check custom GUI process
        success, stdout, stderr = run_ssh_command(PI_IP, PI_USER, PI_PASS, "ps aux | grep raspberry-pi-gui | grep -v grep")
        if success and stdout.strip():
            print("   ✅ Custom GUI is running")
        else:
            print("   ❌ Custom GUI is not running")
    
    print("\n5. Summary:")
    print("   - Pi is reachable via SSH")
    print("   - Check the web dashboard at: http://10.123.42.225:8080")
    print("   - SSH access: ssh pi@10.123.42.225 (password: raspberry)")
    print("   - If services aren't running, you may need to start them manually")

if __name__ == "__main__":
    main()
