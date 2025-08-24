#!/bin/bash

# Prepare SD Card Script
# This script flashes the base Raspberry Pi OS image and adds our customizations

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
OVERLAY_DIR="$WORKSPACE_DIR/overlays"
BASE_IMG="$BUILD_DIR/base-os.img"

# Logging
LOG_FILE="$BUILD_DIR/prepare-sd-card.log"

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

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root (use sudo)"
fi

# Check if base image exists
if [ ! -f "$BASE_IMG" ]; then
    error "Base image not found: $BASE_IMG. Run ./scripts/build.sh first."
fi

# List available disks
log "Available disks:"
diskutil list

# Ask for disk to flash
echo ""
read -p "Enter the disk identifier to flash (e.g., disk2): " DISK_ID

# Confirm disk selection
echo ""
echo "You selected: $DISK_ID"
echo "THIS WILL ERASE ALL DATA ON ${DISK_ID}!"
read -p "Are you sure you want to continue? (y/n): " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    error "Operation cancelled by user"
fi

# Unmount disk
log "Unmounting disk $DISK_ID..."
diskutil unmountDisk "/dev/$DISK_ID"

# Flash image
log "Flashing image to disk $DISK_ID..."
dd if="$BASE_IMG" of="/dev/r$DISK_ID" bs=1m

# Sync and wait
log "Syncing disk..."
sync
sleep 5

# Re-mount disk to copy overlay files
log "Re-mounting disk..."
diskutil mountDisk "/dev/$DISK_ID"
sleep 5

# Find the boot partition
BOOT_PART=$(diskutil list | grep -A 2 "$DISK_ID" | grep "EFI\|FAT" | awk '{print $NF}')

if [ -z "$BOOT_PART" ]; then
    error "Boot partition not found"
fi

log "Boot partition: $BOOT_PART"

# Create a mount point for the boot partition
BOOT_MOUNT="/tmp/rpi_boot"
mkdir -p "$BOOT_MOUNT"

# Check if the partition is already mounted
CURRENT_MOUNT=$(mount | grep "/dev/${BOOT_PART}" | awk '{print $3}')

if [ -n "$CURRENT_MOUNT" ]; then
    log "Boot partition is already mounted at $CURRENT_MOUNT"
    BOOT_MOUNT="$CURRENT_MOUNT"
else
    # Manually mount the boot partition
    log "Manually mounting boot partition..."
    diskutil mount "/dev/${BOOT_PART}"
    sleep 2
    
    # Find where it was mounted
    CURRENT_MOUNT=$(mount | grep "/dev/${BOOT_PART}" | awk '{print $3}')
    
    if [ -n "$CURRENT_MOUNT" ]; then
        log "Boot partition mounted at $CURRENT_MOUNT"
        BOOT_MOUNT="$CURRENT_MOUNT"
    else
        error "Failed to mount boot partition"
    fi
fi

sleep 2

# Verify the mount
if [ ! -d "$BOOT_MOUNT" ] || ! mount | grep -q "$BOOT_MOUNT"; then
    error "Failed to mount boot partition to $BOOT_MOUNT"
fi

log "Boot partition mounted at $BOOT_MOUNT"

# Create overlay directory in boot
log "Creating overlay directory in boot..."
mkdir -p "$BOOT_MOUNT/overlay"

# Copy overlay files to boot partition
log "Copying overlay files to boot partition..."
rsync -av "$OVERLAY_DIR/" "$BOOT_MOUNT/overlay/"

# Create wifi-credentials.txt in boot partition
log "Creating WiFi credentials file..."
cat > "$BOOT_MOUNT/wifi-credentials.txt" << 'EOF'
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
    rsync -av "$WORKSPACE_DIR/configs/" "$BOOT_MOUNT/"
fi

# Copy packages list
if [ -f "$WORKSPACE_DIR/packages/packages.txt" ]; then
    log "Copying packages list to boot partition..."
    cp "$WORKSPACE_DIR/packages/packages.txt" "$BOOT_MOUNT/"
fi

# Create apply-overlay.sh script
log "Creating apply-overlay script..."
cat > "$BOOT_MOUNT/apply-overlay.sh" << 'EOF'
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

chmod +x "$BOOT_MOUNT/apply-overlay.sh"

# Create rc.local to run apply-overlay.sh on first boot
log "Creating rc.local..."
cat > "$BOOT_MOUNT/rc.local" << 'EOF'
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

# Create cmdline.txt to run rc.local on boot
log "Updating cmdline.txt..."
CMDLINE=$(cat "$BOOT_MOUNT/cmdline.txt")
echo "$CMDLINE init=/etc/rc.local" > "$BOOT_MOUNT/cmdline.txt"

# Create a README file in boot
log "Creating README file..."
cat > "$BOOT_MOUNT/README.txt" << 'EOF'
Raspberry Pi 3B Custom OS

This SD card contains a custom Raspberry Pi OS with the following features:
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

# Sync first
log "Syncing..."
sync
sleep 2

# Try to unmount the entire disk (this will unmount all partitions)
log "Unmounting disk (this may take a moment)..."
diskutil unmountDisk force "/dev/$DISK_ID"
sleep 2

log "✅ SD card prepared successfully!"
log "You can now insert the SD card into your Raspberry Pi 3B."
log "The system will:"
log "  1. Apply all customizations on first boot"
log "  2. Auto-login without password"
log "  3. Start the GUI dashboard automatically"
log "  4. Connect to WiFi automatically"
log "  5. Start all services"
