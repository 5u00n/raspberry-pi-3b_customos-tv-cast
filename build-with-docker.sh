#!/bin/bash

# Build Custom Raspberry Pi 3B OS using Docker
# This approach works on macOS without requiring root privileges

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

log "🍓 Building Custom Raspberry Pi 3B OS with Docker"
log "================================================="

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker Desktop from https://www.docker.com/products/docker-desktop"
fi

if ! docker info &> /dev/null; then
    error "Docker is not running. Please start Docker Desktop and try again."
fi

# Create a working directory
WORK_DIR="custom-os-build"
mkdir -p "$WORK_DIR"

log "Creating Docker-based build environment..."

# Create Dockerfile for building
cat > "$WORK_DIR/Dockerfile" << 'EOF'
FROM ubuntu:20.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    debootstrap \
    qemu-user-static \
    kpartx \
    parted \
    dosfstools \
    zip \
    unzip \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /build

# Copy pi-gen
COPY pi-gen /build/pi-gen

# Set up build environment
RUN cd /build/pi-gen && \
    chmod +x build.sh && \
    chmod +x stage*/00-*/*.sh

# Build the custom OS
CMD ["/build/pi-gen/build.sh"]
EOF

# Copy pi-gen to working directory
log "Copying pi-gen to Docker build context..."
cp -r pi-gen "$WORK_DIR/"

# Build the Docker image
log "Building Docker image for pi-gen..."
docker build -t custom-pi-gen "$WORK_DIR/"

# Run the build in Docker
log "Starting build process in Docker container..."
log "This will take 30-60 minutes depending on your system..."

# Create a volume for the build output
docker volume create pi-gen-output

# Run the build
docker run --rm \
    -v pi-gen-output:/build/pi-gen/deploy \
    -v pi-gen-output:/build/pi-gen/work \
    custom-pi-gen

# Copy the built image to local directory
log "Copying built image from Docker volume..."
docker run --rm \
    -v pi-gen-output:/output \
    -v "$(pwd)":/local \
    ubuntu:20.04 \
    cp -r /output/* /local/

# Check if build was successful
if [ -d "deploy" ]; then
    IMAGE_FILE=$(find deploy -name "*.img" | head -1)
    if [ -n "$IMAGE_FILE" ]; then
        log "🎉 Build completed successfully!"
        log "Custom OS image created: $IMAGE_FILE"
        
        # Show image info
        IMAGE_SIZE=$(du -h "$IMAGE_FILE" | cut -f1)
        log "Image size: $IMAGE_SIZE"
        
        # Create a compressed version
        log "Creating compressed image..."
        gzip -c "$IMAGE_FILE" > "${IMAGE_FILE}.gz"
        COMPRESSED_SIZE=$(du -h "${IMAGE_FILE}.gz" | cut -f1)
        log "Compressed image: ${IMAGE_FILE}.gz ($COMPRESSED_SIZE)"
        
        log ""
        log "✅ Your custom Raspberry Pi 3B OS is ready!"
        log "=========================================="
        log "Image file: $IMAGE_FILE"
        log "Compressed: ${IMAGE_FILE}.gz"
        log ""
        log "To test in QEMU:"
        log "  ./test-custom-os.sh"
        log ""
        log "Features included:"
        log "  • AirPlay Receiver"
        log "  • Google Cast"
        log "  • WiFi Security Tools"
        log "  • Remote Control Web Interface"
        log "  • Custom GUI Dashboard"
        log "  • File Sharing (Samba)"
        log "  • Auto-login and auto-start"
    else
        error "No image file found in deploy directory"
    fi
else
    error "Build failed. Deploy directory not found"
fi

# Clean up
log "Cleaning up..."
rm -rf "$WORK_DIR"
docker volume rm pi-gen-output

log "Build process completed!"


