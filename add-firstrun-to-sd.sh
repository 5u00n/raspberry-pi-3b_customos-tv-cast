#!/bin/bash

# Add firstrun.sh to SD card and modify cmdline.txt
# This script will mount the SD card, add firstrun.sh, and modify cmdline.txt

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
read -p "This will modify your SD card. Continue? (y/n): " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    error "Operation cancelled by user"
fi

# Create mount points
BOOT_MOUNT="/tmp/rpi_boot_add"
mkdir -p "$BOOT_MOUNT"

# Mount boot partition
log "Mounting boot partition..."
diskutil mount -mountPoint "$BOOT_MOUNT" "/dev/${DISK_ID}s1" || error "Failed to mount boot partition"

# Copy firstrun.sh to boot partition
log "Copying firstrun.sh to boot partition..."
cp firstrun.sh "$BOOT_MOUNT/"
chmod +x "$BOOT_MOUNT/firstrun.sh"

# Modify cmdline.txt
log "Modifying cmdline.txt..."
CMDLINE_PATH="$BOOT_MOUNT/cmdline.txt"
ORIGINAL_CMDLINE=$(cat "$CMDLINE_PATH")

# Remove any existing init= parameters
CLEANED_CMDLINE=$(echo "$ORIGINAL_CMDLINE" | sed 's/ init=[^ ]*//')

# Add our init parameter
NEW_CMDLINE="$CLEANED_CMDLINE init=/bin/bash -c \"mount -t proc proc /proc; mount -t sysfs sys /sys; mount /boot; if [ -f /boot/firstrun.sh ]; then source /boot/firstrun.sh; else exec /sbin/init; fi\""

echo "$NEW_CMDLINE" > "$CMDLINE_PATH"

log "New cmdline.txt content:"
cat "$CMDLINE_PATH"

# Unmount partitions
log "Unmounting partitions..."
diskutil unmount "$BOOT_MOUNT"

# Cleanup
rm -rf "$BOOT_MOUNT"

log "✅ firstrun.sh added to SD card and cmdline.txt modified"
log "Insert it into your Raspberry Pi 3B and it should boot with all features working"
