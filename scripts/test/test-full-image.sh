#!/bin/bash

# Test Full Customized Image on macOS using QEMU
# This script tests the SD card image with all customizations applied

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE_DIR="$(pwd)"
OUTPUT_DIR="$WORKSPACE_DIR/output"
SD_CARD_IMG="$OUTPUT_DIR/sd_card_backup.img"
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

# Check if we have a backup of the SD card
if [ ! -f "$SD_CARD_IMG" ]; then
    log "🔍 No SD card backup found. Creating one from your SD card..."
    
    # List available disks
    log "Available disks:"
    diskutil list
    
    # Ask for disk to backup
    echo ""
    read -p "Enter the disk identifier of your SD card (e.g., disk4): " DISK_ID
    
    # Confirm disk selection
    echo ""
    echo "You selected: $DISK_ID"
    read -p "Is this correct? (y/n): " CONFIRM
    
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        error "Operation cancelled by user"
    fi
    
    # Create backup of the SD card
    log "Creating backup of SD card..."
    sudo dd if="/dev/r$DISK_ID" of="$SD_CARD_IMG" bs=1m
    
    log "SD card backup created: $SD_CARD_IMG"
else
    log "✅ Found existing SD card backup: $SD_CARD_IMG"
fi

# Create kernel directory if it doesn't exist
mkdir -p "$KERNEL_DIR"

# Download kernel files if they don't exist
if [ ! -f "$KERNEL" ]; then
    log "🔍 Downloading QEMU kernel..."
    curl -L -o "$KERNEL" "https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-4.19.50-buster"
fi

if [ ! -f "$DTB" ]; then
    log "🔍 Downloading device tree blob..."
    curl -L -o "$DTB" "https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/versatile-pb-buster.dtb"
fi

# Check if files exist
if [ ! -f "$SD_CARD_IMG" ]; then
    error "SD card image not found: $SD_CARD_IMG"
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

# Start QEMU with the SD card image
log "🚀 Starting QEMU emulation with your customized SD card image..."
qemu-system-arm \
    -kernel "$KERNEL" \
    -dtb "$DTB" \
    -m 256 \
    -M versatilepb \
    -cpu arm1176 \
    -hda "$SD_CARD_IMG" \
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
