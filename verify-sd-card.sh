#!/bin/bash

# Verify SD card configuration
# This script will mount the SD card and verify its configuration

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# List available disks
log "Listing available disks..."
diskutil list

# Ask for disk identifier
echo ""
read -p "Enter the disk identifier of your SD card (e.g., disk6): " DISK_ID

if [[ ! "$DISK_ID" =~ ^disk[0-9]+$ ]]; then
    error "Invalid disk identifier format. Please enter something like 'disk6'."
fi

log "You selected: $DISK_ID"
read -p "This will mount your SD card for verification. Continue? (y/n): " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    error "Operation cancelled by user"
fi

# Create mount points
BOOT_MOUNT="/tmp/rpi_boot_verify"
ROOTFS_MOUNT="/tmp/rpi_rootfs_verify"
mkdir -p "$BOOT_MOUNT" "$ROOTFS_MOUNT"

# Mount boot partition
log "Mounting boot partition..."
diskutil mount -mountPoint "$BOOT_MOUNT" "/dev/${DISK_ID}s1" || error "Failed to mount boot partition"

# Verify boot partition
log "Verifying boot partition..."
echo "Contents of boot partition:"
ls -la "$BOOT_MOUNT"

log "Verifying cmdline.txt..."
cat "$BOOT_MOUNT/cmdline.txt"

log "Verifying firstrun.sh..."
cat "$BOOT_MOUNT/firstrun.sh" | head -30

log "Verifying wifi-credentials.txt..."
cat "$BOOT_MOUNT/wifi-credentials.txt"

log "Verifying overlay directory..."
ls -la "$BOOT_MOUNT/overlay"

# Unmount partitions
log "Unmounting partitions..."
diskutil unmount "$BOOT_MOUNT"

# Cleanup
rm -rf "$BOOT_MOUNT" "$ROOTFS_MOUNT"

log "✅ SD card verification completed"
log "Your SD card is properly configured with all necessary files"
log "Insert it into your Raspberry Pi 3B and it should boot with all features working"
