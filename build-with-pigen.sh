#!/bin/bash

# Build Custom Raspberry Pi OS using pi-gen
# This follows the official Raspberry Pi image building process

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

log "🍓 Building Custom Raspberry Pi 3B OS with pi-gen"
log "================================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker Desktop from https://www.docker.com/products/docker-desktop"
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    error "Docker is not running. Please start Docker Desktop and try again."
fi

# Clone pi-gen if not exists
if [ ! -d "pi-gen" ]; then
    log "Cloning pi-gen repository..."
    git clone https://github.com/RPi-Distro/pi-gen.git
else
    log "pi-gen directory already exists"
fi

cd pi-gen

# Clean previous builds
log "Cleaning previous builds..."
rm -rf work deploy

# Create config file
log "Creating custom configuration..."
cat > config << 'EOF'
IMG_NAME='RaspberryPi3B-CustomOS'
ENABLE_SSH=1
STAGE_LIST="stage0 stage1 stage2"
EOF

# Create our custom stage
log "Creating custom stage with your features..."
mkdir -p stage3/00-install-packages
mkdir -p stage3/01-custom-services/files
mkdir -p stage3/02-custom-gui/files
mkdir -p stage3/03-custom-config/files

# Create package list
cat > stage3/00-install-packages/00-packages << 'EOF'
python3
python3-pip
python3-tk
python3-psutil
shairport-sync
avahi-daemon
samba
nginx
iw
wireless-tools
hostapd
dnsmasq
xserver-xorg
lxde
lightdm
openbox
EOF

# Create service installation script
cat > stage3/01-custom-services/00-run-chroot.sh << 'EOFSCRIPT'
#!/bin/bash -e

# Install Python packages
pip3 install flask flask-cors requests

# Copy service files
cp files/airplay.service /etc/systemd/system/
cp files/google-cast.service /etc/systemd/system/
cp files/wifi-tools.service /etc/systemd/system/
cp files/remote-control.service /etc/systemd/system/
cp files/desktop-ui.service /etc/systemd/system/

# Enable services
systemctl enable airplay.service
systemctl enable google-cast.service
systemctl enable wifi-tools.service
systemctl enable remote-control.service
systemctl enable desktop-ui.service
EOFSCRIPT

chmod +x stage3/01-custom-services/00-run-chroot.sh

# Copy service files from our project
cp ../overlays/etc/systemd/system/airplay.service stage3/01-custom-services/files/
cp ../overlays/etc/systemd/system/google-cast.service stage3/01-custom-services/files/
cp ../overlays/etc/systemd/system/wifi-tools.service stage3/01-custom-services/files/
cp ../overlays/etc/systemd/system/remote-control.service stage3/01-custom-services/files/
cp ../overlays/etc/systemd/system/desktop-ui.service stage3/01-custom-services/files/

# Create GUI installation script
cat > stage3/02-custom-gui/00-run-chroot.sh << 'EOFGUI'
#!/bin/bash -e

# Create bin directory
mkdir -p /usr/local/bin

# Copy GUI application
cp files/raspberry-pi-gui.py /usr/local/bin/
chmod +x /usr/local/bin/raspberry-pi-gui.py

# Configure openbox to auto-start GUI
mkdir -p /home/pi/.config/openbox
cat > /home/pi/.config/openbox/autostart << 'AUTOSTART'
# Start custom GUI
python3 /usr/local/bin/raspberry-pi-gui.py &
AUTOSTART

chown -R 1000:1000 /home/pi/.config
EOFGUI

chmod +x stage3/02-custom-gui/00-run-chroot.sh

# Copy GUI file
cp ../overlays/usr/local/bin/raspberry-pi-gui.py stage3/02-custom-gui/files/

# Create configuration script
cat > stage3/03-custom-config/00-run-chroot.sh << 'EOFCONFIG'
#!/bin/bash -e

# Configure auto-login for console
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'AUTOLOGIN'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM
AUTOLOGIN

# Configure auto-login for desktop
sed -i 's/#autologin-user=/autologin-user=pi/' /etc/lightdm/lightdm.conf
sed -i 's/#autologin-user-timeout=0/autologin-user-timeout=0/' /etc/lightdm/lightdm.conf

# Configure WiFi (if credentials provided)
if [ -f files/wpa_supplicant.conf ]; then
    cp files/wpa_supplicant.conf /etc/wpa_supplicant/
fi

# Configure Samba
cat >> /etc/samba/smb.conf << 'SAMBA'
[pi]
   path = /home/pi
   browseable = yes
   read only = no
   guest ok = no
SAMBA

# Set Samba password (default: raspberry)
(echo "raspberry"; echo "raspberry") | smbpasswd -a pi

# Configure Nginx for remote control
cat > /etc/nginx/sites-available/remote-control << 'NGINX'
server {
    listen 8080;
    location / {
        proxy_pass http://127.0.0.1:5000;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/remote-control /etc/nginx/sites-enabled/
EOFCONFIG

chmod +x stage3/03-custom-config/00-run-chroot.sh

# Copy config files
cp ../configs/wpa_supplicant.conf stage3/03-custom-config/files/ 2>/dev/null || true

# Create EXPORT marker
touch stage3/EXPORT_IMAGE

log "Configuration complete!"
log ""
log "Building the custom OS image with Docker..."
log "This will take 30-60 minutes depending on your internet speed and computer."
log ""

# Build using Docker
./build-docker.sh

log ""
log "✅ Build complete!"
log ""
log "Your custom OS image is ready at:"
log "  pi-gen/deploy/RaspberryPi3B-CustomOS.img"
log ""
log "To flash to SD card:"
log "  1. Insert SD card"
log "  2. Find device: diskutil list"
log "  3. Unmount: diskutil unmountDisk /dev/diskX"
log "  4. Flash: sudo dd if=pi-gen/deploy/RaspberryPi3B-CustomOS.img of=/dev/rdiskX bs=1m"
log ""
log "🍓 Your custom Raspberry Pi OS is ready for deployment!"

