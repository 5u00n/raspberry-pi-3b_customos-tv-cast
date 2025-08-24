#!/bin/bash

# Build script specifically for macOS
# This creates a complete Raspberry Pi OS image with all customizations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE_DIR="$(pwd)"
BUILD_DIR="$WORKSPACE_DIR/build"
OUTPUT_DIR="$WORKSPACE_DIR/output"
PI_OS_VERSION="2023-02-22"
PI_OS_URL="https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2023-02-22/2023-02-21-raspios-bullseye-armhf-lite.img.xz"
FINAL_IMG="$OUTPUT_DIR/raspberry-pi-os-final.img"

# Logging
LOG_FILE="$BUILD_DIR/build-macos.log"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        error "This script is designed for macOS only."
    fi
    
    # Check for required tools
    for cmd in curl diskutil hdiutil rsync xz; do
        if ! command -v $cmd &> /dev/null; then
            error "$cmd is not installed. Please install it first."
        fi
    done
    
    log "Prerequisites check passed!"
}

# Create build environment
setup_build_env() {
    log "Setting up build environment..."
    
    # Create directories
    mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"
    
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

# Create filesystem overlay
create_overlay() {
    log "Creating filesystem overlay..."
    
    # Create overlay directory structure if it doesn't exist
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
    
    log "Filesystem overlay created!"
}

# Build final image using macOS approach
build_final_image() {
    log "Building final OS image with all customizations..."
    
    # Copy base image to output directory
    cp "$BUILD_DIR/base-os.img" "$FINAL_IMG"
    
    # Create a temporary directory for mounting
    MOUNT_DIR="$BUILD_DIR/mnt"
    mkdir -p "$MOUNT_DIR/boot" "$MOUNT_DIR/rootfs"
    
    # Attach the image file to get a device
    log "Attaching image file..."
    DEVICE=$(hdiutil attach -nomount "$FINAL_IMG" | head -n 1 | cut -d ' ' -f 1)
    
    if [ -z "$DEVICE" ]; then
        error "Failed to attach image file"
    fi
    
    log "Image attached as device: $DEVICE"
    
    # Wait a moment for the device to be ready
    sleep 2
    
    # Mount the boot partition (FAT32)
    log "Mounting boot partition..."
    diskutil mount -mountPoint "$MOUNT_DIR/boot" "${DEVICE}s1"
    
    # Create a temporary directory for rootfs
    TEMP_ROOTFS="$BUILD_DIR/rootfs_temp"
    mkdir -p "$TEMP_ROOTFS"
    
    # Since macOS can't directly mount ext4, we'll extract the rootfs to a temporary directory
    log "Extracting rootfs from image..."
    
    # Create a disk image from the rootfs partition
    dd if="${DEVICE}s2" of="$BUILD_DIR/rootfs.img" bs=1m
    
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

    # Copy config files to boot partition
    if [ -d "$WORKSPACE_DIR/configs" ]; then
        log "Copying configuration files to boot partition..."
        rsync -av "$WORKSPACE_DIR/configs/" "$MOUNT_DIR/boot/"
    fi
    
    # Copy packages list
    if [ -f "$WORKSPACE_DIR/packages/packages.txt" ]; then
        log "Copying packages list to boot partition..."
        cp "$WORKSPACE_DIR/packages/packages.txt" "$MOUNT_DIR/boot/"
    fi
    
    # Copy setup script
    if [ -f "$WORKSPACE_DIR/scripts/setup.sh" ]; then
        log "Copying setup script to boot partition..."
        cp "$WORKSPACE_DIR/scripts/setup.sh" "$MOUNT_DIR/boot/"
        chmod +x "$MOUNT_DIR/boot/setup.sh"
    fi
    
    # Create a special script in boot that will apply our overlay files on first boot
    log "Creating first-boot overlay script..."
    cat > "$MOUNT_DIR/boot/apply-overlay.sh" << 'EOF'
#!/bin/bash

# Script to apply overlay files on first boot
# This runs on the Raspberry Pi itself

LOG_FILE="/var/log/apply-overlay.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting overlay application..."

# Check if already applied
if [ -f "/etc/overlay-applied" ]; then
    log "Overlay already applied, skipping..."
    exit 0
fi

# Create necessary directories
mkdir -p /etc/systemd/system/getty@tty1.service.d
mkdir -p /etc/lightdm
mkdir -p /home/pi/.config/openbox

# Configure auto-login for console
log "Configuring console auto-login..."
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'EOT'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM
Type=idle
Restart=always
RestartSec=1
EOT

# Configure auto-login for desktop
log "Configuring desktop auto-login..."
cat > /etc/lightdm/lightdm.conf << 'EOT'
[SeatDefaults]
autologin-user=pi
autologin-user-timeout=0
autologin-session=openbox
user-session=openbox
autologin-guest=false
EOT

# Set graphical target as default
log "Setting graphical target as default..."
systemctl set-default graphical.target

# Configure WiFi
log "Configuring WiFi..."
if [ -f "/boot/wifi-credentials.txt" ]; then
    source /boot/wifi-credentials.txt
    
    # Generate wpa_supplicant.conf
    cat > /etc/wpa_supplicant/wpa_supplicant.conf << EOT
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

# Primary network (highest priority)
network={
    ssid="$WIFI_SSID_1"
    psk="$WIFI_PASSWORD_1"
    priority=$WIFI_PRIORITY_1
}

# Secondary network (lower priority)
network={
    ssid="$WIFI_SSID_2"
    psk="$WIFI_PASSWORD_2"
    priority=$WIFI_PRIORITY_2
}
EOT
fi

# Create .bashrc for auto-start
log "Creating .bashrc for auto-start..."
cat > /home/pi/.bashrc << 'EOT'
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
EOT

# Create rc.local file
log "Creating rc.local file..."
cat > /etc/rc.local << 'EOT'
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
        cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'INNER'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM
Type=idle
INNER
        
        # Configure desktop auto-login
        log "Configuring desktop auto-login..."
        mkdir -p /etc/lightdm
        cat > /etc/lightdm/lightdm.conf << 'INNER'
[SeatDefaults]
autologin-user=pi
autologin-user-timeout=0
autologin-session=openbox
user-session=openbox
autologin-guest=false
INNER
        
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
EOT

chmod +x /etc/rc.local

# Install required packages
log "Creating package installation script..."
cat > /boot/install-packages.sh << 'EOT'
#!/bin/bash

# Install required packages
LOG_FILE="/var/log/install-packages.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting package installation..."

# Update package lists
log "Updating package lists..."
apt-get update

# Install packages from list
if [ -f "/boot/packages.txt" ]; then
    log "Installing packages from list..."
    apt-get install -y $(grep -v '^#' /boot/packages.txt)
else
    log "No package list found, installing minimal set..."
    apt-get install -y xserver-xorg lxde lightdm openbox python3-tk python3-psutil
fi

# Install Python packages
log "Installing Python packages..."
pip3 install flask flask-cors requests psutil

log "Package installation complete!"
EOT

chmod +x /boot/install-packages.sh

# Mark overlay as applied
log "Marking overlay as applied..."
echo "$(date): Overlay applied" > /etc/overlay-applied

log "Overlay application complete!"
EOF

    chmod +x "$MOUNT_DIR/boot/apply-overlay.sh"
    
    # Create a systemd service to run the overlay script
    cat > "$MOUNT_DIR/boot/overlay.service" << 'EOF'
[Unit]
Description=Apply Overlay Files
After=network.target

[Service]
Type=oneshot
ExecStart=/boot/apply-overlay.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    # Create a script to install the service on first boot
    cat > "$MOUNT_DIR/boot/install-service.sh" << 'EOF'
#!/bin/bash
# Install the overlay service
cp /boot/overlay.service /etc/systemd/system/
systemctl enable overlay.service
systemctl start overlay.service
EOF

    chmod +x "$MOUNT_DIR/boot/install-service.sh"
    
    # Add the service installation to /etc/rc.local in the boot partition
    cat > "$MOUNT_DIR/boot/rc.local" << 'EOF'
#!/bin/bash
# Run the service installer if it exists
if [ -f /boot/install-service.sh ]; then
    /boot/install-service.sh
fi
exit 0
EOF

    chmod +x "$MOUNT_DIR/boot/rc.local"
    
    # Copy our overlay files to the boot partition so they can be applied on first boot
    log "Copying overlay files to boot partition..."
    mkdir -p "$MOUNT_DIR/boot/overlay"
    rsync -av "$WORKSPACE_DIR/overlays/" "$MOUNT_DIR/boot/overlay/"
    
    # Create a script to copy the overlay files on first boot
    cat > "$MOUNT_DIR/boot/copy-overlay.sh" << 'EOF'
#!/bin/bash
# Copy overlay files to rootfs
LOG_FILE="/var/log/copy-overlay.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Copying overlay files..."
rsync -av /boot/overlay/ /
chmod +x /usr/local/bin/*.sh
chmod +x /usr/local/bin/*.py
log "Overlay files copied!"
EOF

    chmod +x "$MOUNT_DIR/boot/copy-overlay.sh"
    
    # Update the install-service.sh script to also copy overlay files
    cat > "$MOUNT_DIR/boot/install-service.sh" << 'EOF'
#!/bin/bash
# Copy overlay files first
if [ -f /boot/copy-overlay.sh ]; then
    /boot/copy-overlay.sh
fi
# Install the overlay service
cp /boot/overlay.service /etc/systemd/system/
systemctl enable overlay.service
systemctl start overlay.service
EOF

    # Sync and unmount
    log "Syncing and unmounting..."
    sync
    diskutil unmount "$MOUNT_DIR/boot"
    hdiutil detach "$DEVICE"
    
    # Clean up
    rm -rf "$MOUNT_DIR"
    
    # Create a compressed version for easier downloading
    log "Creating compressed image..."
    xz -z -k -f "$FINAL_IMG"
    
    log "Final image created: $FINAL_IMG"
    log "Compressed image: $FINAL_IMG.xz"
    log "✅ Image is ready to be flashed to SD card and used in real hardware!"
}

# Main build function
main() {
    log "Starting custom Raspberry Pi 3B OS build for macOS..."
    log "Build directory: $BUILD_DIR"
    log "Output directory: $OUTPUT_DIR"
    
    # Run build steps
    check_prerequisites
    setup_build_env
    download_base_os
    create_overlay
    build_final_image
    
    log "Build completed successfully!"
    log "Output image: $FINAL_IMG"
    log "Compressed image: $FINAL_IMG.xz"
    log "Build logs: $LOG_FILE"
    log ""
    log "To use this image on your Raspberry Pi:"
    log "1. Flash the image to an SD card using 'sudo dd if=$FINAL_IMG of=/dev/rdiskX bs=1m'"
    log "2. Insert the SD card into your Raspberry Pi 3B"
    log "3. Power on the Raspberry Pi"
    log "4. The system will auto-login and start the GUI automatically"
}

# Run main function
main "$@"
