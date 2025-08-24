#!/bin/bash

# Backup SD Card and Test with QEMU
# This script creates a backup of your SD card and tests it with QEMU

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE_DIR="$(pwd)"
OUTPUT_DIR="$WORKSPACE_DIR/output"
BACKUP_IMG="$OUTPUT_DIR/sd_card_backup.img"
KERNEL_DIR="$WORKSPACE_DIR/qemu_kernel"
KERNEL="$KERNEL_DIR/kernel-qemu-4.19.50-buster"
DTB="$KERNEL_DIR/versatile-pb-buster.dtb"

log() {
    echo -e "${GREEN}$1${NC}"
}

warn() {
    echo -e "${YELLOW}$1${NC}"
}

error() {
    echo -e "${RED}$1${NC}"
    exit 1
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root (use sudo)"
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR" "$KERNEL_DIR"

# List available disks
log "Available disks:"
diskutil list

# Ask for disk to backup
echo ""
read -p "Enter the disk identifier of your SD card (e.g., disk4): " DISK_ID

# Confirm disk selection
echo ""
echo "You selected: $DISK_ID"
echo "THIS WILL CREATE A BACKUP OF ${DISK_ID}!"
read -p "Are you sure you want to continue? (y/n): " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    error "Operation cancelled by user"
fi

# Create backup of the SD card (only the first 2GB which contains the OS)
log "Creating backup of SD card (first 2GB only)..."
dd if="/dev/r$DISK_ID" of="$BACKUP_IMG" bs=1m count=2000

log "SD card backup created: $BACKUP_IMG"

# Download kernel files if they don't exist
if [ ! -f "$KERNEL" ]; then
    log "Downloading QEMU kernel..."
    curl -L -o "$KERNEL" "https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-4.19.50-buster"
fi

if [ ! -f "$DTB" ]; then
    log "Downloading device tree blob..."
    curl -L -o "$DTB" "https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/versatile-pb-buster.dtb"
fi

# Check if files exist
if [ ! -f "$BACKUP_IMG" ]; then
    error "Backup image not found: $BACKUP_IMG"
fi

if [ ! -f "$KERNEL" ]; then
    error "Kernel not found: $KERNEL"
fi

if [ ! -f "$DTB" ]; then
    error "Device tree blob not found: $DTB"
fi

log "✅ All required files found!"

# Make sure no other QEMU instances are running
pkill -f qemu-system-arm || true
sleep 2

# Start QEMU with the backup image
log "🚀 Starting QEMU emulation with your SD card backup..."
qemu-system-arm \
    -kernel "$KERNEL" \
    -dtb "$DTB" \
    -m 256 \
    -M versatilepb \
    -cpu arm1176 \
    -hda "$BACKUP_IMG" \
    -net nic \
    -net user,hostfwd=tcp::5022-:22 \
    -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw console=ttyAMA0" \
    -no-reboot \
    -display cocoa \
    -serial stdio

log "🏁 QEMU session ended."

log "💡 Tips for testing:"
log "   • The Pi should boot and apply all customizations"
log "   • Look for auto-login to happen"
log "   • Desktop environment should load"
log "   • GUI application should start automatically"
log "   • Press Ctrl+C in QEMU to exit"
