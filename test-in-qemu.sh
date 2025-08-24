#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting QEMU with Raspberry Pi OS image...${NC}"

# Run QEMU with the Raspberry Pi OS image
qemu-system-arm \
    -M versatilepb \
    -cpu arm1176 \
    -m 256 \
    -kernel qemu_files/kernel-qemu-4.19.50-buster \
    -dtb qemu_files/versatile-pb-buster.dtb \
    -no-reboot \
    -serial stdio \
    -append "root=/dev/sda1 panic=1 rootfstype=vfat rw init=/bin/bash" \
    -hda output/raspberry-pi-os-fixed.img \
    -display cocoa \
    -net nic \
    -net user
