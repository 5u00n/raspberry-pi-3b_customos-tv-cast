#!/bin/bash

# Test Custom Raspberry Pi 3B OS in QEMU
# This script tests your custom OS in a virtual machine

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log "🍓 Testing Custom Raspberry Pi 3B OS in QEMU"
log "==========================================="

# Check if QEMU is installed
if ! command -v qemu-system-arm &> /dev/null; then
    error "QEMU is not installed. Please install it with: brew install qemu"
fi

# Find the custom OS image
IMAGE_FILE=""
if [ -f "custom-raspberry-pi-os.img" ]; then
    IMAGE_FILE="custom-raspberry-pi-os.img"
elif [ -d "pi-gen/deploy" ]; then
    IMAGE_FILE=$(find pi-gen/deploy -name "*.img" | head -1)
fi

if [ -z "$IMAGE_FILE" ] || [ ! -f "$IMAGE_FILE" ]; then
    error "Custom OS image not found. Please create it first with: ./create-working-test.sh"
fi

log "Using image: $IMAGE_FILE"

# Check image size
IMAGE_SIZE=$(du -h "$IMAGE_FILE" | cut -f1)
log "Image size: $IMAGE_SIZE"

# Create a copy for testing
TEST_IMAGE="test-custom-os.img"
log "Creating test image copy..."
cp "$IMAGE_FILE" "$TEST_IMAGE"

log "🍓 Starting Custom Raspberry Pi 3B OS in QEMU"
log "============================================="
log "This will show you the actual desktop interface!"
log ""
log "Access methods:"
log "  • Web Dashboard: http://localhost:8083"
log "  • SSH: ssh pi@localhost -p 2224"
log "  • Direct access: Monitor and keyboard connected"
log ""
log "Features to test:"
log "  • AirPlay Receiver: Look for 'Raspberry Pi 3B Custom OS' in AirPlay"
log "  • Google Cast: Look for 'Raspberry Pi 3B Custom OS' in Google Cast"
log "  • Web Dashboard: Open http://localhost:8083 in your browser"
log "  • Custom GUI: Full-screen dashboard should start automatically"
log "  • WiFi Tools: Background network monitoring"
log "  • File Sharing: Access via \\\\localhost\\pi"
log ""
log "Press Ctrl+A then X to exit QEMU"
log ""

# Run QEMU with the custom OS
qemu-system-arm \
    -M versatilepb \
    -cpu arm1176 \
    -m 256 \
    -hda "$TEST_IMAGE" \
    -netdev user,id=net0,hostfwd=tcp::2224-:22,hostfwd=tcp::8083-:8080 \
    -device rtl8139,netdev=net0 \
    -nographic

log "QEMU session ended"

# Clean up test image
if [ -f "$TEST_IMAGE" ]; then
    log "Cleaning up test image..."
    rm -f "$TEST_IMAGE"
fi

log "Test completed!"
