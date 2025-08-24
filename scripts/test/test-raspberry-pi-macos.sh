#!/bin/bash

# macOS QEMU Testing Script for Raspberry Pi 3B OS
# This script tests your custom OS image on MacBook

echo "🍎 Testing Raspberry Pi 3B OS on macOS with QEMU..."
echo "=================================================="

# Check if QEMU is installed
if ! command -v qemu-system-arm &> /dev/null; then
    echo "❌ QEMU not found. Please install it first:"
    echo "   brew install qemu"
    exit 1
fi

# Check if kernel files exist
if [ ! -f "kernel-qemu-4.19.50-buster" ] || [ ! -f "versatile-pb-buster.dtb" ]; then
    echo "❌ Kernel files missing. Downloading them..."
    curl -L -o kernel-qemu-4.19.50-buster https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-4.19.50-buster
    curl -L -o versatile-pb-buster.dtb https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/versatile-pb-buster.dtb
fi

# Check if OS image exists
if [ ! -f "output/raspberry-pi-os.img" ]; then
    echo "❌ OS image not found. Please build it first:"
    echo "   ./scripts/build.sh"
    exit 1
fi

echo "✅ All required files found!"
echo "🚀 Starting QEMU emulation..."

# macOS-compatible QEMU command
# Note: macOS doesn't support -display gtk, so we use -display cocoa or -nographic
qemu-system-arm \
  -M versatilepb \
  -cpu arm1176 \
  -m 256 \
  -hda output/raspberry-pi-os.img \
  -kernel kernel-qemu-4.19.50-buster \
  -dtb versatile-pb-buster.dtb \
  -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw console=ttyAMA0" \
  -net nic \
  -net user \
  -vga std \
  -display cocoa \
  -serial stdio

echo "🏁 QEMU session ended."
echo ""
echo "💡 Tips for testing:"
echo "   • The Pi will boot automatically"
echo "   • Look for auto-login to happen"
echo "   • Desktop environment should load"
echo "   • GUI application should start automatically"
echo "   • Press Ctrl+C in QEMU to exit"
