#!/bin/bash

# Setup script to pull data from GitHub and configure the system
# This script should be run on a fresh Raspberry Pi OS installation

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# GitHub repository URL
REPO_URL="https://github.com/5u00n/raspberry-pi-3b_customos-tv-cast.git"

# Log function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root. Try 'sudo $0'"
fi

# Install required packages
log "Installing required packages..."
apt-get update
apt-get install -y git rsync

# Create working directory
WORK_DIR="/tmp/raspberry_pi_3b_customos_tv_cast_setup"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Clone the repository
log "Cloning repository from $REPO_URL..."
git clone "$REPO_URL" .

# Check if WiFi credentials exist, if not, prompt for them
if [ ! -f "configs/wifi-credentials.txt" ]; then
    log "WiFi credentials not found. Creating..."
    mkdir -p configs
    
    # Prompt for WiFi details
    read -p "Enter primary WiFi SSID: " WIFI_SSID_1
    read -p "Enter primary WiFi password: " WIFI_PASSWORD_1
    read -p "Enter secondary WiFi SSID (optional): " WIFI_SSID_2
    read -p "Enter secondary WiFi password (optional): " WIFI_PASSWORD_2
    
    # Create wifi-credentials.txt
    cat > configs/wifi-credentials.txt << EOF
# WiFi credentials for auto-connection
WIFI_SSID_1="$WIFI_SSID_1"
WIFI_PASSWORD_1="$WIFI_PASSWORD_1"
WIFI_PRIORITY_1=1

EOF

    # Add second WiFi if provided
    if [ ! -z "$WIFI_SSID_2" ]; then
        cat >> configs/wifi-credentials.txt << EOF
WIFI_SSID_2="$WIFI_SSID_2"
WIFI_PASSWORD_2="$WIFI_PASSWORD_2"
WIFI_PRIORITY_2=2
EOF
    fi
fi

# Create directories for overlay
log "Setting up overlay directories..."
mkdir -p /boot/overlay
mkdir -p /etc/systemd/system
mkdir -p /etc/network
mkdir -p /usr/local/bin
mkdir -p /home/pi
mkdir -p /etc/systemd/system/getty@tty1.service.d

# Copy overlay files
log "Copying overlay files..."
rsync -av overlays/ /boot/overlay/

# Copy firstrun.sh to boot partition
log "Copying firstrun.sh to boot partition..."
cp firstrun.sh /boot/
chmod +x /boot/firstrun.sh

# Copy wifi-credentials.txt to boot partition
log "Copying wifi-credentials.txt to boot partition..."
cp configs/wifi-credentials.txt /boot/

# Modify cmdline.txt
log "Modifying cmdline.txt..."
CMDLINE_PATH="/boot/cmdline.txt"
ORIGINAL_CMDLINE=$(cat "$CMDLINE_PATH")

# Remove any existing init= parameters
CLEANED_CMDLINE=$(echo "$ORIGINAL_CMDLINE" | sed 's/ init=[^ ]*//')

# Add our init parameter
NEW_CMDLINE="$CLEANED_CMDLINE init=/bin/bash -c \"mount -t proc proc /proc; mount -t sysfs sys /sys; mount /boot; if [ -f /boot/firstrun.sh ]; then source /boot/firstrun.sh; else exec /sbin/init; fi\""

echo "$NEW_CMDLINE" > "$CMDLINE_PATH"

log "New cmdline.txt content:"
cat "$CMDLINE_PATH"

# Copy final instructions
log "Copying final instructions..."
cp docs/FINAL_INSTRUCTIONS.md /boot/

# Cleanup
log "Cleaning up..."
cd /
rm -rf "$WORK_DIR"

log "✅ Setup complete! Reboot your system to apply changes."
log "After reboot, the system will automatically configure itself."
log "See /boot/FINAL_INSTRUCTIONS.md for more information."

read -p "Reboot now? (y/n): " REBOOT
if [[ "$REBOOT" == "y" || "$REBOOT" == "Y" ]]; then
    log "Rebooting..."
    reboot
fi
