#!/bin/bash

# Complete Raspberry Pi 3B Startup Script
# This script handles auto-login, GUI startup, and all services with detailed logging

LOG_FILE="/var/log/complete-startup.log"
CONSOLE_LOG="/dev/console"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🍓 $1" | tee -a "$LOG_FILE" | tee "$CONSOLE_LOG"
}

log "================================================"
log "COMPLETE RASPBERRY PI 3B STARTUP SCRIPT"
log "================================================"

# Function to log to both file and console
log_both() {
    echo "$1" | tee -a "$LOG_FILE" | tee "$CONSOLE_LOG"
}

# Wait for system to be fully ready
log "Waiting for system to be fully ready..."
sleep 15

# Check and set display environment
log "Setting up display environment..."
export DISPLAY=:0
export XAUTHORITY=/home/pi/.Xauthority

# Ensure X11 authority exists
if [ ! -f "$XAUTHORITY" ]; then
    log "Creating X11 authority file..."
    mkdir -p /home/pi
    touch "$XAUTHORITY"
    chown pi:pi "$XAUTHORITY"
    chmod 600 "$XAUTHORITY"
fi

# Force auto-login configuration
log "Configuring aggressive auto-login system..."

# Console auto-login
log "Setting up console auto-login..."
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM
Type=idle
Restart=always
RestartSec=1
EOF

# Desktop auto-login
log "Setting up desktop auto-login..."
mkdir -p /etc/lightdm
cat > /etc/lightdm/lightdm.conf << 'EOF'
[SeatDefaults]
autologin-user=pi
autologin-user-timeout=0
autologin-session=openbox
user-session=openbox
autologin-guest=false
EOF

# Force graphical target
log "Setting default target to graphical..."
systemctl set-default graphical.target

# Reload systemd
log "Reloading systemd configuration..."
systemctl daemon-reload

# Start all services with detailed logging
log "================================================"
log "STARTING ALL SERVICES WITH DETAILED LOGGING"
log "================================================"

# Service 1: AirPlay
log "Starting AirPlay service..."
if systemctl start airplay.service; then
    log "✅ AirPlay service started successfully"
    log "AirPlay service status:"
    systemctl status airplay.service --no-pager | tee -a "$LOG_FILE"
else
    log "❌ Failed to start AirPlay service"
    log "AirPlay service error:"
    systemctl status airplay.service --no-pager | tee -a "$LOG_FILE"
fi

# Service 2: Google Cast
log "Starting Google Cast service..."
if systemctl start google-cast.service; then
    log "✅ Google Cast service started successfully"
    log "Google Cast service status:"
    systemctl status google-cast.service --no-pager | tee -a "$LOG_FILE"
else
    log "❌ Failed to start Google Cast service"
    log "Google Cast service error:"
    systemctl status google-cast.service --no-pager | tee -a "$LOG_FILE"
fi

# Service 3: WiFi Tools
log "Starting WiFi Tools service..."
if systemctl start wifi-tools.service; then
    log "✅ WiFi Tools service started successfully"
    log "WiFi Tools service status:"
    systemctl status wifi-tools.service --no-pager | tee -a "$LOG_FILE"
else
    log "❌ Failed to start WiFi Tools service"
    log "WiFi Tools service error:"
    systemctl status wifi-tools.service --no-pager | tee -a "$LOG_FILE"
fi

# Service 4: Remote Control
log "Starting Remote Control service..."
if systemctl start remote-control.service; then
    log "✅ Remote Control service started successfully"
    log "Remote Control service status:"
    systemctl status remote-control.service --no-pager | tee -a "$LOG_FILE"
else
    log "❌ Failed to start Remote Control service"
    log "Remote Control service error:"
    systemctl status remote-control.service --no-pager | tee -a "$LOG_FILE"
fi

# Service 5: Desktop GUI
log "Starting Desktop GUI service..."
if systemctl start desktop-ui.service; then
    log "✅ Desktop GUI service started successfully"
    log "Desktop GUI service status:"
    systemctl status desktop-ui.service --no-pager | tee -a "$LOG_FILE"
else
    log "❌ Failed to start Desktop GUI service"
    log "Desktop GUI service error:"
    systemctl status desktop-ui.service --no-pager | tee -a "$LOG_FILE"
fi

# Check all service statuses
log "================================================"
log "SERVICE STATUS SUMMARY"
log "================================================"

services=("airplay.service" "google-cast.service" "wifi-tools.service" "remote-control.service" "desktop-ui.service")

for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        log "🟢 $service: RUNNING"
    else
        log "🔴 $service: STOPPED"
        log "Last 10 lines of $service log:"
        journalctl -u "$service" -n 10 --no-pager | tee -a "$LOG_FILE"
    fi
done

# Force start GUI application directly
log "================================================"
log "FORCE STARTING GUI APPLICATION"
log "================================================"

# Check if tkinter is available
log "Checking Python tkinter availability..."
if python3 -c "import tkinter; print('Tkinter OK')" 2>/dev/null; then
    log "✅ Tkinter is available"
else
    log "❌ Tkinter not available, installing..."
    apt-get update
    apt-get install -y python3-tk
fi

# Check if GUI script exists and start it
if [ -f "/usr/local/bin/raspberry-pi-gui.py" ]; then
    log "✅ GUI script found, starting it..."
    
    # Start GUI in background with logging
    nohup python3 /usr/local/bin/raspberry-pi-gui.py > /var/log/gui-app.log 2>&1 &
    GUI_PID=$!
    
    if [ -n "$GUI_PID" ] && kill -0 "$GUI_PID" 2>/dev/null; then
        log "✅ GUI application started successfully (PID: $GUI_PID)"
        log "GUI log file: /var/log/gui-app.log"
        log "GUI process info:"
        ps aux | grep "$GUI_PID" | tee -a "$LOG_FILE"
    else
        log "❌ Failed to start GUI application"
        log "GUI log file: /var/log/gui-app.log"
        log "GUI error log:"
        cat /var/log/gui-app.log | tee -a "$LOG_FILE"
    fi
else
    log "❌ GUI script not found, starting fallback terminal dashboard..."
    nohup python3 /usr/local/bin/terminal-dashboard.py > /var/log/terminal-dashboard.log 2>&1 &
    DASHBOARD_PID=$!
    log "Terminal dashboard started with PID: $DASHBOARD_PID"
fi

# Network status check
log "================================================"
log "NETWORK STATUS CHECK"
log "================================================"

log "Checking WiFi status..."
if command -v iwconfig >/dev/null 2>&1; then
    iwconfig wlan0 2>/dev/null | tee -a "$LOG_FILE"
else
    log "iwconfig not available"
fi

log "Checking IP address..."
if command -v hostname >/dev/null 2>&1; then
    hostname -I | tee -a "$LOG_FILE"
else
    log "hostname command not available"
fi

# WiFi configuration check
log "Checking WiFi configuration..."
if [ -f "/etc/wpa_supplicant/wpa_supplicant.conf" ]; then
    log "✅ WiFi configuration file exists"
    log "WiFi networks configured:"
    grep "ssid=" /etc/wpa_supplicant/wpa_supplicant.conf | tee -a "$LOG_FILE"
else
    log "❌ WiFi configuration file not found"
fi

# Final status and continuous monitoring
log "================================================"
log "STARTUP COMPLETE - MONITORING MODE"
log "================================================"

log "All services have been started with detailed logging"
log "Check log files for any errors:"
log "  - Main startup log: $LOG_FILE"
log "  - GUI log: /var/log/gui-app.log"
log "  - Terminal dashboard log: /var/log/terminal-dashboard.log"
log "  - System logs: journalctl -b"

log "System should now be fully operational with:"
log "  ✅ Auto-login configured"
log "  ✅ All services running"
log "  ✅ GUI application started"
log "  ✅ WiFi configured"
log "  ✅ Detailed logging enabled"

# Continuous monitoring and logging
log "Entering continuous monitoring mode..."
log "Service will continue running to maintain logging and monitor system health..."

while true; do
    sleep 30
    
    # Log heartbeat
    log "=== HEARTBEAT - SYSTEM STATUS CHECK ==="
    
    # Check service statuses
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log "🟢 $service: RUNNING"
        else
            log "🔴 $service: STOPPED - Attempting restart..."
            systemctl restart "$service"
        fi
    done
    
    # Check GUI process
    if [ -n "$GUI_PID" ] && kill -0 "$GUI_PID" 2>/dev/null; then
        log "✅ GUI application running (PID: $GUI_PID)"
    else
        log "❌ GUI application not running, restarting..."
        if [ -f "/usr/local/bin/raspberry-pi-gui.py" ]; then
            nohup python3 /usr/local/bin/raspberry-pi-gui.py > /var/log/gui-app.log 2>&1 &
            GUI_PID=$!
            log "✅ GUI application restarted (PID: $GUI_PID)"
        fi
    fi
    
    # Check network status
    if command -v hostname >/dev/null 2>&1; then
        IP=$(hostname -I | awk '{print $1}')
        if [ -n "$IP" ]; then
            log "🌐 Network active - IP: $IP"
        else
            log "❌ No network IP detected"
        fi
    fi
    
    log "=== HEARTBEAT COMPLETE ==="
done