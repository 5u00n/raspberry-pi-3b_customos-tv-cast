#!/bin/bash

# Test script for custom Raspberry Pi 3B OS
# This script tests the build environment and components

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

log() {
    echo -e "${GREEN}[TEST]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

# Test 1: Check if required directories exist
test_directory_structure() {
    log "Testing directory structure..."
    
    required_dirs=("docs" "scripts" "configs" "packages" "overlays" "build" "output")
    
    for dir in "${required_dirs[@]}"; do
        if [ -d "$dir" ]; then
            success "Directory $dir exists"
        else
            error "Directory $dir missing"
        fi
    done
}

# Test 2: Check if required files exist
test_required_files() {
    log "Testing required files..."
    
    required_files=(
        "scripts/build.sh"
        "scripts/flash.sh"
        "scripts/setup.sh"
        "scripts/test.sh"
        "configs/config.txt"
        "configs/wpa_supplicant.conf"
        "packages/packages.txt"
        "overlays/usr/local/bin/remote-control-server"
        "overlays/usr/local/bin/wifi-tools-daemon"
        "overlays/var/www/templates/index.html"
        "build/Dockerfile"
        "README.md"
        "docs/BUILD.md"
        "docs/INSTALLATION.md"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            success "File $file exists"
        else
            error "File $file missing"
        fi
    done
}

# Test 3: Check script permissions
test_script_permissions() {
    log "Testing script permissions..."
    
    scripts=("scripts/build.sh" "scripts/flash.sh" "scripts/setup.sh" "scripts/test.sh")
    
    for script in "${scripts[@]}"; do
        if [ -x "$script" ]; then
            success "Script $script is executable"
        else
            error "Script $script is not executable"
        fi
    done
}

# Test 4: Check Docker availability
test_docker() {
    log "Testing Docker availability..."
    
    if command -v docker &> /dev/null; then
        if docker info &> /dev/null; then
            success "Docker is available and running"
        else
            error "Docker is installed but not running"
        fi
    else
        error "Docker is not installed"
    fi
}

# Test 5: Check Python dependencies
test_python_deps() {
    log "Testing Python dependencies..."
    
    if command -v python3 &> /dev/null; then
        success "Python3 is available"
        
        # Check if required modules can be imported
        if python3 -c "import flask" 2>/dev/null; then
            success "Flask module available"
        else
            warn "Flask module not available (will be installed during build)"
        fi
        
        if python3 -c "import flask_cors" 2>/dev/null; then
            success "Flask-CORS module available"
        else
            warn "Flask-CORS module not available (will be installed during build)"
        fi
    else
        error "Python3 is not available"
    fi
}

# Test 6: Check disk space
test_disk_space() {
    log "Testing available disk space..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        AVAILABLE_SPACE=$(df . | awk 'NR==2 {print $4}')
        REQUIRED_SPACE=20971520  # 20GB in KB
        
        if [ "$AVAILABLE_SPACE" -ge "$REQUIRED_SPACE" ]; then
            success "Sufficient disk space available ($((AVAILABLE_SPACE / 1024 / 1024)) GB)"
        else
            error "Insufficient disk space ($((AVAILABLE_SPACE / 1024 / 1024)) GB available, 20GB required)"
        fi
    else
        warn "Disk space check not available on $OSTYPE"
    fi
}

# Test 7: Check network connectivity
test_network() {
    log "Testing network connectivity..."
    
    if ping -c 1 8.8.8.8 &> /dev/null; then
        success "Network connectivity available"
    else
        error "No network connectivity"
    fi
}

# Test 8: Validate configuration files
test_config_files() {
    log "Testing configuration files..."
    
    # Test config.txt syntax
    if [ -f "configs/config.txt" ]; then
        if grep -q "arm_freq" "configs/config.txt"; then
            success "config.txt contains valid Raspberry Pi configuration"
        else
            error "config.txt appears to be invalid"
        fi
    fi
    
    # Test wpa_supplicant.conf syntax
    if [ -f "configs/wpa_supplicant.conf" ]; then
        if grep -q "network=" "configs/wpa_supplicant.conf"; then
            success "wpa_supplicant.conf contains valid WiFi configuration"
        else
            error "wpa_supplicant.conf appears to be invalid"
        fi
    fi
}

# Test 9: Check overlay structure
test_overlay_structure() {
    log "Testing overlay structure..."
    
    overlay_dirs=(
        "overlays/etc/systemd/system"
        "overlays/etc/network"
        "overlays/usr/local/bin"
        "overlays/var/www/templates"
    )
    
    for dir in "${overlay_dirs[@]}"; do
        if [ -d "$dir" ]; then
            success "Overlay directory $dir exists"
        else
            error "Overlay directory $dir missing"
        fi
    done
}

# Test 10: Validate HTML template
test_html_template() {
    log "Testing HTML template..."
    
    if [ -f "overlays/var/www/templates/index.html" ]; then
        if grep -q "<!DOCTYPE html>" "overlays/var/www/templates/index.html"; then
            success "HTML template is valid"
        else
            error "HTML template appears to be invalid"
        fi
        
        if grep -q "Raspberry Pi 3B" "overlays/var/www/templates/index.html"; then
            success "HTML template contains expected content"
        else
            error "HTML template missing expected content"
        fi
    else
        error "HTML template file not found"
    fi
}

# Main test function
main() {
    echo "=========================================="
    echo "Custom Raspberry Pi 3B OS - Build Test"
    echo "=========================================="
    echo ""
    
    # Run all tests
    test_directory_structure
    test_required_files
    test_script_permissions
    test_docker
    test_python_deps
    test_disk_space
    test_network
    test_config_files
    test_overlay_structure
    test_html_template
    
    # Print results
    echo ""
    echo "=========================================="
    echo "Test Results Summary"
    echo "=========================================="
    echo "Tests Passed: $TESTS_PASSED"
    echo "Tests Failed: $TESTS_FAILED"
    echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed! Your build environment is ready.${NC}"
        echo "You can now run: ./scripts/build.sh"
        exit 0
    else
        echo -e "${RED}Some tests failed. Please fix the issues before building.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
