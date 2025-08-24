#!/bin/bash

# Script to set up Git repository with the proper files

set -e

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

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Ask for GitHub username
read -p "Enter your GitHub username: " GITHUB_USERNAME

# Replace placeholder username in files
log "Updating GitHub username in files..."
find . -type f -name "*.md" -o -name "*.sh" | xargs sed -i '' "s|5u00n|$GITHUB_USERNAME|g" || warn "Failed to update some files"

# Initialize Git repository
log "Initializing Git repository..."
git init

# Create necessary directories if they don't exist
log "Ensuring required directories exist..."
mkdir -p overlays/etc/systemd/system
mkdir -p overlays/etc/network
mkdir -p overlays/usr/local/bin
mkdir -p overlays/home/pi
mkdir -p overlays/var/www
mkdir -p configs
mkdir -p scripts

# Add important files to Git
log "Adding files to Git..."
git add .gitignore
git add README.md
git add FINAL_INSTRUCTIONS.md
git add firstrun.sh
git add setup-from-github.sh
git add install.sh
git add fix-sd-card.sh
git add git-setup.sh
git add overlays/
git add configs/
git add scripts/

# Initial commit
log "Creating initial commit..."
git commit -m "Initial commit of Raspberry Pi 3B Custom OS"

# Set up remote
log "Setting up remote..."
git branch -M main
git remote add origin "https://github.com/$GITHUB_USERNAME/raspberry-pi-3b_customos-tv-cast.git"

# Instructions for pushing
log "✅ Git repository set up successfully!"
log "To push to GitHub, run:"
echo -e "${YELLOW}git push -u origin main${NC}"
log "Make sure you've created the repository at: https://github.com/$GITHUB_USERNAME/raspberry-pi-3b_customos-tv-cast"
