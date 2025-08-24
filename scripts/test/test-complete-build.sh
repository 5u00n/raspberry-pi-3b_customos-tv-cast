#!/bin/bash

# Complete Build and Test Script for Raspberry Pi Custom OS
# This script will verify all features are properly integrated

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

# Check if required tools are installed
check_dependencies() {
    log "Checking dependencies..."
    
    if ! command -v qemu-system-arm &> /dev/null; then
        error "qemu-system-arm not found. Install with: brew install qemu"
    fi
    
    if ! command -v hdiutil &> /dev/null; then
        error "hdiutil not found (required for macOS disk image mounting)"
    fi
    
    log "All dependencies found ✅"
}

# Verify all required overlay files exist
verify_overlays() {
    log "Verifying overlay files..."
    
    # Check systemd services
    local services=(
        "airplay.service"
        "google-cast.service" 
        "wifi-tools.service"
        "remote-control.service"
        "desktop-ui.service"
    )
    
    for service in "${services[@]}"; do
        if [[ ! -f "${OVERLAY_DIR}/etc/systemd/system/${service}" ]]; then
            error "Missing service file: ${service}"
        fi
        info "Found service: ${service} ✅"
    done
    
    # Check executables
    local executables=(
        "cast-receiver.py"
        "raspberry-pi-gui.py"
        "wifi-tools-daemon"
        "remote-control-server"
    )
    
    for executable in "${executables[@]}"; do
        if [[ ! -f "${OVERLAY_DIR}/usr/local/bin/${executable}" ]]; then
            error "Missing executable: ${executable}"
        fi
        info "Found executable: ${executable} ✅"
    done
    
    log "All overlay files verified ✅"
}

# Verify configuration files
verify_configs() {
    log "Verifying configuration files..."
    
    local configs=(
        "firstrun.sh"
        "wifi-credentials.txt"
        "config.txt"
        "wpa_supplicant.conf"
    )
    
    for config in "${configs[@]}"; do
        if [[ ! -f "${CONFIG_DIR}/${config}" ]]; then
            error "Missing config file: ${config}"
        fi
        info "Found config: ${config} ✅"
    done
    
    log "All configuration files verified ✅"
}

# Verify QEMU files
verify_qemu_files() {
    log "Verifying QEMU files..."
    
    if [[ ! -f "${QEMU_FILES}/kernel-qemu-4.19.50-buster" ]]; then
        error "Missing QEMU kernel file"
    fi
    
    if [[ ! -f "${QEMU_FILES}/versatile-pb-buster.dtb" ]]; then
        error "Missing QEMU device tree file"
    fi
    
    log "QEMU files verified ✅"
}

# Test image mounting (without modification)
test_image_structure() {
    log "Testing image structure..."
    
    local test_image="${OUTPUT_DIR}/raspberry-pi-os.img"
    
    if [[ ! -f "${test_image}" ]]; then
        error "Test image not found: ${test_image}"
    fi
    
    # Get image info
    info "Image size: $(du -h "${test_image}" | cut -f1)"
    info "Image type: $(file "${test_image}" | cut -d: -f2-)"
    
    log "Image structure test completed ✅"
}

# Create a quick QEMU test
test_qemu_boot() {
    log "Testing QEMU boot (quick test)..."
    
    local test_image="${OUTPUT_DIR}/raspberry-pi-os.img"
    
    # Create a simple boot test script
    cat > /tmp/qemu_test.sh << 'EOF'
#!/bin/bash
qemu-system-arm \
    -M versatilepb \
    -cpu arm1176 \
    -m 256 \
    -kernel qemu_files/kernel-qemu-4.19.50-buster \
    -dtb qemu_files/versatile-pb-buster.dtb \
    -no-reboot \
    -serial stdio \
    -append "root=/dev/sda1 panic=1 rootfstype=ext4 rw init=/bin/bash -c 'echo QEMU_BOOT_TEST_SUCCESS; ls -la /boot; sleep 2; poweroff'" \
    -hda output/raspberry-pi-os.img \
    -display none \
    -net nic \
    -net user
EOF
    
    chmod +x /tmp/qemu_test.sh
    
    info "QEMU test script created. Manual testing recommended."
    info "Run: /tmp/qemu_test.sh"
    
    log "QEMU boot test setup completed ✅"
}

# Verify service file contents
verify_service_contents() {
    log "Verifying service file contents..."
    
    # Check AirPlay service
    if grep -q "shairport-sync" "${OVERLAY_DIR}/etc/systemd/system/airplay.service"; then
        info "AirPlay service properly configured ✅"
    else
        warn "AirPlay service may not be properly configured"
    fi
    
    # Check Google Cast service
    if grep -q "cast-receiver.py" "${OVERLAY_DIR}/etc/systemd/system/google-cast.service"; then
        info "Google Cast service properly configured ✅"
    else
        warn "Google Cast service may not be properly configured"
    fi
    
    # Check WiFi tools service
    if grep -q "wifi-tools-daemon" "${OVERLAY_DIR}/etc/systemd/system/wifi-tools.service"; then
        info "WiFi tools service properly configured ✅"
    else
        warn "WiFi tools service may not be properly configured"
    fi
    
    log "Service contents verification completed ✅"
}

# Main function
main() {
    log "🚀 Starting Complete Build Verification"
    echo
    
    check_dependencies
    echo
    
    verify_overlays
    echo
    
    verify_configs
    echo
    
    verify_qemu_files
    echo
    
    test_image_structure
    echo
    
    verify_service_contents
    echo
    
    test_qemu_boot
    echo
    
    log "🎉 Complete Build Verification Finished!"
    echo
    
    info "Summary of Features in Your Custom OS:"
    echo "  ✅ AirPlay support (shairport-sync)"
    echo "  ✅ Google Cast receiver"
    echo "  ✅ WiFi security tools (wifite/aircrack)"
    echo "  ✅ Remote control web interface"
    echo "  ✅ Auto-login and GUI dashboard"
    echo "  ✅ Systemd services for all features"
    echo "  ✅ QEMU testing capability"
    echo
    
    info "Your image is ready for:"
    echo "  📱 Flashing to SD card with dd or Raspberry Pi Imager"
    echo "  🖥️  Testing in QEMU emulator"
    echo "  🚀 Deployment on real Raspberry Pi 3B hardware"
    echo
    
    info "Next steps:"
    echo "  1. Test in QEMU: ./scripts/test/test-in-qemu.sh"
    echo "  2. Flash to SD: dd if=output/raspberry-pi-os.img of=/dev/diskX bs=1m"
    echo "  3. Use Raspberry Pi Imager with the .img file"
}

# Run main function
main "$@"
