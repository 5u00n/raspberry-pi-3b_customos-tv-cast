#!/bin/bash
#
# Quick Dependency Checker for Pi-Gen Build
# Run this before building to verify all tools are available
#

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🔍 Checking Pi-Gen Build Dependencies              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

MISSING=0
OPTIONAL_MISSING=0

# Function to check required command
check_required() {
    local cmd=$1
    local package=$2
    
    if command -v $cmd &> /dev/null; then
        echo -e "${GREEN}✅${NC} $cmd - OK"
        return 0
    else
        echo -e "${RED}❌${NC} $cmd - MISSING (install: $package)"
        MISSING=$((MISSING + 1))
        return 1
    fi
}

# Function to check optional command
check_optional() {
    local cmd=$1
    local package=$2
    
    if command -v $cmd &> /dev/null; then
        echo -e "${GREEN}✅${NC} $cmd - OK"
        return 0
    else
        echo -e "${YELLOW}⚠️${NC}  $cmd - Optional (install: $package)"
        OPTIONAL_MISSING=$((OPTIONAL_MISSING + 1))
        return 1
    fi
}

echo "📦 Required Build Tools:"
echo "------------------------"
check_required "git" "git"
check_required "curl" "curl"
check_required "debootstrap" "debootstrap"
check_required "qemu-arm-static" "qemu-user-static"
check_required "xz" "xz-utils"
check_required "pigz" "pigz"
check_required "kpartx" "kpartx"

echo ""
echo "📚 Archive Tools:"
echo "-----------------"
if check_required "bsdtar" "libarchive-tools"; then
    :
else
    # Check for tar as fallback
    if command -v tar &> /dev/null; then
        echo -e "${YELLOW}  ↳${NC} 'tar' available as fallback"
    fi
fi

echo ""
echo "⚡ Compression Tools:"
echo "--------------------"
check_required "gzip" "gzip"
check_required "zip" "zip"
check_required "unzip" "unzip"

# Check for parallel xz
if check_optional "pixz" "pixz"; then
    :
elif check_optional "pxz" "pxz"; then
    :
else
    echo -e "${YELLOW}  ↳${NC} Will use standard 'xz' (slower but works)"
fi

echo ""
echo "🔧 System Tools:"
echo "----------------"
check_required "parted" "parted"
check_required "fdisk" "fdisk"
check_required "mkfs.vfat" "dosfstools"

echo ""
echo "🐍 Python:"
echo "----------"
check_required "python3" "python3"
check_required "pip3" "python3-pip"

echo ""
echo "════════════════════════════════════════════════════════"
echo ""

# Summary
if [ $MISSING -eq 0 ]; then
    echo -e "${GREEN}✅ All required dependencies are installed!${NC}"
    echo ""
    echo -e "${BLUE}You can now run:${NC}"
    echo -e "  ${GREEN}./BUILD-DEBIAN-AMD64.sh${NC}"
    echo ""
    
    if [ $OPTIONAL_MISSING -gt 0 ]; then
        echo -e "${YELLOW}Note: $OPTIONAL_MISSING optional tool(s) missing${NC}"
        echo -e "${YELLOW}The build will work but may be slower.${NC}"
        echo ""
        echo "To install optional tools:"
        echo "  sudo apt-get install pixz"
    fi
    
    exit 0
else
    echo -e "${RED}❌ $MISSING required dependencies are missing!${NC}"
    echo ""
    echo -e "${YELLOW}To install all dependencies, run:${NC}"
    echo ""
    echo "  sudo apt-get update"
    echo "  sudo apt-get install -y \\"
    echo "    git curl debootstrap qemu-user-static xz-utils pigz \\"
    echo "    kpartx libarchive-tools gzip zip unzip parted fdisk \\"
    echo "    dosfstools python3 python3-pip"
    echo ""
    echo -e "${BLUE}Or simply run the build script - it will install them:${NC}"
    echo -e "  ${GREEN}./BUILD-DEBIAN-AMD64.sh${NC}"
    echo ""
    exit 1
fi

