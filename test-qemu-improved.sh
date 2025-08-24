#!/bin/bash

# Enhanced QEMU Test Script for Raspberry Pi Custom OS
# This script provides comprehensive testing options with proper file handling

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories and files
WORKSPACE_DIR="$(pwd)"
OUTPUT_DIR="${WORKSPACE_DIR}/output"
QEMU_DIR="${WORKSPACE_DIR}/qemu_files"
TEMP_DIR="${OUTPUT_DIR}/qemu_temp"

# Default files
DEFAULT_IMAGE="$OUTPUT_DIR/raspberry-pi-os.img"
KERNEL="$QEMU_DIR/kernel-qemu-4.19.50-buster"
DTB="$QEMU_DIR/versatile-pb-buster.dtb"

# Log functions
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

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Usage information
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -i, --image <path>     Specify custom image path"
    echo "  -q, --quick           Quick boot test (5 seconds)"
    echo "  -f, --full            Full interactive test"
    echo "  -n, --network         Enable network testing"
    echo "  -h, --help            Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                    # Quick boot test with default image"
    echo "  $0 -f                 # Full interactive test"
    echo "  $0 -i custom.img -n   # Network test with custom image"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check QEMU
    if ! command -v qemu-system-arm >/dev/null 2>&1; then
        error "QEMU ARM emulator not found. Install with: brew install qemu"
    fi
    
    # Check kernel files
    if [[ ! -f "$KERNEL" ]]; then
        error "QEMU kernel not found: $KERNEL"
    fi
    
    if [[ ! -f "$DTB" ]]; then
        error "QEMU DTB file not found: $DTB"
    fi
    
    log "Prerequisites check passed"
}

# Prepare test environment
prepare_test() {
    local image="$1"
    
    log "Preparing test environment..."
    
    # Create temp directory
    mkdir -p "$TEMP_DIR"
    
    # Create a copy of the image to avoid file locking issues
    local test_image="$TEMP_DIR/test-$(basename "$image")"
    
    if [[ ! -f "$test_image" ]] || [[ "$image" -nt "$test_image" ]]; then
        info "Creating test copy of image..."
        cp "$image" "$test_image"
    fi
    
    echo "$test_image"
}

# Quick boot test
quick_test() {
    local image="$1"
    
    log "Starting quick boot test..."
    info "This will boot the image and exit after 10 seconds"
    echo
    
    # Use timeout command if available (may not be on macOS)
    local timeout_cmd=""
    if command -v gtimeout >/dev/null 2>&1; then
        timeout_cmd="gtimeout 10"
    elif command -v timeout >/dev/null 2>&1; then
        timeout_cmd="timeout 10"
    fi
    
    $timeout_cmd qemu-system-arm \
        -M versatilepb \
        -cpu arm1176 \
        -m 256 \
        -kernel "$KERNEL" \
        -dtb "$DTB" \
        -drive format=raw,file="$image" \
        -append "root=/dev/sda2 rootfstype=ext4 rw panic=1" \
        -netdev user,id=net0 \
        -device rtl8139,netdev=net0 \
        -nographic || true
    
    log "Quick test completed"
}

# Full interactive test
full_test() {
    local image="$1"
    
    log "Starting full interactive test..."
    info "QEMU will start in graphics mode"
    info "Press Ctrl+Alt+G to release mouse/keyboard"
    info "Close QEMU window or press Ctrl+C to exit"
    echo
    
    qemu-system-arm \
        -M versatilepb \
        -cpu arm1176 \
        -m 256 \
        -kernel "$KERNEL" \
        -dtb "$DTB" \
        -drive format=raw,file="$image" \
        -append "root=/dev/sda2 rootfstype=ext4 rw" \
        -netdev user,id=net0 \
        -device rtl8139,netdev=net0
}

# Network test
network_test() {
    local image="$1"
    
    log "Starting network test..."
    info "QEMU will start with port forwarding:"
    info "  - SSH: localhost:2222 -> pi:22"
    info "  - Web: localhost:8080 -> pi:80"
    info "  - Cast: localhost:8009 -> pi:8009"
    echo
    
    qemu-system-arm \
        -M versatilepb \
        -cpu arm1176 \
        -m 256 \
        -kernel "$KERNEL" \
        -dtb "$DTB" \
        -drive format=raw,file="$image" \
        -append "root=/dev/sda2 rootfstype=ext4 rw" \
        -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80,hostfwd=tcp::8009-:8009 \
        -device rtl8139,netdev=net0 \
        -nographic
}

# Check image
check_image() {
    local image="$1"
    
    if [[ ! -f "$image" ]]; then
        error "Image not found: $image"
    fi
    
    local size=$(du -h "$image" | cut -f1)
    info "Using image: $image ($size)"
    
    # Verify it's a valid image
    if ! file "$image" | grep -q "data\|filesystem\|boot"; then
        warn "Image format might not be recognized"
    fi
}

# Cleanup function
cleanup() {
    log "Cleaning up..."
    # Kill any remaining QEMU processes
    pkill -f qemu-system-arm || true
}

# Main function
main() {
    local image="$DEFAULT_IMAGE"
    local test_type="quick"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--image)
                image="$2"
                shift 2
                ;;
            -q|--quick)
                test_type="quick"
                shift
                ;;
            -f|--full)
                test_type="full"
                shift
                ;;
            -n|--network)
                test_type="network"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    log "Starting QEMU test for Raspberry Pi Custom OS"
    
    # Run checks
    check_prerequisites
    check_image "$image"
    
    # Prepare test environment
    local test_image
    test_image=$(prepare_test "$image")
    
    # Run the specified test
    case $test_type in
        quick)
            quick_test "$test_image"
            ;;
        full)
            full_test "$test_image"
            ;;
        network)
            network_test "$test_image"
            ;;
        *)
            error "Unknown test type: $test_type"
            ;;
    esac
    
    log "QEMU test completed successfully"
}

# Check if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
