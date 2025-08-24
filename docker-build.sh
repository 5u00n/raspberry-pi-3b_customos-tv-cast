#!/bin/bash

# Docker Build Script for Raspberry Pi OS
# This script builds a complete customized image and tests it

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE_DIR="/workspace"
BUILD_DIR="$WORKSPACE_DIR/build"
OUTPUT_DIR="$WORKSPACE_DIR/output"
OVERLAY_DIR="$WORKSPACE_DIR/overlays"
PI_OS_VERSION="2023-02-22"
PI_OS_URL="https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2023-02-22/2023-02-21-raspios-bullseye-armhf-lite.img.xz"
KERNEL_DIR="$WORKSPACE_DIR/qemu_kernel"
KERNEL="$KERNEL_DIR/kernel-qemu-4.19.50-buster"
DTB="$KERNEL_DIR/versatile-pb-buster.dtb"

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

# Create directories
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR" "$KERNEL_DIR"

# Download base Raspberry Pi OS
log "Downloading base Raspberry Pi OS..."
if [ ! -f "$BUILD_DIR/base-os.img.xz" ]; then
    log "Downloading from: $PI_OS_URL"
    wget -O "$BUILD_DIR/base-os.img.xz" "$PI_OS_URL"
else
    log "Base OS already downloaded, skipping..."
fi

# Extract image
if [ ! -f "$BUILD_DIR/base-os.img" ]; then
    log "Extracting base OS image..."
    xz -d "$BUILD_DIR/base-os.img.xz"
fi

# Download QEMU kernel files
log "Downloading QEMU kernel files..."
if [ ! -f "$KERNEL" ]; then
    wget -O "$KERNEL" "https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-4.19.50-buster"
fi

if [ ! -f "$DTB" ]; then
    wget -O "$DTB" "https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/versatile-pb-buster.dtb"
fi

# Copy base image to output directory
log "Creating customized image..."
cp "$BUILD_DIR/base-os.img" "$OUTPUT_DIR/raspberry-pi-os-custom.img"

# Create mount points
MOUNT_DIR="$BUILD_DIR/mnt"
mkdir -p "$MOUNT_DIR/boot" "$MOUNT_DIR/rootfs"

# Set up loop device
log "Setting up loop device..."
LOOP_DEVICE=$(losetup -f)
losetup -P "$LOOP_DEVICE" "$OUTPUT_DIR/raspberry-pi-os-custom.img"

# Mount partitions
log "Mounting partitions..."
mount "${LOOP_DEVICE}p1" "$MOUNT_DIR/boot"
mount "${LOOP_DEVICE}p2" "$MOUNT_DIR/rootfs"

# Copy overlay files to rootfs
log "Applying overlay files to rootfs..."
if [ -d "$OVERLAY_DIR" ]; then
    rsync -av "$OVERLAY_DIR/" "$MOUNT_DIR/rootfs/"
    
    # Make scripts executable
    find "$MOUNT_DIR/rootfs/usr/local/bin" -type f -name "*.sh" -exec chmod +x {} \; || true
    find "$MOUNT_DIR/rootfs/usr/local/bin" -type f -name "*.py" -exec chmod +x {} \; || true
else
    warn "No overlay directory found, skipping..."
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

# Configure desktop auto-login
log "Configuring desktop auto-login..."
mkdir -p "$MOUNT_DIR/rootfs/etc/lightdm"
cat > "$MOUNT_DIR/rootfs/etc/lightdm/lightdm.conf" << 'EOF'
[SeatDefaults]
autologin-user=pi
autologin-user-timeout=0
autologin-session=openbox
user-session=openbox
autologin-guest=false
EOF

# Set default target to graphical.target
log "Setting default target to graphical.target..."
ln -sf "/lib/systemd/system/graphical.target" "$MOUNT_DIR/rootfs/etc/systemd/system/default.target"

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

chmod +x "$MOUNT_DIR/rootfs/etc/rc.local"

# Enable systemd services
log "Enabling systemd services..."
for service_file in $(find "$OVERLAY_DIR/etc/systemd/system" -name "*.service" 2>/dev/null || echo ""); do
    if [ -f "$service_file" ]; then
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
    fi
done

# Sync and unmount
log "Syncing and unmounting..."
sync
umount "$MOUNT_DIR/boot"
umount "$MOUNT_DIR/rootfs"
losetup -d "$LOOP_DEVICE"

log "✅ Customized image created: $OUTPUT_DIR/raspberry-pi-os-custom.img"

# Test the image with QEMU
log "Testing the customized image with QEMU..."
qemu-system-arm \
    -kernel "$KERNEL" \
    -dtb "$DTB" \
    -m 256 \
    -M versatilepb \
    -cpu arm1176 \
    -hda "$OUTPUT_DIR/raspberry-pi-os-custom.img" \
    -net nic \
    -net user,hostfwd=tcp::5022-:22 \
    -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw console=ttyAMA0" \
    -no-reboot \
    -nographic

log "✅ Build and test complete!"
log "The customized image is available at: $OUTPUT_DIR/raspberry-pi-os-custom.img"
