#!/bin/bash

# Fix SD Card Script
# This script fixes the SD card to ensure all features work

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE_DIR="$(pwd)"
OVERLAY_DIR="$WORKSPACE_DIR/overlays"

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

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root (use sudo)"
fi

# List available disks
log "Available disks:"
diskutil list

# Ask for disk to fix
echo ""
read -p "Enter the disk identifier of your SD card (e.g., disk4): " DISK_ID

# Confirm disk selection
echo ""
echo "You selected: $DISK_ID"
echo "THIS WILL MODIFY THE SD CARD ${DISK_ID}!"
read -p "Are you sure you want to continue? (y/n): " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    error "Operation cancelled by user"
fi

# Mount boot partition
log "Mounting boot partition..."
BOOT_MOUNT="/tmp/rpi_boot"
mkdir -p "$BOOT_MOUNT"

# Find the boot partition
BOOT_PART=$(diskutil list | grep -A 2 "$DISK_ID" | grep "EFI\|FAT" | awk '{print $NF}')
if [ -z "$BOOT_PART" ]; then
    error "Boot partition not found"
fi
log "Boot partition: $BOOT_PART"

# Mount the boot partition
diskutil mount -mountPoint "$BOOT_MOUNT" "/dev/${BOOT_PART}"
sleep 2

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

# Create firstrun.sh script
log "Creating firstrun.sh script..."
cat > "$BOOT_MOUNT/firstrun.sh" << 'EOF'
#!/bin/bash

# Log file for debugging
LOG_FILE=/boot/firstrun.log

# Log function
log() {
  echo "$(date): $1" | tee -a "$LOG_FILE"
}

log "Starting first run setup..."

# Copy overlay files
log "Copying overlay files..."
cp -r /boot/overlay/* /

# Make scripts executable
log "Setting permissions..."
find /usr/local/bin -type f -name "*.sh" -exec chmod +x {} \;
find /usr/local/bin -type f -name "*.py" -exec chmod +x {} \;

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

# Set up WiFi
log "Setting up WiFi..."
if [ -f "/boot/wifi-credentials.txt" ]; then
    source /boot/wifi-credentials.txt
    cat > /etc/wpa_supplicant/wpa_supplicant.conf << EOT
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
    ssid="$WIFI_SSID_1"
    psk="$WIFI_PASSWORD_1"
    priority=$WIFI_PRIORITY_1
}

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
apt-get install -y xserver-xorg lxde lightdm openbox python3-tk python3-psutil

# Install Python packages
log "Installing Python packages..."
pip3 install flask flask-cors requests psutil

# Enable services
log "Enabling services..."
for service_file in /etc/systemd/system/*.service; do
    if [ -f "$service_file" ]; then
        service_name=$(basename "$service_file")
        log "Enabling service: $service_name"
        systemctl enable "$service_name"
    fi
done

# Set graphical target
log "Setting graphical target..."
systemctl set-default graphical.target

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
    log "First boot after setup, running configuration..."
    
    # Start all services
    services=("airplay.service" "google-cast.service" "wifi-tools.service" "remote-control.service" "desktop-ui.service")
    for service in "${services[@]}"; do
        log "Starting $service..."
        systemctl start "$service"
    done
    
    # Mark setup as complete
    log "Marking setup as complete..."
    echo "$(date): Setup completed" > /etc/setup-complete
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

# Mark as completed
log "First run completed"
rm /boot/firstrun.sh
touch /boot/firstrun.done

# Reboot
log "Rebooting..."
reboot
EOF

chmod +x "$BOOT_MOUNT/firstrun.sh"

# Modify cmdline.txt
log "Modifying cmdline.txt..."
CMDLINE=$(cat "$BOOT_MOUNT/cmdline.txt")
echo "$CMDLINE init=/bin/bash -c \"mount -t proc proc /proc; mount -t sysfs sys /sys; mount /boot; if [ -f /boot/firstrun.sh ]; then source /boot/firstrun.sh; else exec /sbin/init; fi\"" > "$BOOT_MOUNT/cmdline.txt"

# Sync and unmount
log "Syncing and unmounting..."
sync
diskutil unmount "$BOOT_MOUNT"

log "✅ SD card fixed successfully!"
log "You can now insert the SD card into your Raspberry Pi 3B."
log "The system will:"
log "  1. Run the firstrun.sh script on first boot"
log "  2. Copy all overlay files to the root filesystem"
log "  3. Configure auto-login and auto-start"
log "  4. Install required packages"
log "  5. Set up WiFi with your networks"
log "  6. Enable all services"
log "  7. Reboot to apply changes"
log ""
log "After the reboot, the system will:"
log "  1. Auto-login without password"
log "  2. Start the GUI dashboard"
log "  3. Connect to WiFi automatically"
log "  4. Start all services"
