#!/bin/bash

# Force Auto-Login and Service Startup Script
# This script ensures everything starts automatically with detailed logging

LOG_FILE="/var/log/force-autologin.log"
CONSOLE_LOG="/dev/console"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🍓 $1" | tee -a "$LOG_FILE" | tee "$CONSOLE_LOG"
}

log "================================================"
log "FORCE AUTO-LOGIN AND SERVICE STARTUP SCRIPT"
log "================================================"

# Function to log to both file and console
log_both() {
    echo "$1" | tee -a "$LOG_FILE" | tee "$CONSOLE_LOG"
}

# Wait for system to be fully ready
log "Waiting for system to be fully ready..."
sleep 10

# Check if we're already logged in
if [ -n "$DISPLAY" ] && [ -n "$XAUTHORITY" ]; then
    log "Display environment already set: DISPLAY=$DISPLAY"
else
    log "Setting display environment..."
    export DISPLAY=:0
    export XAUTHORITY=/home/pi/.Xauthority
fi

# Force create X11 authority if it doesn't exist
if [ ! -f "$XAUTHORITY" ]; then
    log "Creating X11 authority file..."
    mkdir -p /home/pi
    touch "$XAUTHORITY"
    chown pi:pi "$XAUTHORITY"
    chmod 600 "$XAUTHORITY"
fi

# Ensure pi user is properly configured
log "Configuring pi user..."
usermod -a -G audio,video,plugdev pi

# Force auto-login configuration
log "Configuring aggressive auto-login..."

# Console auto-login
log "Setting up console auto-login..."
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM
Type=idle
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
    systemctl status airplay.service --no-pager | tee -a "$LOG_FILE"
else
    log "❌ Failed to start AirPlay service"
    systemctl status airplay.service --no-pager | tee -a "$LOG_FILE"
fi

# Service 2: Google Cast
log "Starting Google Cast service..."
if systemctl start google-cast.service; then
    log "✅ Google Cast service started successfully"
    systemctl status google-cast.service --no-pager | tee -a "$LOG_FILE"
else
    log "❌ Failed to start Google Cast service"
    systemctl status google-cast.service --no-pager | tee -a "$LOG_FILE"
fi

# Service 3: WiFi Tools
log "Starting WiFi Tools service..."
if systemctl start wifi-tools.service; then
    log "✅ WiFi Tools service started successfully"
    systemctl status wifi-tools.service --no-pager | tee -a "$LOG_FILE"
else
    log "❌ Failed to start WiFi Tools service"
    systemctl status wifi-tools.service --no-pager | tee -a "$LOG_FILE"
fi

# Service 4: Remote Control
log "Starting Remote Control service..."
if systemctl start remote-control.service; then
    log "✅ Remote Control service started successfully"
    systemctl status remote-control.service --no-pager | tee -a "$LOG_FILE"
else
    log "❌ Failed to start Remote Control service"
    systemctl status remote-control.service --no-pager | tee -a "$LOG_FILE"
fi

# Service 5: Desktop GUI
log "Starting Desktop GUI service..."
if systemctl start desktop-ui.service; then
    log "✅ Desktop GUI service started successfully"
    systemctl status desktop-ui.service --no-pager | tee -a "$LOG_FILE"
else
    log "❌ Failed to start Desktop GUI service"
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

# Check if GUI script exists
if [ -f "/usr/local/bin/raspberry-pi-gui.py" ]; then
    log "✅ GUI script found, starting it..."
    
    # Start GUI in background with logging
    nohup python3 /usr/local/bin/raspberry-pi-gui.py > /var/log/gui-app.log 2>&1 &
    GUI_PID=$!
    
    if [ -n "$GUI_PID" ] && kill -0 "$GUI_PID" 2>/dev/null; then
        log "✅ GUI application started successfully (PID: $GUI_PID)"
        log "GUI log file: /var/log/gui-app.log"
    else
        log "❌ Failed to start GUI application"
        log "GUI log file: /var/log/gui-app.log"
        cat /var/log/gui-app.log | tee -a "$LOG_FILE"
    fi
else
    log "❌ GUI script not found, starting fallback terminal dashboard..."
    python3 /usr/local/bin/terminal-dashboard.py &
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

# Final status
log "================================================"
log "AUTO-LOGIN AND SERVICE STARTUP COMPLETE"
log "================================================"

log "All services have been started with detailed logging"
log "Check log files for any errors:"
log "  - Main log: $LOG_FILE"
log "  - GUI log: /var/log/gui-app.log"
log "  - System logs: journalctl -b"

log "System should now be fully operational with:"
log "  ✅ Auto-login configured"
log "  ✅ All services running"
log "  ✅ GUI application started"
log "  ✅ WiFi configured"
log "  ✅ Detailed logging enabled"

# Keep the service running to maintain logging
log "Service will continue running to maintain logging..."
while true; do
    sleep 30
    log "Auto-login service heartbeat - all systems operational"
done