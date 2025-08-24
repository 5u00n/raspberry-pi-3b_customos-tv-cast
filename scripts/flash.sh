#!/bin/bash

# Flash script for custom Raspberry Pi 3B OS
# Usage: ./flash.sh /dev/sdX

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if device argument is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: No device specified${NC}"
    echo "Usage: $0 /dev/sdX"
    echo "Example: $0 /dev/sdb"
    exit 1
fi

DEVICE="$1"
IMAGE_PATH="$(pwd)/output/raspberry-pi-os.img"

# Safety checks
if [ ! -f "$IMAGE_PATH" ]; then
    echo -e "${RED}Error: Image file not found at $IMAGE_PATH${NC}"
    echo "Please run ./scripts/build.sh first"
    exit 1
fi

if [ ! -b "$DEVICE" ]; then
    echo -e "${RED}Error: $DEVICE is not a block device${NC}"
    exit 1
fi

# Check if device is mounted
if mount | grep -q "$DEVICE"; then
    echo -e "${YELLOW}Warning: $DEVICE appears to be mounted${NC}"
    echo "Please unmount all partitions on this device first"
    exit 1
fi

# Confirm before proceeding
echo -e "${YELLOW}WARNING: This will completely erase $DEVICE${NC}"
echo "All data on this device will be lost!"
echo ""
echo "Device: $DEVICE"
echo "Image: $IMAGE_PATH"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Operation cancelled"
    exit 0
fi

# Get device size
DEVICE_SIZE=$(sudo blockdev --getsize64 "$DEVICE")
IMAGE_SIZE=$(stat -c%s "$IMAGE_PATH")

if [ "$IMAGE_SIZE" -gt "$DEVICE_SIZE" ]; then
    echo -e "${RED}Error: Image is larger than device${NC}"
    echo "Image size: $((IMAGE_SIZE / 1024 / 1024)) MB"
    echo "Device size: $((DEVICE_SIZE / 1024 / 1024)) MB"
    exit 1
fi

echo -e "${GREEN}Starting flash process...${NC}"
echo "Device: $DEVICE"
echo "Image: $IMAGE_PATH"
echo ""

# Flash the image
echo "Flashing image to device (this may take several minutes)..."
sudo dd if="$IMAGE_PATH" of="$DEVICE" bs=4M status=progress conv=fsync

# Verify the flash
echo ""
echo "Verifying flash..."
sudo dd if="$DEVICE" of="/tmp/verify.img" bs=4M count=$((IMAGE_SIZE / 4194304))

if cmp -s "$IMAGE_PATH" "/tmp/verify.img"; then
    echo -e "${GREEN}Flash verification successful!${NC}"
else
    echo -e "${RED}Flash verification failed!${NC}"
    exit 1
fi

# Cleanup
sudo rm -f "/tmp/verify.img"

echo ""
echo -e "${GREEN}Flash completed successfully!${NC}"
echo "You can now safely remove the SD card and insert it into your Raspberry Pi 3B"
echo ""
echo "Next steps:"
echo "1. Insert SD card into Pi 3B"
echo "2. Power on the Pi"
echo "3. Wait for first boot setup (5-10 minutes)"
echo "4. Connect to WiFi network"
echo "5. Access remote control at http://<pi-ip>:8080"
