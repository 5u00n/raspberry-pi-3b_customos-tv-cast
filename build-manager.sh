#!/bin/bash

# Build Verification and Rebuild Script
# This script will check if a fresh build is needed and rebuild if necessary

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
WORKSPACE_DIR="$(pwd)"
OUTPUT_DIR="${WORKSPACE_DIR}/output"
BUILD_DIR="${WORKSPACE_DIR}/build"

# Image files
OUTPUT_IMAGE="${OUTPUT_DIR}/raspberry-pi-os.img"
LATEST_IMAGE="${OUTPUT_DIR}/raspberry-pi-os-latest.img"

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

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if build is needed
check_build_needed() {
    log "Checking if rebuild is needed..."
    
    local rebuild_needed=false
    
    # Check if output image exists
    if [[ ! -f "$OUTPUT_IMAGE" ]]; then
        info "Output image not found, rebuild needed"
        rebuild_needed=true
    fi
    
    # Check if overlay files are newer than image
    if [[ -f "$OUTPUT_IMAGE" ]]; then
        local newest_overlay=$(find overlays/ -type f -newer "$OUTPUT_IMAGE" | head -1)
        if [[ -n "$newest_overlay" ]]; then
            info "Overlay files modified since last build: $newest_overlay"
            rebuild_needed=true
        fi
        
        local newest_config=$(find configs/ -type f -newer "$OUTPUT_IMAGE" | head -1)
        if [[ -n "$newest_config" ]]; then
            info "Config files modified since last build: $newest_config"
            rebuild_needed=true
        fi
    fi
    
    if [[ "$rebuild_needed" = true ]]; then
        warn "Rebuild is needed"
        return 0
    else
        log "Current build is up to date ✅"
        return 1
    fi
}

# Build fresh image
build_fresh_image() {
    log "Starting fresh image build..."
    
    # Create backup of current image if it exists
    if [[ -f "$OUTPUT_IMAGE" ]]; then
        info "Backing up current image..."
        cp "$OUTPUT_IMAGE" "${OUTPUT_IMAGE}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Run the complete build script
    if [[ -f "build-complete-image.sh" ]]; then
        log "Running complete build script..."
        ./build-complete-image.sh
    else
        error "build-complete-image.sh not found"
    fi
    
    # Verify the new build
    if [[ -f "$OUTPUT_IMAGE" ]]; then
        info "Build completed successfully"
        info "New image size: $(du -h "$OUTPUT_IMAGE" | cut -f1)"
        
        # Create a 'latest' copy
        cp "$OUTPUT_IMAGE" "$LATEST_IMAGE"
        log "Latest image copy created ✅"
    else
        error "Build failed - no output image created"
    fi
}

# Quick verification of image content
verify_image_content() {
    local image="$1"
    
    log "Verifying image content..."
    
    if [[ ! -f "$image" ]]; then
        error "Image not found: $image"
    fi
    
    # Check image format
    local file_info=$(file "$image")
    if [[ "$file_info" =~ "DOS/MBR boot sector" ]]; then
        info "Image format verified: Valid disk image ✅"
    else
        warn "Unexpected image format: $file_info"
    fi
    
    # Try to mount and check boot partition (macOS specific)
    log "Attempting to verify boot partition content..."
    
    local temp_mount="/tmp/pi_image_test_$$"
    local device=""
    
    # Attach the image
    device=$(hdiutil attach -nomount "$image" 2>/dev/null | head -n 1 | awk '{print $1}' || true)
    
    if [[ -n "$device" ]]; then
        info "Image attached as: $device"
        
        # Try to mount boot partition
        local boot_part="${device}s1"
        if diskutil mount -mountPoint "$temp_mount" "$boot_part" 2>/dev/null; then
            info "Boot partition mounted successfully"
            
            # Check for our files
            if [[ -f "${temp_mount}/overlay" ]] || [[ -d "${temp_mount}/overlay" ]]; then
                info "Overlay directory found in boot partition ✅"
            else
                warn "Overlay directory not found in boot partition"
            fi
            
            if [[ -f "${temp_mount}/firstrun.sh" ]]; then
                info "First run script found in boot partition ✅"
            else
                warn "First run script not found in boot partition"
            fi
            
            # Cleanup
            diskutil unmount "$temp_mount" 2>/dev/null || true
        else
            warn "Could not mount boot partition for verification"
        fi
        
        # Detach the image
        hdiutil detach "$device" 2>/dev/null || true
    else
        warn "Could not attach image for verification"
    fi
    
    log "Image content verification completed"
}

# Test the image in QEMU
quick_qemu_test() {
    local image="$1"
    
    log "Running quick QEMU test..."
    
    info "Testing basic QEMU boot (will timeout in 30 seconds)..."
    
    # Use a background process with timeout
    (
        sleep 30
        pkill -f "qemu-system-arm.*$image" 2>/dev/null || true
    ) &
    local timeout_pid=$!
    
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
        -display none \
        -net nic \
        -net user 2>/dev/null || true
    
    # Kill the timeout process
    kill $timeout_pid 2>/dev/null || true
    
    info "QEMU test completed"
}

# Main menu
show_menu() {
    echo
    echo "🔧 Raspberry Pi Custom OS - Build Manager"
    echo "=========================================="
    echo
    echo "1) Check if rebuild is needed"
    echo "2) Force rebuild"
    echo "3) Verify current image"
    echo "4) Quick QEMU test"
    echo "5) Complete verification"
    echo "6) Exit"
    echo
}

# Main function
main() {
    if [[ $# -eq 0 ]]; then
        # Interactive mode
        while true; do
            show_menu
            read -p "Select option (1-6): " choice
            
            case $choice in
                1)
                    if check_build_needed; then
                        read -p "Rebuild needed. Proceed? (y/N): " proceed
                        if [[ "$proceed" =~ ^[Yy]$ ]]; then
                            build_fresh_image
                        fi
                    fi
                    ;;
                2)
                    read -p "Force rebuild? This will overwrite current image (y/N): " proceed
                    if [[ "$proceed" =~ ^[Yy]$ ]]; then
                        build_fresh_image
                    fi
                    ;;
                3)
                    verify_image_content "$OUTPUT_IMAGE"
                    ;;
                4)
                    quick_qemu_test "$OUTPUT_IMAGE"
                    ;;
                5)
                    ./test-complete-build.sh
                    ;;
                6)
                    log "Goodbye!"
                    exit 0
                    ;;
                *)
                    error "Invalid option"
                    ;;
            esac
            
            echo
            read -p "Press Enter to continue..."
        done
    else
        # Command line mode
        case "$1" in
            check)
                check_build_needed && build_fresh_image
                ;;
            build)
                build_fresh_image
                ;;
            verify)
                verify_image_content "$OUTPUT_IMAGE"
                ;;
            test)
                quick_qemu_test "$OUTPUT_IMAGE"
                ;;
            complete)
                ./test-complete-build.sh
                ;;
            *)
                echo "Usage: $0 [check|build|verify|test|complete]"
                echo "  check    - Check if rebuild needed and rebuild if so"
                echo "  build    - Force rebuild"
                echo "  verify   - Verify current image"
                echo "  test     - Quick QEMU test"
                echo "  complete - Run complete verification"
                echo "  (no args) - Interactive mode"
                ;;
        esac
    fi
}

# Run main function
main "$@"
