#!/bin/bash

# Console Auto-Login Script
# This script automatically logs in the pi user and starts the GUI

LOG_FILE="/var/log/console-autologin.log"
CONSOLE_LOG="/dev/console"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🍓 $1" | tee -a "$LOG_FILE" | tee "$CONSOLE_LOG"
}

log "================================================"
log "CONSOLE AUTO-LOGIN SCRIPT STARTED"
log "================================================"

# Wait a moment for system to be ready
sleep 5

# Force login as pi user
log "Forcing login as pi user..."
exec su - pi << 'EOF'
# Set display environment
export DISPLAY=:0
export XAUTHORITY=/home/pi/.Xauthority

# Log that we're logged in
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🍓 Successfully logged in as pi user" | tee -a /var/log/console-autologin.log

# Start the GUI application
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🍓 Starting GUI application..." | tee -a /var/log/console-autologin.log

# Check if GUI script exists and start it
if [ -f "/usr/local/bin/raspberry-pi-gui.py" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🍓 GUI script found, starting..." | tee -a /var/log/console-autologin.log
    python3 /usr/local/bin/raspberry-pi-gui.py
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🍓 GUI script not found, starting terminal dashboard..." | tee -a /var/log/console-autologin.log
    python3 /usr/local/bin/terminal-dashboard.py
fi
EOF