#!/bin/bash

# Build and Run Docker Container for Raspberry Pi OS Build
# This script builds the Docker image and runs the container to build the Raspberry Pi OS

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker first."
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    error "Docker daemon is not running. Please start Docker first."
fi

# Build Docker image
log "Building Docker image..."
docker build -t raspberry-pi-os-builder .

# Create output directory if it doesn't exist
mkdir -p output

# Run Docker container
log "Running Docker container to build and test Raspberry Pi OS..."
docker run --rm --privileged \
    -v "$(pwd):/workspace" \
    -v "$(pwd)/output:/workspace/output" \
    -v "$(pwd)/overlays:/workspace/overlays" \
    -v "$(pwd)/configs:/workspace/configs" \
    -v "$(pwd)/packages:/workspace/packages" \
    -v "$(pwd)/scripts:/workspace/scripts" \
    raspberry-pi-os-builder

log "✅ Build and test complete!"
log "The customized image is available at: output/raspberry-pi-os-custom.img"
log "You can flash this image to an SD card using:"
log "  sudo dd if=output/raspberry-pi-os-custom.img of=/dev/rdiskX bs=1m"
log "  (Replace diskX with your SD card device)"
