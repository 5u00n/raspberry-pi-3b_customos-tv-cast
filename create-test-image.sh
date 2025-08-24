#!/bin/bash

# Create Fully Customized Test Image
# This script creates a complete customized image for testing in QEMU

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE_DIR="$(pwd)"
BUILD_DIR="$WORKSPACE_DIR/build"
OUTPUT_DIR="$WORKSPACE_DIR/output"
OVERLAY_DIR="$WORKSPACE_DIR/overlays"
BASE_IMG="$BUILD_DIR/base-os.img"
TEST_IMG="$OUTPUT_DIR/test-image.img"
MOUNT_DIR="$BUILD_DIR/mnt"

log() {
    echo -e "${GREEN}$1${NC}"
}

warn() {
    echo -e "${YELLOW}$1${NC}"
}

error() {
    echo -e "${RED}$1${NC}"
    exit 1
}

# Check if base image exists
if [ ! -f "$BASE_IMG" ]; then
    error "Base image not found: $BASE_IMG. Run ./scripts/build.sh first."
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Copy base image to test image
log "Creating test image from base image..."
cp "$BASE_IMG" "$TEST_IMG"

# Create temporary mount directories
mkdir -p "$MOUNT_DIR/boot" "$MOUNT_DIR/rootfs"

# Create a disk image from the test image for mounting
log "Creating disk image for mounting..."
hdiutil attach -nomount "$TEST_IMG"

# Get the device name
DEVICE=$(hdiutil info | grep "$TEST_IMG" | cut -f1)
if [ -z "$DEVICE" ]; then
    error "Failed to attach test image"
fi

log "Test image attached as device: $DEVICE"

# Find the partition offsets
BOOT_PART="${DEVICE}s1"
ROOTFS_PART="${DEVICE}s2"

log "Boot partition: $BOOT_PART"
log "Root filesystem partition: $ROOTFS_PART"

# Mount the boot partition
log "Mounting boot partition..."
diskutil mount -mountPoint "$MOUNT_DIR/boot" "$BOOT_PART"

# Since we can't directly mount ext4 on macOS, we'll copy overlay files to boot
# and create a script to apply them on first boot

# Create overlay directory in boot
log "Creating overlay directory in boot..."
mkdir -p "$MOUNT_DIR/boot/overlay"

# Copy overlay files to boot partition
log "Copying overlay files to boot partition..."
rsync -av "$OVERLAY_DIR/" "$MOUNT_DIR/boot/overlay/"

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

# Create apply-overlay.sh script
log "Creating apply-overlay script..."
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

# Copy overlay files to rootfs
log "Copying overlay files..."
rsync -av /boot/overlay/ /
chmod +x /usr/local/bin/*.sh
chmod +x /usr/local/bin/*.py

# Configure auto-login for console
log "Configuring console auto-login..."
mkdir -p /etc/systemd/system/getty@tty1.service.d
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
mkdir -p /etc/lightdm
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

# Install required packages
log "Installing required packages..."
apt-get update
if [ -f "/boot/packages.txt" ]; then
    apt-get install -y $(grep -v '^#' /boot/packages.txt)
else
    apt-get install -y xserver-xorg lxde lightdm openbox python3-tk python3-psutil
fi

# Install Python packages
log "Installing Python packages..."
pip3 install flask flask-cors requests psutil

# Enable all services
log "Enabling services..."
for service_file in /etc/systemd/system/*.service; do
    if [ -f "$service_file" ]; then
        service_name=$(basename "$service_file")
        log "Enabling service: $service_name"
        systemctl enable "$service_name"
    fi
done

# Mark overlay as applied
log "Marking overlay as applied..."
echo "$(date): Overlay applied" > /etc/overlay-applied

# Reboot to apply changes
log "Rebooting to apply changes..."
reboot
EOF

chmod +x "$MOUNT_DIR/boot/apply-overlay.sh"

# Create rc.local to run apply-overlay.sh on first boot
log "Creating rc.local..."
cat > "$MOUNT_DIR/boot/rc.local" << 'EOF'
#!/bin/bash

# RC Local for Raspberry Pi 3B
# This script runs on every boot

LOG_FILE="/var/log/rc-local.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🍓 $1" | tee -a "$LOG_FILE"
}

log "Starting Raspberry Pi 3B configuration..."

# Run apply-overlay.sh if it exists
if [ -f "/boot/apply-overlay.sh" ] && [ ! -f "/etc/overlay-applied" ]; then
    log "Running apply-overlay.sh..."
    /boot/apply-overlay.sh
fi

# Check if setup is already complete
if [ -f "/etc/overlay-applied" ] && [ ! -f "/etc/setup-complete" ]; then
    log "First boot after overlay, running setup..."
    
    # Wait for system to be ready
    sleep 15
    
    # Run first boot setup script if available
    if [ -f "/usr/local/bin/first-boot-setup.sh" ]; then
        log "Executing first-boot setup script..."
        chmod +x /usr/local/bin/first-boot-setup.sh
        /usr/local/bin/first-boot-setup.sh
    else
        log "First-boot setup script not found, running basic configuration..."
        
        # Start services
        services=("airplay.service" "google-cast.service" "wifi-tools.service" "remote-control.service" "desktop-ui.service")
        for service in "${services[@]}"; do
            log "Starting $service..."
            systemctl start "$service"
        done
        
        # Mark setup as complete
        log "Marking setup as complete..."
        echo "$(date): Basic setup completed via rc.local" > /etc/setup-complete
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

chmod +x "$MOUNT_DIR/boot/rc.local"

# Create cmdline.txt to run rc.local on boot
log "Updating cmdline.txt..."
CMDLINE=$(cat "$MOUNT_DIR/boot/cmdline.txt")
echo "$CMDLINE init=/etc/rc.local" > "$MOUNT_DIR/boot/cmdline.txt"

# Create a README file in boot
log "Creating README file..."
cat > "$MOUNT_DIR/boot/README.txt" << 'EOF'
Raspberry Pi 3B Custom OS - Test Image

This image contains a custom Raspberry Pi OS with the following features:
- Auto-login without password
- GUI dashboard showing system status
- AirPlay, Google Cast, and Miracast support
- Remote control interface
- WiFi security tools
- File server

On first boot, the system will:
1. Apply all customizations from the overlay directory
2. Configure WiFi using wifi-credentials.txt
3. Install required packages
4. Enable all services
5. Reboot to apply changes

After the reboot, the system will:
1. Auto-login without password
2. Start the GUI dashboard
3. Connect to WiFi automatically
4. Start all services

If you have any issues, check the log files:
- /var/log/apply-overlay.log
- /var/log/rc-local.log
- /var/log/force-autologin.log
- /var/log/gui-app.log
EOF

# Sync and unmount
log "Syncing and unmounting..."
sync
sleep 2
diskutil unmount "$MOUNT_DIR/boot"
sleep 2
hdiutil detach "$DEVICE"

log "✅ Test image created successfully: $TEST_IMG"
log "You can now test this image using QEMU:"
log "  ./test-qemu.sh $TEST_IMG"

# Create a test script for this specific image
log "Creating test script for this image..."
cat > "$WORKSPACE_DIR/test-qemu.sh" << EOF
#!/bin/bash

# Test QEMU Script for Custom Image
# Usage: ./test-qemu.sh [image_file]

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE_DIR="$(pwd)"
KERNEL_DIR="\$WORKSPACE_DIR/qemu_kernel"
KERNEL="\$KERNEL_DIR/kernel-qemu-4.19.50-buster"
DTB="\$KERNEL_DIR/versatile-pb-buster.dtb"

# Default image file
IMAGE_FILE="$TEST_IMG"

# Override with command line argument if provided
if [ \$# -eq 1 ]; then
    IMAGE_FILE="\$1"
fi

log() {
    echo -e "\${GREEN}\$1\${NC}"
}

warn() {
    echo -e "\${YELLOW}\$1\${NC}"
}

error() {
    echo -e "\${RED}\$1\${NC}"
    exit 1
}

# Create kernel directory if it doesn't exist
mkdir -p "\$KERNEL_DIR"

# Download kernel files if they don't exist
if [ ! -f "\$KERNEL" ]; then
    log "🔍 Downloading QEMU kernel..."
    curl -L -o "\$KERNEL" "https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-4.19.50-buster"
fi

if [ ! -f "\$DTB" ]; then
    log "🔍 Downloading device tree blob..."
    curl -L -o "\$DTB" "https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/versatile-pb-buster.dtb"
fi

# Check if files exist
if [ ! -f "\$IMAGE_FILE" ]; then
    error "Image file not found: \$IMAGE_FILE"
fi

if [ ! -f "\$KERNEL" ]; then
    error "Kernel not found: \$KERNEL"
fi

if [ ! -f "\$DTB" ]; then
    error "Device tree blob not found: \$DTB"
fi

log "✅ All required files found!"

# Make sure no other QEMU instances are running
pkill -f qemu-system-arm || true
sleep 2

# Start QEMU with the image
log "🚀 Starting QEMU emulation..."
qemu-system-arm \\
    -kernel "\$KERNEL" \\
    -dtb "\$DTB" \\
    -m 256 \\
    -M versatilepb \\
    -cpu arm1176 \\
    -hda "\$IMAGE_FILE" \\
    -net nic \\
    -net user,hostfwd=tcp::5022-:22 \\
    -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw console=ttyAMA0" \\
    -no-reboot \\
    -display cocoa \\
    -serial stdio

log "🏁 QEMU session ended."

log "💡 Tips for testing:"
log "   • The Pi should boot and apply all customizations"
log "   • Look for auto-login to happen"
log "   • Desktop environment should load"
log "   • GUI application should start automatically"
log "   • Press Ctrl+C in QEMU to exit"
EOF

chmod +x "$WORKSPACE_DIR/test-qemu.sh"

log "You can now run: ./test-qemu.sh"
