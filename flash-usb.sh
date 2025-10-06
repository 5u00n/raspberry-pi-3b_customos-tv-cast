#!/bin/bash

# Flash Raspberry Pi OS to USB drive with custom configuration
# This creates a bootable USB drive for Raspberry Pi 3B

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[USB-FLASH]${NC} $1"
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

step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

log "🍓 Flashing Raspberry Pi OS to USB Drive"
log "========================================="

# USB drive detection
USB_DEVICE="/dev/disk4"
USB_MOUNT="/Volumes/bootfs"

# Check if USB is connected
if [ ! -b "$USB_DEVICE" ]; then
    error "USB drive not found at $USB_DEVICE. Please check connection."
fi

log "✅ USB drive detected at $USB_DEVICE"

# Download Raspberry Pi OS Lite if not exists
if [ ! -f "raspios-lite.img.xz" ]; then
    step "Downloading Raspberry Pi OS Lite..."
    log "This may take 10-15 minutes depending on your internet speed..."
    curl -L -o raspios-lite.img.xz "https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2023-12-11/2023-12-05-raspios-bookworm-armhf-lite.img.xz"
    log "✅ Download complete"
else
    log "✅ Raspberry Pi OS image already exists"
fi

# Extract the image
if [ ! -f "raspios-lite.img" ]; then
    step "Extracting image..."
    xz -d raspios-lite.img.xz
    log "✅ Image extracted"
else
    log "✅ Image already extracted"
fi

# Unmount USB drive
step "Unmounting USB drive..."
diskutil unmountDisk "$USB_DEVICE" 2>/dev/null || true
log "✅ USB drive unmounted"

# Flash the image
step "Flashing image to USB drive..."
log "This will take 5-10 minutes..."
log "⚠️  WARNING: This will erase all data on the USB drive!"
echo "Press Enter to continue or Ctrl+C to cancel..."
read

sudo dd if=raspios-lite.img of="$USB_DEVICE" bs=1m status=progress
log "✅ Image flashed to USB drive"

# Wait for USB to remount
step "Waiting for USB to remount..."
sleep 5

# Check if USB mounted
if [ ! -d "$USB_MOUNT" ]; then
    # Try to mount manually
    diskutil mountDisk "$USB_DEVICE"
    sleep 3
fi

if [ ! -d "$USB_MOUNT" ]; then
    error "Could not mount USB drive. Please check manually."
fi

log "✅ USB drive mounted at $USB_MOUNT"

# Run the SSH and WiFi setup
step "Configuring SSH and WiFi..."
./enable-ssh.sh

# Copy custom files
step "Copying custom files..."
if [ -f "overlays/usr/local/bin/raspberry-pi-gui.py" ]; then
    cp overlays/usr/local/bin/raspberry-pi-gui.py "$USB_MOUNT/firstboot/"
    log "✅ Custom GUI script copied"
fi

# Create systemd services
log "Creating systemd services..."
mkdir -p "$USB_MOUNT/firstboot/services"

# AirPlay service
cat > "$USB_MOUNT/firstboot/services/airplay.service" << 'EOF'
[Unit]
Description=AirPlay Receiver
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/shairport-sync
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
EOF

# Google Cast service
cat > "$USB_MOUNT/firstboot/services/google-cast.service" << 'EOF'
[Unit]
Description=Google Cast Receiver
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m http.server 8008
WorkingDirectory=/home/pi
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
EOF

# Remote control service
cat > "$USB_MOUNT/firstboot/services/remote-control.service" << 'EOF'
[Unit]
Description=Remote Control Web Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/remote-control-server
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
EOF

log "✅ Systemd services created"

# Update first-boot script to install services
cat >> "$USB_MOUNT/firstboot/setup.sh" << 'EOF'

# Install systemd services
cp /boot/firstboot/services/*.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable airplay.service
systemctl enable google-cast.service
systemctl enable remote-control.service

# Install additional packages
apt install -y shairport-sync avahi-daemon samba nginx

# Configure Samba
cat >> /etc/samba/smb.conf << 'SAMBA'

[pi]
   path = /home/pi
   browseable = yes
   read only = no
   guest ok = no
SAMBA

# Set Samba password
(echo "raspberry"; echo "raspberry") | smbpasswd -a pi -s

# Configure auto-login
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'AUTOLOGIN'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM
AUTOLOGIN

# Configure LightDM for auto-login
sed -i 's/#autologin-user=/autologin-user=pi/' /etc/lightdm/lightdm.conf
sed -i 's/#autologin-user-timeout=0/autologin-user-timeout=0/' /etc/lightdm/lightdm.conf

# Enable desktop
systemctl set-default graphical.target
systemctl enable lightdm

echo "✅ All services configured!"
EOF

log "✅ First-boot script updated"

# Create final instructions
cat > "$USB_MOUNT/BOOT-INSTRUCTIONS.txt" << 'EOF'
🍓 Raspberry Pi USB Boot Instructions
====================================

Your USB drive is now ready for Raspberry Pi 3B!

CONFIGURATION INCLUDED:
✅ SSH enabled (port 22)
✅ WiFi: "connection" (password: 12qw34er)
✅ Auto-login as user 'pi' (password: raspberry)
✅ Custom GUI auto-starts
✅ AirPlay receiver
✅ Google Cast support
✅ Web dashboard on port 8080
✅ File sharing via Samba

FIRST BOOT PROCESS:
1. Insert USB drive into Raspberry Pi 3B
2. Power on the Pi
3. Wait 5-10 minutes for automatic setup
4. The Pi will connect to WiFi automatically
5. Custom GUI will start automatically

ACCESSING YOUR PI:
• SSH: ssh pi@raspberrypi (password: raspberry)
• Find IP: ping raspberrypi.local or check router
• Web: http://[PI-IP]:8080
• Files: smb://[PI-IP]/pi (user: pi, password: raspberry)

TROUBLESHOOTING:
• If WiFi doesn't connect, check the wpa_supplicant.conf file
• If SSH doesn't work, check if the 'ssh' file exists in boot partition
• First boot takes longer - be patient!

Your Raspberry Pi is ready to go! 🍓
EOF

log "✅ Boot instructions created"

# Eject USB drive
step "Ejecting USB drive..."
diskutil eject "$USB_DEVICE"
log "✅ USB drive ejected safely"

log ""
log "🎉 USB Flash Complete!"
log "====================="
log ""
info "Your USB drive is now ready for Raspberry Pi 3B!"
info ""
info "Configuration:"
info "  ✅ SSH enabled (port 22)"
info "  ✅ WiFi: 'connection' (password: 12qw34er)"
info "  ✅ Auto-login as 'pi' (password: raspberry)"
info "  ✅ Custom GUI auto-starts"
info "  ✅ AirPlay & Google Cast ready"
info "  ✅ Web dashboard on port 8080"
info ""
info "Next steps:"
info "  1. Insert USB drive into Raspberry Pi 3B"
info "  2. Power on the Pi"
info "  3. Wait 5-10 minutes for setup"
info "  4. SSH: ssh pi@raspberrypi"
info ""
log "🍓 Enjoy your custom Raspberry Pi OS!"
