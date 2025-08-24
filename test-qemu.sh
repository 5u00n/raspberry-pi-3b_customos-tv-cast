#!/bin/bash

# Test QEMU Script for Custom Image
# Usage: ./test-qemu.sh [image_file]

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE_DIR="$(pwd)"
KERNEL_DIR="$WORKSPACE_DIR/qemu_kernel"
KERNEL="$KERNEL_DIR/kernel-qemu-4.19.50-buster"
DTB="$KERNEL_DIR/versatile-pb-buster.dtb"

# Default image file
IMAGE_FILE="$WORKSPACE_DIR/build/base-os.img"

# Override with command line argument if provided
if [ $# -eq 1 ]; then
    IMAGE_FILE="$1"
fi

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
if [ ! -f "$IMAGE_FILE" ]; then
    error "Image file not found: $IMAGE_FILE"
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

# Start QEMU with the image
log "🚀 Starting QEMU emulation..."
qemu-system-arm \
    -kernel "$KERNEL" \
    -dtb "$DTB" \
    -m 256 \
    -M versatilepb \
    -cpu arm1176 \
    -hda "$IMAGE_FILE" \
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
