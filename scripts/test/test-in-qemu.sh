#!/bin/bash

# Enhanced QEMU test script for Raspberry Pi Custom OS
# This script provides multiple testing options

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default image
DEFAULT_IMAGE="output/raspberry-pi-os.img"

# Log function
log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if image exists
check_image() {
    local image="$1"
    if [[ ! -f "$image" ]]; then
        error "Image not found: $image"
    fi
    info "Using image: $image ($(du -h "$image" | cut -f1))"
}

# Test boot functionality
test_boot() {
    local image="$1"
    log "Testing basic boot functionality..."
    
    info "Starting QEMU boot test..."
    info "Press Ctrl+C to exit QEMU when done testing"
    echo
    
    qemu-system-arm \
        -M versatilepb \
        -cpu arm1176 \
        -m 256 \
        -kernel qemu_files/kernel-qemu-4.19.50-buster \
        -dtb qemu_files/versatile-pb-buster.dtb \
        -no-reboot \
        -serial stdio \
        -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw console=ttyAMA0" \
        -hda "$image" \
        -display cocoa \
        -net nic \
        -net user,hostfwd=tcp::8080-:80,hostfwd=tcp::2222-:22
}

# Test with GUI
test_gui() {
    local image="$1"
    log "Testing with GUI display..."
    
    info "Starting QEMU with GUI support..."
    info "This will open a graphical window"
    echo
    
    qemu-system-arm \
        -M versatilepb \
        -cpu arm1176 \
        -m 512 \
        -kernel qemu_files/kernel-qemu-4.19.50-buster \
        -dtb qemu_files/versatile-pb-buster.dtb \
        -no-reboot \
        -serial stdio \
        -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw console=ttyAMA0" \
        -hda "$image" \
        -display cocoa \
        -net nic \
        -net user,hostfwd=tcp::8080-:80,hostfwd=tcp::2222-:22 \
        -device usb-kbd \
        -device usb-mouse
}

# Test services verification
test_services() {
    local image="$1"
    log "Testing services verification..."
    
    info "This will boot and check if services are running"
    echo
    
    qemu-system-arm \
        -M versatilepb \
        -cpu arm1176 \
        -m 256 \
        -kernel qemu_files/kernel-qemu-4.19.50-buster \
        -dtb qemu_files/versatile-pb-buster.dtb \
        -no-reboot \
        -serial stdio \
        -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw console=ttyAMA0 init=/bin/bash -c 'mount -a; systemctl status airplay google-cast wifi-tools remote-control desktop-ui; sleep 30; poweroff'" \
        -hda "$image" \
        -display none \
        -net nic \
        -net user
}

# Usage function
usage() {
    echo "Usage: $0 [OPTIONS] [IMAGE]"
    echo ""
    echo "OPTIONS:"
    echo "  -b, --boot      Test basic boot (default)"
    echo "  -g, --gui       Test with GUI display"
    echo "  -s, --services  Test services verification"
    echo "  -h, --help      Show this help"
    echo ""
    echo "IMAGE:"
    echo "  Path to the image file (default: $DEFAULT_IMAGE)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Basic boot test"
    echo "  $0 -g                                 # GUI test"
    echo "  $0 -s output/customized-pi-os.img     # Services test with specific image"
}

# Main function
main() {
    local test_type="boot"
    local image="$DEFAULT_IMAGE"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -b|--boot)
                test_type="boot"
                shift
                ;;
            -g|--gui)
                test_type="gui"
                shift
                ;;
            -s|--services)
                test_type="services"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                error "Unknown option: $1"
                ;;
            *)
                image="$1"
                shift
                ;;
        esac
    done
    
    # Check dependencies
    if ! command -v qemu-system-arm &> /dev/null; then
        error "qemu-system-arm not found. Install with: brew install qemu"
    fi
    
    # Check files
    check_image "$image"
    
    if [[ ! -f "qemu_files/kernel-qemu-4.19.50-buster" ]]; then
        error "QEMU kernel not found: qemu_files/kernel-qemu-4.19.50-buster"
    fi
    
    if [[ ! -f "qemu_files/versatile-pb-buster.dtb" ]]; then
        error "QEMU device tree not found: qemu_files/versatile-pb-buster.dtb"
    fi
    
    # Run the selected test
    case $test_type in
        boot)
            test_boot "$image"
            ;;
        gui)
            test_gui "$image"
            ;;
        services)
            test_services "$image"
            ;;
    esac
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
