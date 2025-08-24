#!/bin/bash

# Test on Real Hardware
# This script prepares the SD card for testing on real Raspberry Pi 3B hardware

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE_DIR="$(pwd)"
OUTPUT_DIR="$WORKSPACE_DIR/output"
IMAGE_FILE="$OUTPUT_DIR/raspberry-pi-os.img"
OVERLAY_DIR="$WORKSPACE_DIR/overlays"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if image file exists
if [ ! -f "$IMAGE_FILE" ]; then
    error "Image file not found: $IMAGE_FILE"
fi

log "🍓 Preparing for Real Hardware Testing"
log "======================================"
log ""

# Check for SD card
log "Please insert your SD card and press Enter to continue..."
read

# List available disks
log "Available disks:"
diskutil list

# Ask for disk to flash
echo ""
read -p "Enter the disk identifier to flash (e.g., disk2): " DISK_ID

# Confirm disk selection
echo ""
echo "You selected: $DISK_ID"
echo "THIS WILL ERASE ALL DATA ON ${DISK_ID}!"
read -p "Are you sure you want to continue? (y/n): " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    error "Operation cancelled by user"
fi

# Unmount disk
log "Unmounting disk $DISK_ID..."
diskutil unmountDisk "/dev/$DISK_ID"

# Flash image
log "Flashing image to disk $DISK_ID..."
dd if="$IMAGE_FILE" of="/dev/r$DISK_ID" bs=1m

# Sync and wait
log "Syncing disk..."
sync
sleep 5

# Re-mount disk to copy overlay files
log "Re-mounting disk..."
diskutil mountDisk "/dev/$DISK_ID"
sleep 5

# Find the boot and rootfs partitions
BOOT_PART=$(diskutil list | grep -A 2 "$DISK_ID" | grep "EFI\|FAT" | awk '{print $NF}')
ROOTFS_PART=$(diskutil list | grep -A 3 "$DISK_ID" | grep "Linux" | awk '{print $NF}')

if [ -z "$BOOT_PART" ]; then
    warn "Boot partition not found automatically. Please enter the boot partition identifier:"
    read BOOT_PART
fi

if [ -z "$ROOTFS_PART" ]; then
    warn "Root filesystem partition not found automatically. Please enter the rootfs partition identifier:"
    read ROOTFS_PART
fi

log "Boot partition: $BOOT_PART"
log "Root filesystem partition: $ROOTFS_PART"

# Create mount points
BOOT_MOUNT="/tmp/rpi_boot"
ROOTFS_MOUNT="/tmp/rpi_rootfs"

mkdir -p "$BOOT_MOUNT" "$ROOTFS_MOUNT"

# Mount partitions
log "Mounting partitions..."
mount -t msdos "/dev/$BOOT_PART" "$BOOT_MOUNT" || error "Failed to mount boot partition"
mount -t ext4 "/dev/$ROOTFS_PART" "$ROOTFS_MOUNT" || error "Failed to mount rootfs partition"

# Copy overlay files
log "Copying overlay files..."
rsync -av "$OVERLAY_DIR/" "$ROOTFS_MOUNT/"

# Create wifi-credentials.txt in boot partition
log "Creating WiFi credentials file..."
cat > "$BOOT_MOUNT/wifi-credentials.txt" << 'EOF'
# WiFi credentials for auto-connection
WIFI_SSID_1="connection"
WIFI_PASSWORD_1="12qw34er"
WIFI_PRIORITY_1=1

WIFI_SSID_2="Nomita"
WIFI_PASSWORD_2="200019981996"
WIFI_PRIORITY_2=2
EOF

# Create rc.local file for first boot
log "Creating rc.local file..."
cat > "$ROOTFS_MOUNT/etc/rc.local" << 'EOF'
#!/bin/bash

# RC Local for Raspberry Pi 3B
# This script runs on every boot

LOG_FILE="/var/log/rc-local.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🍓 $1" | tee -a "$LOG_FILE"
}

log "Starting Raspberry Pi 3B configuration..."

# Check if setup is already complete
if [ ! -f "/etc/setup-complete" ]; then
    log "First boot detected, running setup..."
    
    # Wait for system to be ready
    sleep 15
    
    # Run first boot setup script if available
    if [ -f "/usr/local/bin/first-boot-setup.sh" ]; then
        log "Executing first-boot setup script..."
        chmod +x /usr/local/bin/first-boot-setup.sh
        /usr/local/bin/first-boot-setup.sh
    else
        log "First-boot setup script not found, running basic configuration..."
        
        # Configure auto-login
        log "Configuring auto-login..."
        mkdir -p /etc/systemd/system/getty@tty1.service.d/
        cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'EOT'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM
Type=idle
EOT
        
        # Configure desktop auto-login
        log "Configuring desktop auto-login..."
        mkdir -p /etc/lightdm
        cat > /etc/lightdm/lightdm.conf << 'EOT'
[SeatDefaults]
autologin-user=pi
autologin-user-timeout=0
autologin-session=openbox
user-session=openbox
autologin-guest=false
EOT
        
        # Set default target to graphical
        log "Setting default target to graphical..."
        systemctl set-default graphical.target
        
        # Mark setup as complete
        log "Marking setup as complete..."
        echo "$(date): Basic setup completed via rc.local" > /etc/setup-complete
        
        # Reboot to apply changes
        log "Rebooting to apply changes..."
        sleep 5
        reboot
    fi
else
    log "Setup already completed, ensuring services are running..."
    
    # Start desktop GUI service if not running
    if ! systemctl is-active --quiet desktop-ui.service; then
        log "Starting desktop GUI service..."
        systemctl start desktop-ui.service
    fi
    
    # Check and start other services
    services=("airplay.service" "google-cast.service" "wifi-tools.service" "remote-control.service")
    for service in "${services[@]}"; do
        if ! systemctl is-active --quiet "$service"; then
            log "Starting $service..."
            systemctl start "$service"
        fi
    done
fi

log "RC local configuration complete"
exit 0
EOF

# Make rc.local executable
chmod +x "$ROOTFS_MOUNT/etc/rc.local"

# Make scripts executable
log "Making scripts executable..."
find "$ROOTFS_MOUNT/usr/local/bin" -type f -name "*.sh" -exec chmod +x {} \;
find "$ROOTFS_MOUNT/usr/local/bin" -type f -name "*.py" -exec chmod +x {} \;

# Configure auto-login
log "Configuring auto-login..."
mkdir -p "$ROOTFS_MOUNT/etc/systemd/system/getty@tty1.service.d"
cat > "$ROOTFS_MOUNT/etc/systemd/system/getty@tty1.service.d/autologin.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM
Type=idle
Restart=always
RestartSec=1
EOF

# Set default target to graphical.target
log "Setting default target to graphical.target..."
ln -sf "/lib/systemd/system/graphical.target" "$ROOTFS_MOUNT/etc/systemd/system/default.target"

# Create a test file to verify everything worked
log "Creating test file..."
cat > "$ROOTFS_MOUNT/home/pi/TEST_SUCCESS.txt" << 'EOF'
If you can see this file, the SD card was prepared successfully!

Your Raspberry Pi 3B should:
1. Auto-login without password
2. Start the GUI dashboard automatically
3. Show detailed console logs during boot
4. Connect to WiFi automatically
5. Start all services (AirPlay, Google Cast, etc.)

If something isn't working, check the logs:
- /var/log/force-autologin.log
- /var/log/complete-startup.log
- /var/log/console-autologin.log
- /var/log/gui-app.log
EOF

# Sync and unmount
log "Syncing and unmounting..."
sync
umount "$BOOT_MOUNT"
umount "$ROOTFS_MOUNT"

# Clean up
rmdir "$BOOT_MOUNT" "$ROOTFS_MOUNT"

# Eject disk
diskutil eject "/dev/$DISK_ID"

log "✅ SD card prepared successfully!"
log "You can now insert the SD card into your Raspberry Pi 3B."
log "The system will:"
log "  1. Auto-login without password"
log "  2. Start the GUI dashboard automatically"
log "  3. Show detailed console logs during boot"
log "  4. Connect to WiFi automatically"
log "  5. Start all services (AirPlay, Google Cast, etc.)"
log ""
log "If something isn't working, check the logs:"
log "  - /var/log/force-autologin.log"
log "  - /var/log/complete-startup.log"
log "  - /var/log/console-autologin.log"
log "  - /var/log/gui-app.log"
