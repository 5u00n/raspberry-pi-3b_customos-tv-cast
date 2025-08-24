#!/bin/bash

# Test the SD card in QEMU
# This script will create a backup of the SD card and test it in QEMU

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

# Create directories
log "Creating directories..."
mkdir -p qemu_files output

# Download QEMU kernel files if not exists
if [ ! -f "qemu_files/kernel-qemu-4.19.50-buster" ]; then
    log "Downloading QEMU kernel files..."
    curl -L -o "qemu_files/kernel-qemu-4.19.50-buster" "https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-4.19.50-buster"
    curl -L -o "qemu_files/versatile-pb-buster.dtb" "https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/versatile-pb-buster.dtb"
fi

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
read -p "This will create a backup of your SD card for testing. Continue? (y/n): " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    error "Operation cancelled by user"
fi

# Create backup of the SD card (first 2GB only for speed)
log "Creating backup of SD card (first 2GB only)..."
dd if="/dev/$DISK_ID" of="output/sd-card-backup.img" bs=1m count=2000

# Test the backup in QEMU
log "Testing the backup in QEMU..."
qemu-system-arm \
    -M versatilepb \
    -cpu arm1176 \
    -m 256 \
    -kernel "qemu_files/kernel-qemu-4.19.50-buster" \
    -dtb "qemu_files/versatile-pb-buster.dtb" \
    -no-reboot \
    -serial stdio \
    -append "root=/dev/sda1 panic=1 rootfstype=vfat rw init=/bin/bash -c \"mount -t proc proc /proc; mount -t sysfs sys /sys; ls -la /boot; cat /boot/cmdline.txt; cat /boot/firstrun.sh | head -20; echo 'QEMU test successful!'; sleep 30; poweroff\"" \
    -hda "output/sd-card-backup.img" \
    -display cocoa \
    -net nic \
    -net user

log "✅ QEMU test completed"
