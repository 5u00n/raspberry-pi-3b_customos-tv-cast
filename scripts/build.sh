#!/bin/bash

# Custom Raspberry Pi 3B OS Build Script
# This script builds a complete custom OS image

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BUILD_DIR="$(pwd)/build"
OUTPUT_DIR="$(pwd)/output"
WORKSPACE_DIR="$(pwd)"
PI_OS_VERSION="2023-02-22"
PI_OS_URL="https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2023-02-22/2023-02-21-raspios-bullseye-armhf-lite.img.xz"

# Logging
LOG_FILE="$BUILD_DIR/build.log"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if running on supported OS
    if [[ "$OSTYPE" != "linux-gnu"* && "$OSTYPE" != "darwin"* ]]; then
        error "Unsupported operating system: $OSTYPE"
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running. Please start Docker first."
    fi
    
    # Check available disk space (need at least 20GB)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        AVAILABLE_SPACE=$(df . | awk 'NR==2 {print $4}')
        if [ "$AVAILABLE_SPACE" -lt 20971520 ]; then
            error "Insufficient disk space. Need at least 20GB available."
        fi
    fi
    
    log "Prerequisites check passed!"
}

# Create build environment
setup_build_env() {
    log "Setting up build environment..."
    
    # Create directories
    mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"
    
    # Create Dockerfile for build environment
    cat > "$BUILD_DIR/Dockerfile" << 'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    build-essential \
    bc \
    libncurses5-dev \
    libssl-dev \
    libelf-dev \
    bison \
    flex \
    libfdt-dev \
    device-tree-compiler \
    python3 \
    python3-pip \
    qemu-user-static \
    binfmt-support \
    parted \
    dosfstools \
    mtools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
EOF
    
    log "Build environment setup complete!"
}

# Download base Raspberry Pi OS
download_base_os() {
    log "Downloading base Raspberry Pi OS..."
    
    if [ ! -f "$BUILD_DIR/base-os.img.xz" ]; then
        log "Downloading from: $PI_OS_URL"
        curl -L -o "$BUILD_DIR/base-os.img.xz" "$PI_OS_URL"
    else
        log "Base OS already downloaded, skipping..."
    fi
    
    # Extract image
    if [ ! -f "$BUILD_DIR/base-os.img" ]; then
        log "Extracting base OS image..."
        xz -d "$BUILD_DIR/base-os.img.xz"
    fi
    
    log "Base OS download complete!"
}

# Build custom kernel
build_kernel() {
    log "Building custom kernel..."
    
    # This is a placeholder - in a real implementation, we would:
    # 1. Download kernel source
    # 2. Apply custom patches
    # 3. Configure for Pi 3B
    # 4. Compile kernel and modules
    
    log "Kernel build complete! (placeholder)"
}

# Create filesystem overlay
create_overlay() {
    log "Creating filesystem overlay..."
    
    # Create overlay directory structure
    mkdir -p "$WORKSPACE_DIR/overlays/etc/systemd/system"
    mkdir -p "$WORKSPACE_DIR/overlays/etc/systemd/system/getty@tty1.service.d"
    mkdir -p "$WORKSPACE_DIR/overlays/etc/network"
    mkdir -p "$WORKSPACE_DIR/overlays/usr/local/bin"
    mkdir -p "$WORKSPACE_DIR/overlays/var/www"
    mkdir -p "$WORKSPACE_DIR/overlays/home/pi"
    mkdir -p "$WORKSPACE_DIR/overlays/etc/lightdm"
    
    # Make sure all our scripts are executable
    if [ -d "$WORKSPACE_DIR/overlays/usr/local/bin" ]; then
        find "$WORKSPACE_DIR/overlays/usr/local/bin" -type f -name "*.sh" -exec chmod +x {} \;
        find "$WORKSPACE_DIR/overlays/usr/local/bin" -type f -name "*.py" -exec chmod +x {} \;
    fi
    
    # Create auto-login configuration
    cat > "$WORKSPACE_DIR/overlays/etc/systemd/system/getty@tty1.service.d/autologin.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM
Type=idle
Restart=always
RestartSec=1
EOF

    # Create LightDM auto-login configuration
    cat > "$WORKSPACE_DIR/overlays/etc/lightdm/lightdm.conf" << 'EOF'
[SeatDefaults]
autologin-user=pi
autologin-user-timeout=0
autologin-session=openbox
user-session=openbox
autologin-guest=false
EOF

    # Create .bashrc for auto-start
    cat > "$WORKSPACE_DIR/overlays/home/pi/.bashrc" << 'EOF'
# .bashrc for pi user - Auto-start GUI

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Auto-start GUI if this is an interactive login
if [[ $- == *i* ]] && [[ -n "$DISPLAY" ]]; then
    echo "🍓 Auto-starting Raspberry Pi GUI..."
    
    # Start GUI in background
    if [ -f "/usr/local/bin/raspberry-pi-gui.py" ]; then
        echo "✅ Starting GUI application..."
        nohup python3 /usr/local/bin/raspberry-pi-gui.py > /var/log/gui-auto.log 2>&1 &
        echo "🍓 GUI started with PID: $!"
    else
        echo "⚠️ GUI script not found, starting terminal dashboard..."
        nohup python3 /usr/local/bin/terminal-dashboard.py > /var/log/terminal-auto.log 2>&1 &
        echo "🍓 Terminal dashboard started with PID: $!"
    fi
fi

# Set display environment
export DISPLAY=:0
export XAUTHORITY=/home/pi/.Xauthority
EOF

    # Create systemd services
    cat > "$WORKSPACE_DIR/overlays/etc/systemd/system/airplay.service" << 'EOF'
[Unit]
Description=AirPlay Receiver Service
After=network.target sound.target
Wants=network.target

[Service]
Type=simple
User=pi
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
WorkingDirectory=/home/pi
ExecStart=/usr/bin/shairport-sync -a "Raspberry Pi 3B"
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    cat > "$WORKSPACE_DIR/overlays/etc/systemd/system/google-cast.service" << 'EOF'
[Unit]
Description=Google Cast Receiver Service
After=network.target sound.target
Wants=network.target

[Service]
Type=simple
User=pi
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
WorkingDirectory=/home/pi
ExecStartPre=/bin/bash -c 'if ! pgrep -f "chromecast-daemon\|cast-receiver" > /dev/null; then echo "Starting Google Cast service"; fi'
ExecStart=/usr/bin/python3 /usr/local/bin/cast-receiver.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    cat > "$WORKSPACE_DIR/overlays/etc/systemd/system/wifi-tools.service" << 'EOF'
[Unit]
Description=WiFi Security Tools Daemon
After=network.target
Wants=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi
ExecStart=/usr/bin/python3 /usr/local/bin/wifi-tools-daemon.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    cat > "$WORKSPACE_DIR/overlays/etc/systemd/system/remote-control.service" << 'EOF'
[Unit]
Description=Remote Control Web Interface
After=network.target
Wants=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi
ExecStart=/usr/bin/python3 /usr/local/bin/remote-control-server
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    cat > "$WORKSPACE_DIR/overlays/etc/systemd/system/desktop-ui.service" << 'EOF'
[Unit]
Description=Desktop GUI Application Service
After=graphical.target network.target
Wants=graphical.target

[Service]
Type=simple
User=pi
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
WorkingDirectory=/home/pi
ExecStart=/usr/local/bin/start-desktop-gui.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical.target
EOF

    cat > "$WORKSPACE_DIR/overlays/etc/systemd/system/autologin.service" << 'EOF'
[Unit]
Description=Force Auto-Login and Start All Services
After=graphical.target
Wants=graphical.target

[Service]
Type=oneshot
User=pi
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
WorkingDirectory=/home/pi
ExecStart=/usr/local/bin/force-autologin.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical.target
EOF

    cat > "$WORKSPACE_DIR/overlays/etc/systemd/system/console-autologin.service" << 'EOF'
[Unit]
Description=Console Auto-Login Service
After=getty@tty1.service
Wants=getty@tty1.service

[Service]
Type=oneshot
User=pi
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
WorkingDirectory=/home/pi
ExecStart=/usr/local/bin/console-autologin.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=getty.target
EOF

    cat > "$WORKSPACE_DIR/overlays/etc/systemd/system/raspberry-pi-startup.service" << 'EOF'
[Unit]
Description=Raspberry Pi 3B Complete Startup Service
After=graphical.target network.target
Wants=graphical.target network.target

[Service]
Type=simple
User=pi
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
WorkingDirectory=/home/pi
ExecStart=/usr/local/bin/complete-startup.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical.target
EOF

    log "Filesystem overlay created!"
}

# Build final image
build_final_image() {
    log "Building final OS image with all customizations..."
    
    # Copy base image to output directory
    cp "$BUILD_DIR/base-os.img" "$OUTPUT_DIR/raspberry-pi-os.img"
    
    # Create a temporary directory for mounting
    MOUNT_DIR="$BUILD_DIR/mnt"
    mkdir -p "$MOUNT_DIR/boot" "$MOUNT_DIR/rootfs"
    
    # Find the start sector of each partition
    BOOT_START=$(fdisk -l "$OUTPUT_DIR/raspberry-pi-os.img" | grep "W95 FAT32" | awk '{print $2}')
    ROOTFS_START=$(fdisk -l "$OUTPUT_DIR/raspberry-pi-os.img" | grep "Linux$" | awk '{print $2}')
    
    if [ -z "$BOOT_START" ] || [ -z "$ROOTFS_START" ]; then
        error "Failed to find partition start sectors"
    fi
    
    log "Boot partition starts at sector $BOOT_START"
    log "Root filesystem starts at sector $ROOTFS_START"
    
    # Calculate offsets in bytes
    BOOT_OFFSET=$((BOOT_START * 512))
    ROOTFS_OFFSET=$((ROOTFS_START * 512))
    
    # Mount the image partitions
    log "Mounting image partitions..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS approach - create a device and mount it
        DEVICE=$(hdiutil attach -nomount "$OUTPUT_DIR/raspberry-pi-os.img" | head -n 1 | cut -d ' ' -f 1)
        mount -t msdos "${DEVICE}s1" "$MOUNT_DIR/boot"
        mount -t ext4 "${DEVICE}s2" "$MOUNT_DIR/rootfs"
    else
        # Linux approach - use loop devices
        LOOP_DEVICE=$(losetup -f --show "$OUTPUT_DIR/raspberry-pi-os.img")
        mount -o offset=$BOOT_OFFSET "$LOOP_DEVICE" "$MOUNT_DIR/boot"
        mount -o offset=$ROOTFS_OFFSET "$LOOP_DEVICE" "$MOUNT_DIR/rootfs"
    fi
    
    # Copy overlay files to the image
    log "Applying overlay files to image..."
    rsync -av "$WORKSPACE_DIR/overlays/" "$MOUNT_DIR/rootfs/"
    
    # Copy config files to boot partition
    if [ -d "$WORKSPACE_DIR/configs" ]; then
        log "Copying configuration files to boot partition..."
        rsync -av "$WORKSPACE_DIR/configs/" "$MOUNT_DIR/boot/"
    fi
    
    # Copy packages list
    if [ -f "$WORKSPACE_DIR/packages/packages.txt" ]; then
        log "Copying packages list to boot partition..."
        mkdir -p "$MOUNT_DIR/boot" && cp "$WORKSPACE_DIR/packages/packages.txt" "$MOUNT_DIR/boot/"
    fi
    
    # Copy setup script
    if [ -f "$WORKSPACE_DIR/scripts/setup.sh" ]; then
        log "Copying setup script to boot partition..."
        cp "$WORKSPACE_DIR/scripts/setup.sh" "$MOUNT_DIR/boot/" && chmod +x "$MOUNT_DIR/boot/setup.sh"
        
        # Create systemd service to run setup script on first boot
        mkdir -p "$MOUNT_DIR/rootfs/etc/systemd/system"
        cat > "$MOUNT_DIR/rootfs/etc/systemd/system/setup.service" << 'EOF'
[Unit]
Description=First Boot Setup
After=network.target

[Service]
Type=oneshot
ExecStart=/boot/setup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
        
        # Enable the service
        mkdir -p "$MOUNT_DIR/rootfs/etc/systemd/system/multi-user.target.wants"
        ln -sf "/etc/systemd/system/setup.service" "$MOUNT_DIR/rootfs/etc/systemd/system/multi-user.target.wants/setup.service"
    fi
    
    # Create wifi-credentials.txt in boot partition
    log "Creating WiFi credentials file..."
    cat > "$MOUNT_DIR/boot/wifi-credentials.txt" << 'EOF'
# WiFi credentials for auto-connection
WIFI_SSID_1="connection"
WIFI_PASSWORD_1="12qw34er"
WIFI_PRIORITY_1=1

WIFI_SSID_2="Nomita"
WIFI_PASSWORD_2="200019981996"
WIFI_PRIORITY_2=2
EOF
    
    # Configure auto-login
    log "Configuring auto-login..."
    mkdir -p "$MOUNT_DIR/rootfs/etc/systemd/system/getty@tty1.service.d"
    cat > "$MOUNT_DIR/rootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM
Type=idle
Restart=always
RestartSec=1
EOF
    
    # Make scripts executable
    log "Making scripts executable..."
    find "$MOUNT_DIR/rootfs/usr/local/bin" -type f -name "*.sh" -exec chmod +x {} \;
    find "$MOUNT_DIR/rootfs/usr/local/bin" -type f -name "*.py" -exec chmod +x {} \;
    
    # Set default target to graphical.target
    log "Setting default target to graphical.target..."
    ln -sf "/lib/systemd/system/graphical.target" "$MOUNT_DIR/rootfs/etc/systemd/system/default.target"
    
    # Enable all systemd services in the overlay
    log "Enabling systemd services..."
    for service_file in $(find "$WORKSPACE_DIR/overlays/etc/systemd/system" -name "*.service"); do
        service_name=$(basename "$service_file")
        log "Enabling service: $service_name"
        
        # Create symlink in /etc/systemd/system/multi-user.target.wants/
        mkdir -p "$MOUNT_DIR/rootfs/etc/systemd/system/multi-user.target.wants"
        ln -sf "/etc/systemd/system/$service_name" "$MOUNT_DIR/rootfs/etc/systemd/system/multi-user.target.wants/$service_name"
        
        # Create symlink in /etc/systemd/system/graphical.target.wants/ for GUI services
        if [[ "$service_name" == *"desktop"* || "$service_name" == *"autologin"* || "$service_name" == *"startup"* ]]; then
            mkdir -p "$MOUNT_DIR/rootfs/etc/systemd/system/graphical.target.wants"
            ln -sf "/etc/systemd/system/$service_name" "$MOUNT_DIR/rootfs/etc/systemd/system/graphical.target.wants/$service_name"
        fi
    done
    
    # Create rc.local file for first boot
    log "Creating rc.local file..."
    cat > "$MOUNT_DIR/rootfs/etc/rc.local" << 'EOF'
#!/bin/bash

# RC Local for Raspberry Pi 3B
# This script runs on every boot

LOG_FILE="/var/log/rc-local.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🍓 $1" | tee -a "$LOG_FILE"
}

log "Starting Raspberry Pi 3B configuration..."

# Check if setup is already complete
if [ ! -f "/etc/setup-complete" ]; then
    log "First boot detected, running setup..."
    
    # Wait for system to be ready
    sleep 15
    
    # Run first boot setup script if available
    if [ -f "/usr/local/bin/first-boot-setup.sh" ]; then
        log "Executing first-boot setup script..."
        chmod +x /usr/local/bin/first-boot-setup.sh
        /usr/local/bin/first-boot-setup.sh
    else
        log "First-boot setup script not found, running basic configuration..."
        
        # Configure auto-login
        log "Configuring auto-login..."
        mkdir -p /etc/systemd/system/getty@tty1.service.d/
        cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'EOT'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM
Type=idle
EOT
        
        # Configure desktop auto-login
        log "Configuring desktop auto-login..."
        mkdir -p /etc/lightdm
        cat > /etc/lightdm/lightdm.conf << 'EOT'
[SeatDefaults]
autologin-user=pi
autologin-user-timeout=0
autologin-session=openbox
user-session=openbox
autologin-guest=false
EOT
        
        # Set default target to graphical
        log "Setting default target to graphical..."
        systemctl set-default graphical.target
        
        # Mark setup as complete
        log "Marking setup as complete..."
        echo "$(date): Basic setup completed via rc.local" > /etc/setup-complete
        
        # Reboot to apply changes
        log "Rebooting to apply changes..."
        sleep 5
        reboot
    fi
else
    log "Setup already completed, ensuring services are running..."
    
    # Start desktop GUI service if not running
    if ! systemctl is-active --quiet desktop-ui.service; then
        log "Starting desktop GUI service..."
        systemctl start desktop-ui.service
    fi
    
    # Check and start other services
    services=("airplay.service" "google-cast.service" "wifi-tools.service" "remote-control.service")
    for service in "${services[@]}"; do
        if ! systemctl is-active --quiet "$service"; then
            log "Starting $service..."
            systemctl start "$service"
        fi
    done
fi

log "RC local configuration complete"
exit 0
EOF

    # Make rc.local executable
    chmod +x "$MOUNT_DIR/rootfs/etc/rc.local"
    
    # Sync and unmount
    log "Syncing and unmounting..."
    sync
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS unmount
        umount "$MOUNT_DIR/boot"
        umount "$MOUNT_DIR/rootfs"
        hdiutil detach "$DEVICE"
    else
        # Linux unmount
        umount "$MOUNT_DIR/boot"
        umount "$MOUNT_DIR/rootfs"
        losetup -d "$LOOP_DEVICE"
    fi
    
    # Clean up
    rm -rf "$MOUNT_DIR"
    
    # Create a compressed version for easier downloading
    log "Creating compressed image..."
    xz -z -k -f "$OUTPUT_DIR/raspberry-pi-os.img"
    
    log "Final image created: $OUTPUT_DIR/raspberry-pi-os.img"
    log "Compressed image: $OUTPUT_DIR/raspberry-pi-os.img.xz"
    log "✅ Image is ready to be flashed to SD card and used in real hardware!"
}

# Main build function
main() {
    log "Starting custom Raspberry Pi 3B OS build..."
    log "Build directory: $BUILD_DIR"
    log "Output directory: $OUTPUT_DIR"
    
    # Run build steps
    check_prerequisites
    setup_build_env
    download_base_os
    build_kernel
    create_overlay
    build_final_image
    
    log "Build completed successfully!"
    log "Output image: $OUTPUT_DIR/raspberry-pi-os.img"
    log "Build logs: $LOG_FILE"
}

# Run main function
main "$@"
