#!/bin/bash

# Flash Raspberry Pi OS image to SD card with overlay files
# This script flashes the base image and then copies the overlay files

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

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root (use sudo)"
fi

# Check if image file exists
if [ ! -f "$IMAGE_FILE" ]; then
    error "Image file not found: $IMAGE_FILE"
fi

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
    error "Boot partition not found"
fi

if [ -z "$ROOTFS_PART" ]; then
    error "Root filesystem partition not found"
fi

log "Boot partition: $BOOT_PART"
log "Root filesystem partition: $ROOTFS_PART"

# Create mount points
BOOT_MOUNT="/tmp/rpi_boot"
ROOTFS_MOUNT="/tmp/rpi_rootfs"

mkdir -p "$BOOT_MOUNT" "$ROOTFS_MOUNT"

# Mount partitions
log "Mounting partitions..."
mount -t msdos "/dev/$BOOT_PART" "$BOOT_MOUNT"
mount -t ext4 "/dev/$ROOTFS_PART" "$ROOTFS_MOUNT"

# Copy overlay files
log "Copying overlay files..."
rsync -av "$OVERLAY_DIR/" "$ROOTFS_MOUNT/"

# Copy config files
if [ -d "$WORKSPACE_DIR/configs" ]; then
    log "Copying configuration files..."
    rsync -av "$WORKSPACE_DIR/configs/" "$BOOT_MOUNT/"
fi

# Copy packages list
if [ -f "$WORKSPACE_DIR/packages/packages.txt" ]; then
    log "Copying packages list..."
    cp "$WORKSPACE_DIR/packages/packages.txt" "$BOOT_MOUNT/"
fi

# Copy setup script
if [ -f "$WORKSPACE_DIR/scripts/setup.sh" ]; then
    log "Copying setup script..."
    cp "$WORKSPACE_DIR/scripts/setup.sh" "$BOOT_MOUNT/"
    chmod +x "$BOOT_MOUNT/setup.sh"
fi

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

# Enable systemd services
log "Enabling systemd services..."
for service_file in $(find "$OVERLAY_DIR/etc/systemd/system" -name "*.service"); do
    service_name=$(basename "$service_file")
    log "Enabling service: $service_name"
    
    # Create symlink in /etc/systemd/system/multi-user.target.wants/
    mkdir -p "$ROOTFS_MOUNT/etc/systemd/system/multi-user.target.wants"
    ln -sf "/etc/systemd/system/$service_name" "$ROOTFS_MOUNT/etc/systemd/system/multi-user.target.wants/$service_name"
    
    # Create symlink in /etc/systemd/system/graphical.target.wants/ for GUI services
    if [[ "$service_name" == *"desktop"* || "$service_name" == *"autologin"* || "$service_name" == *"startup"* ]]; then
        mkdir -p "$ROOTFS_MOUNT/etc/systemd/system/graphical.target.wants"
        ln -sf "/etc/systemd/system/$service_name" "$ROOTFS_MOUNT/etc/systemd/system/graphical.target.wants/$service_name"
    fi
done

# Sync and unmount
log "Syncing and unmounting..."
sync
umount "$BOOT_MOUNT"
umount "$ROOTFS_MOUNT"

# Clean up
rmdir "$BOOT_MOUNT" "$ROOTFS_MOUNT"

# Eject disk
diskutil eject "/dev/$DISK_ID"

log "Flash completed successfully!"
log "You can now insert the SD card into your Raspberry Pi 3B."
log "The system will auto-login and start the GUI automatically."
