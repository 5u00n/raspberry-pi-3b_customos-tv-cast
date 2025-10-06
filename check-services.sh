#!/bin/bash

# Check Raspberry Pi services remotely
# This script will help verify all services are running

PI_IP="10.123.42.225"
PI_USER="pi"
PI_PASS="raspberry"

echo "🍓 Checking Raspberry Pi Services"
echo "================================="
echo "IP: $PI_IP"
echo "User: $PI_USER"
echo ""

# Function to run commands on Pi
run_on_pi() {
    echo "Running: $1"
    echo "----------------------------------------"
    # Using expect to handle password authentication
    expect << EOF
spawn ssh -o StrictHostKeyChecking=no $PI_USER@$PI_IP "$1"
expect "password:"
send "$PI_PASS\r"
expect eof
EOF
    echo ""
}

echo "1. Testing SSH connection..."
run_on_pi "echo 'SSH connection successful!' && whoami && hostname"

echo "2. Checking system status..."
run_on_pi "uptime && free -h && df -h /"

echo "3. Checking running services..."
run_on_pi "systemctl list-units --type=service --state=running | grep -E '(airplay|google-cast|remote-control|ssh|lightdm)'"

echo "4. Checking custom GUI process..."
run_on_pi "ps aux | grep raspberry-pi-gui"

echo "5. Checking network services..."
run_on_pi "netstat -tlnp | grep -E ':(22|8080|8008|5353)'"

echo "6. Checking WiFi connection..."
run_on_pi "iwconfig wlan0 2>/dev/null || echo 'WiFi interface not found'"

echo "7. Checking installed packages..."
run_on_pi "dpkg -l | grep -E '(shairport|samba|nginx|python3)'"

echo "8. Checking custom scripts..."
run_on_pi "ls -la /usr/local/bin/ | grep -E '(raspberry-pi-gui|airplay-service|google-cast-service|remote-control-server)'"

echo "9. Checking web dashboard..."
run_on_pi "curl -s http://localhost:8080 | head -10 || echo 'Web dashboard not responding'"

echo "10. Checking AirPlay service..."
run_on_pi "systemctl status airplay.service --no-pager"

echo "11. Checking Google Cast service..."
run_on_pi "systemctl status google-cast.service --no-pager"

echo "12. Checking Remote Control service..."
run_on_pi "systemctl status remote-control.service --no-pager"

echo ""
echo "✅ Service check complete!"
echo "If any services are not running, you may need to start them manually."
