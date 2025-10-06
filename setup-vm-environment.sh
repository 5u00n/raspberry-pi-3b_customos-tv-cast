#!/bin/bash

# Automated VM Environment Setup for Apple Silicon Mac
# This script helps you set up everything needed to build the custom Raspberry Pi OS

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[SETUP]${NC} $1"
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

step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

log "🍓 VM Environment Setup for Raspberry Pi OS Build"
log "================================================="
echo

# Detect architecture
ARCH=$(uname -m)
info "Detected architecture: $ARCH"

if [ "$ARCH" = "arm64" ]; then
    info "✅ Apple Silicon Mac detected"
    VM_SOFTWARE="UTM"
elif [ "$ARCH" = "x86_64" ]; then
    info "✅ Intel Mac detected"
    VM_SOFTWARE="VirtualBox or UTM"
else
    error "Unknown architecture: $ARCH"
fi

echo

# Check if Homebrew is installed
step "1/4: Checking Homebrew..."
if command -v brew &> /dev/null; then
    log "✅ Homebrew is installed"
    BREW_INSTALLED=true
else
    warn "Homebrew is not installed"
    BREW_INSTALLED=false
    echo
    info "Homebrew is recommended for easy installation of UTM"
    read -p "Would you like to install Homebrew? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add to PATH for Apple Silicon
        if [ "$ARCH" = "arm64" ]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        
        BREW_INSTALLED=true
        log "✅ Homebrew installed"
    fi
fi

echo

# Check if VM software is installed
step "2/4: Checking VM software..."

UTM_INSTALLED=false
if command -v utm &> /dev/null || [ -d "/Applications/UTM.app" ]; then
    log "✅ UTM is already installed"
    UTM_INSTALLED=true
fi

VBOX_INSTALLED=false
if command -v virtualbox &> /dev/null || [ -d "/Applications/VirtualBox.app" ]; then
    log "✅ VirtualBox is already installed"
    VBOX_INSTALLED=true
fi

if [ "$UTM_INSTALLED" = false ] && [ "$VBOX_INSTALLED" = false ]; then
    warn "No VM software found"
    echo
    
    if [ "$ARCH" = "arm64" ]; then
        info "For Apple Silicon, UTM is recommended"
        
        if [ "$BREW_INSTALLED" = true ]; then
            read -p "Install UTM via Homebrew? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                info "Installing UTM..."
                brew install --cask utm
                log "✅ UTM installed"
                UTM_INSTALLED=true
            fi
        else
            info "Please download UTM manually from: https://mac.getutm.app/"
            read -p "Press Enter when you have installed UTM..."
        fi
    else
        info "For Intel Mac, you can use VirtualBox or UTM"
        info "VirtualBox: https://www.virtualbox.org/wiki/Downloads"
        info "UTM: https://mac.getutm.app/"
        read -p "Press Enter when you have installed VM software..."
    fi
fi

echo

# Download Ubuntu ISO
step "3/4: Ubuntu ISO..."

if [ "$ARCH" = "arm64" ]; then
    ISO_URL="https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.3-live-server-arm64.iso"
    ISO_NAME="ubuntu-22.04-live-server-arm64.iso"
else
    ISO_URL="https://releases.ubuntu.com/22.04/ubuntu-22.04.3-desktop-amd64.iso"
    ISO_NAME="ubuntu-22.04-desktop-amd64.iso"
fi

ISO_PATH="$HOME/Downloads/$ISO_NAME"

if [ -f "$ISO_PATH" ]; then
    log "✅ Ubuntu ISO already downloaded: $ISO_PATH"
else
    warn "Ubuntu ISO not found"
    info "ISO will be downloaded to: $ISO_PATH"
    info "Size: ~2-4 GB (this will take 10-30 minutes)"
    echo
    read -p "Download Ubuntu ISO now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Downloading Ubuntu ISO..."
        info "This may take a while..."
        curl -# -L -o "$ISO_PATH" "$ISO_URL"
        log "✅ Ubuntu ISO downloaded"
    else
        info "You can download it later from: $ISO_URL"
    fi
fi

echo

# Create VM instructions
step "4/4: Creating setup instructions..."

cat > VM-NEXT-STEPS.txt << EOF
🖥️ VM Setup Complete! Next Steps:
==================================

✅ VM Software: $VM_SOFTWARE
✅ Ubuntu ISO: $ISO_PATH

NEXT STEPS:
===========

1. Open UTM (or VirtualBox)

2. Create New VM:
   - Name: RaspberryPi-Builder
   - Type: Linux / Ubuntu
   - Memory: 4096 MB (4 GB) or more
   - CPU: 4 cores (or 2 minimum)
   - Disk: 40 GB
   - ISO: $ISO_PATH

3. Install Ubuntu:
   - Username: builder
   - Password: (your choice)
   - Enable OpenSSH server

4. In Ubuntu VM, run:
   
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y git docker.io
   sudo systemctl start docker
   sudo usermod -aG docker \$USER
   
   # Log out and log back in
   
   git clone https://github.com/YOUR_USERNAME/raspberry-pi-3b_customos-tv-cast.git
   cd raspberry-pi-3b_customos-tv-cast
   ./build-custom-os.sh

5. Wait 30-60 minutes for build

6. Transfer image to Mac (see VM-SETUP-GUIDE.md)

7. Flash to SD card (see FLASH-INSTRUCTIONS.txt)

DETAILED GUIDES:
================

- START-HERE-MAC.md - Complete step-by-step guide
- VM-SETUP-GUIDE.md - Detailed VM setup instructions
- BUILD-OPTIONS.md - All available build methods

QUICK ALTERNATIVE:
==================

If this seems too complex, use the Quick Install method:
1. Flash regular Raspberry Pi OS to SD card
2. Boot your Pi
3. Run ./INSTALL-ON-PI.sh
4. Same result, much faster!

Happy building! 🍓
EOF

log "✅ Instructions created: VM-NEXT-STEPS.txt"

echo
echo "================================================="
log "🎉 VM Environment Setup Complete!"
echo "================================================="
echo
info "Next steps:"
info "  1. Read VM-NEXT-STEPS.txt"
info "  2. Read START-HERE-MAC.md for detailed guide"
info "  3. Create and configure VM"
info "  4. Build your custom OS!"
echo
info "Or use Quick Install method (no VM needed) - see BUILD-OPTIONS.md"
echo

# Open files for user
info "Opening guide files..."
open VM-NEXT-STEPS.txt
open START-HERE-MAC.md

log "🍓 Ready to build your custom Raspberry Pi OS!"

