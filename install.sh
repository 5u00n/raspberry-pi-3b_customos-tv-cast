#!/bin/bash
# One-line installer for Raspberry Pi 3B Custom OS
# Usage: curl -L https://raw.githubusercontent.com/5u00n/my_rasp_OS/main/install.sh | sudo bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root. Try 'curl -L https://raw.githubusercontent.com/5u00n/my_rasp_OS/main/install.sh | sudo bash'"
fi

log "Downloading setup script from GitHub..."
curl -L -o /tmp/setup-from-github.sh https://raw.githubusercontent.com/5u00n/my_rasp_OS/main/setup-from-github.sh

log "Making script executable..."
chmod +x /tmp/setup-from-github.sh

log "Running setup script..."
/tmp/setup-from-github.sh

# The setup script will handle the rest, including cleanup
