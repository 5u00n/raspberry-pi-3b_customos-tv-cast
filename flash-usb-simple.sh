#!/bin/bash

# Simple USB Flash Script - No complications!
# Downloads, extracts, and flashes complete Raspberry Pi OS

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[FLASH]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

log "🍓 Simple USB Flash - Complete Raspberry Pi OS"
log "=============================================="

# Check if image is downloaded
if [ ! -f ~/Downloads/raspios_lite_arm64.img.xz ]; then
    error "Raspberry Pi OS image not found. Please wait for download to complete."
fi

log "✅ Found Raspberry Pi OS image"

# Extract image
log "Extracting image..."
cd ~/Downloads
xz -d raspios_lite_arm64.img.xz
log "✅ Image extracted"

# Find USB drive
USB_DEVICE="/dev/disk4"  # Your 64GB USB drive
if [ ! -e "$USB_DEVICE" ]; then
    error "USB drive not found at $USB_DEVICE"
fi

log "✅ Found USB drive: $USB_DEVICE"

# Unmount USB drive
log "Unmounting USB drive..."
diskutil unmountDisk "$USB_DEVICE" 2>/dev/null || true
log "✅ USB drive unmounted"

# Flash image
log "Flashing Raspberry Pi OS to USB drive..."
log "This will take 3-5 minutes..."
sudo dd if=~/Downloads/raspios_lite_arm64.img of="${USB_DEVICE//disk/rdisk}" bs=1m status=progress

# Eject USB
log "Ejecting USB drive..."
sudo diskutil eject "$USB_DEVICE"
log "✅ USB drive ejected"

log "🎉 SUCCESS! Your USB drive is ready!"
log "====================================="
echo
info "What to do next:"
info "1. Insert USB drive into Raspberry Pi 3B"
info "2. Power on the Pi"
info "3. Wait 2-3 minutes for first boot"
info "4. Connect via SSH: ssh pi@raspberrypi.local"
info "5. Run: sudo apt update && sudo apt install -y python3-pyqt5 python3-pip"
info "6. Clone this repo and run INSTALL-ON-PI.sh"
echo
info "Default credentials:"
info "Username: pi"
info "Password: raspberry"
echo
log "🍓 Your USB drive is ready to boot!"
