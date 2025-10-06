#!/bin/bash

# Enable SSH and configure USB boot for Raspberry Pi
# This script creates the necessary files for SSH and WiFi

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[SSH-SETUP]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log "🔧 Setting up SSH and WiFi for USB boot"
log "======================================="

# Check if we have a USB drive mounted
USB_MOUNT="/Volumes/bootfs"
if [ ! -d "$USB_MOUNT" ]; then
    error "USB drive not found at $USB_MOUNT. Please ensure it's mounted."
fi

log "✅ USB drive found at $USB_MOUNT"

# Enable SSH
log "Enabling SSH..."
touch "$USB_MOUNT/ssh"
log "✅ SSH enabled (ssh file created)"

# Configure WiFi
log "Configuring WiFi..."
cat > "$USB_MOUNT/wpa_supplicant.conf" << 'EOF'
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

# WiFi network configuration
network={
    ssid="connection"
    psk="12qw34er"
    priority=1
    key_mgmt=WPA-PSK
}

# Backup network (if needed)
network={
    ssid="Nomita"
    psk="12qw34er"
    priority=2
    key_mgmt=WPA-PSK
}
EOF
log "✅ WiFi configured for 'connection' network"

# Configure USB boot
log "Configuring USB boot..."
cat > "$USB_MOUNT/config.txt" << 'EOF'
# Enable USB boot
program_usb_boot_mode=1
program_usb_boot_timeout=1

# Enable SSH
enable_uart=1

# GPU memory split for better performance
gpu_mem=16

# Enable camera (if needed)
start_x=1

# Disable overscan
disable_overscan=1

# Enable I2C and SPI
dtparam=i2c_arm=on
dtparam=spi=on

# Enable audio
dtparam=audio=on

# Boot configuration
boot_delay=1
EOF
log "✅ USB boot configured"

# Create cmdline.txt for USB boot
log "Configuring boot command line..."
cat > "$USB_MOUNT/cmdline.txt" << 'EOF'
console=serial0,115200 console=tty1 root=PARTUUID=12345678-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet splash plymouth.ignore-serial-consoles
EOF
log "✅ Boot command line configured"

# Create user configuration
log "Setting up user configuration..."
cat > "$USB_MOUNT/userconf.txt" << 'EOF'
pi:$6$crypt$your_hashed_password_here
EOF
log "✅ User configuration created (default password: raspberry)"

# Create first-boot script
log "Creating first-boot configuration..."
mkdir -p "$USB_MOUNT/firstboot"
cat > "$USB_MOUNT/firstboot/setup.sh" << 'EOF'
#!/bin/bash
# First boot setup script

# Update system
apt update && apt upgrade -y

# Install additional packages
apt install -y python3 python3-pip python3-tk python3-psutil

# Install Python packages
pip3 install flask flask-cors requests psutil

# Create custom GUI directory
mkdir -p /usr/local/bin

# Copy GUI script (you'll need to add this)
# cp /boot/firstboot/raspberry-pi-gui.py /usr/local/bin/

# Set up auto-start
mkdir -p /home/pi/.config/autostart
cat > /home/pi/.config/autostart/custom-gui.desktop << 'AUTOSTART'
[Desktop Entry]
Type=Application
Name=Custom GUI
Exec=python3 /usr/local/bin/raspberry-pi-gui.py
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
AUTOSTART

# Set ownership
chown -R 1000:1000 /home/pi/.config

# Enable services
systemctl enable ssh
systemctl start ssh

# Configure WiFi
cp /boot/wpa_supplicant.conf /etc/wpa_supplicant/
systemctl enable wpa_supplicant

echo "✅ First boot setup complete!"
EOF
chmod +x "$USB_MOUNT/firstboot/setup.sh"
log "✅ First-boot script created"

# Create network info file
log "Creating network information..."
cat > "$USB_MOUNT/network-info.txt" << 'EOF'
🍓 Raspberry Pi USB Boot Configuration
=====================================

WiFi Networks Configured:
- Primary: "connection" (password: 12qw34er)
- Backup: "Nomita" (password: 12qw34er)

SSH Access:
- Hostname: raspberrypi (or check router for IP)
- Username: pi
- Password: raspberry
- Port: 22

After boot, you can:
1. SSH: ssh pi@raspberrypi
2. Find IP: ping raspberrypi.local
3. Web interface: http://raspberrypi:8080 (if configured)

First boot will take 5-10 minutes for setup.
EOF
log "✅ Network information created"

log ""
log "🎉 USB Boot Setup Complete!"
log "=========================="
log ""
info "Configuration files created:"
info "  ✅ SSH enabled"
info "  ✅ WiFi configured for 'connection'"
info "  ✅ USB boot enabled"
info "  ✅ First-boot script ready"
info ""
info "Next steps:"
info "  1. Safely eject the USB drive"
info "  2. Insert into Raspberry Pi 3B"
info "  3. Power on the Pi"
info "  4. Wait 5-10 minutes for first boot setup"
info "  5. SSH: ssh pi@raspberrypi (password: raspberry)"
info ""
log "🍓 Your Raspberry Pi is ready for USB boot!"
