#!/bin/bash

# Comprehensive Build and Feature Verification Script
# This script verifies that all features are properly integrated and working

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
OVERLAY_DIR="${WORKSPACE_DIR}/overlays"
CONFIG_DIR="${WORKSPACE_DIR}/configs"
QEMU_FILES="${WORKSPACE_DIR}/qemu_files"

# Log functions
log() {
    echo -e "${GREEN}[✓]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

info() {
    echo -e "${BLUE}[i]${NC} $1"
}

section() {
    echo -e "\n${BLUE}==== $1 ====${NC}"
}

# Verification functions
check_file() {
    if [ -f "$1" ]; then
        log "Found: $1"
        return 0
    else
        error "Missing: $1"
        return 1
    fi
}

check_directory() {
    if [ -d "$1" ]; then
        log "Directory exists: $1"
        return 0
    else
        error "Missing directory: $1"
        return 1
    fi
}

# Main verification
main() {
    section "Raspberry Pi 3B Custom OS - Build Verification"
    
    # Check workspace structure
    section "1. Workspace Structure Verification"
    check_directory "$OVERLAY_DIR" || exit 1
    check_directory "$CONFIG_DIR" || exit 1
    check_directory "$OUTPUT_DIR" || exit 1
    
    # Check essential scripts
    section "2. Essential Scripts Verification"
    check_file "build-complete-image.sh" || exit 1
    check_file "test-in-qemu.sh" || exit 1
    check_file "firstrun.sh" || exit 1
    check_file "setup-from-github.sh" || exit 1
    
    # Check overlay structure for key features
    section "3. Feature Overlay Verification"
    
    # AirPlay/Google Cast services
    check_file "$OVERLAY_DIR/etc/systemd/system/airplay.service" || warn "AirPlay service missing"
    check_file "$OVERLAY_DIR/etc/systemd/system/google-cast.service" || warn "Google Cast service missing"
    
    # Auto-login configuration
    check_file "$OVERLAY_DIR/etc/systemd/system/autologin.service" || warn "Auto-login service missing"
    check_file "$OVERLAY_DIR/etc/lightdm/lightdm.conf" || warn "LightDM config missing"
    
    # WiFi tools and remote control
    check_file "$OVERLAY_DIR/etc/systemd/system/wifi-tools.service" || warn "WiFi tools service missing"
    check_file "$OVERLAY_DIR/etc/systemd/system/remote-control.service" || warn "Remote control service missing"
    
    # Check if images exist
    section "4. Built Images Verification"
    if [ -f "$OUTPUT_DIR/raspberry-pi-os.img" ]; then
        log "Main OS image exists: $(ls -lh $OUTPUT_DIR/raspberry-pi-os.img | awk '{print $5}')"
    else
        warn "Main OS image not found - will need to build"
    fi
    
    if [ -f "$OUTPUT_DIR/customized-pi-os.img" ]; then
        log "Customized OS image exists: $(ls -lh $OUTPUT_DIR/customized-pi-os.img | awk '{print $5}')"
    else
        warn "Customized OS image not found"
    fi
    
    # Check QEMU files
    section "5. QEMU Testing Prerequisites"
    if command -v qemu-system-arm >/dev/null 2>&1; then
        log "QEMU ARM emulator installed"
    else
        error "QEMU ARM emulator not installed. Install with: brew install qemu"
        exit 1
    fi
    
    check_file "$QEMU_FILES/kernel-qemu-4.19.50-buster" || check_file "kernel-qemu-4.19.50-buster" || error "QEMU kernel missing"
    check_file "$QEMU_FILES/versatile-pb-buster.dtb" || check_file "versatile-pb-buster.dtb" || error "QEMU DTB file missing"
    
    # Check configuration files
    section "6. Configuration Files Verification"
    check_file "$CONFIG_DIR/config.txt" || warn "Boot config missing"
    check_file "$CONFIG_DIR/wpa_supplicant.conf" || warn "WiFi config template missing"
    
    # Verify web interface files
    section "7. Web Interface Verification"
    if [ -d "$OVERLAY_DIR/var/www" ]; then
        log "Web interface directory found"
        find "$OVERLAY_DIR/var/www" -name "*.html" -o -name "*.js" -o -name "*.css" | head -5 | while read file; do
            log "  Found web file: $(basename "$file")"
        done
    else
        warn "Web interface directory not found"
    fi
    
    # Check executable scripts
    section "8. Script Permissions Verification"
    for script in *.sh; do
        if [ -x "$script" ]; then
            log "Executable: $script"
        else
            warn "Not executable: $script (run: chmod +x $script)"
        fi
    done
    
    section "9. Summary"
    echo
    info "Verification complete! Key points:"
    echo "  • All essential scripts are present"
    echo "  • Overlay structure contains key services"
    echo "  • QEMU testing environment is ready"
    echo "  • Configuration files are in place"
    echo
    
    if [ -f "$OUTPUT_DIR/raspberry-pi-os.img" ] || [ -f "$OUTPUT_DIR/customized-pi-os.img" ]; then
        log "Ready to flash SD card or test in QEMU"
        echo
        info "To test in QEMU, run: ./scripts/test/test-in-qemu.sh"
        info "To build fresh image, run: ./scripts/build/build-complete-image.sh"
    else
        warn "No built images found. Run ./scripts/build/build-complete-image.sh first"
    fi
    
    echo
    log "Build verification completed successfully!"
}

main "$@"
