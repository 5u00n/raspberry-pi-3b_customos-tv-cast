#!/bin/bash

# Build Custom Raspberry Pi OS on Debian/Ubuntu
# This script mirrors the GitHub Actions workflow for local Debian/Ubuntu builds

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() { echo -e "${GREEN}[BUILD]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
step() { echo -e "${PURPLE}[STEP]${NC} $1"; }

log "🍓 Building Custom Raspberry Pi 3B OS on Debian/Ubuntu"
log "======================================================="
echo

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    error "This script must run on Debian/Ubuntu Linux"
fi

# Check if running as root for apt
if [ "$EUID" -ne 0 ]; then 
    warn "Some steps require sudo. You may be prompted for password."
fi

step "1/8: Installing dependencies..."
sudo apt-get update
sudo apt-get install -y \
    coreutils quilt parted qemu-user-static debootstrap zerofree zip \
    dosfstools libarchive-tools libcap2-bin grep rsync xz-utils file \
    git curl bc qemu-utils kpartx arch-test
log "✅ Dependencies installed"

step "2/8: Cloning pi-gen repository..."
rm -rf pi-gen
git clone https://github.com/RPi-Distro/pi-gen.git
cd pi-gen
# Use 2024 branch which supports bookworm
git checkout 2024-07-04-raspios-bookworm || git checkout master
log "✅ pi-gen cloned"

step "3/8: Cleaning previous builds..."
sudo rm -rf work deploy
log "✅ Cleaned"

step "4/8: Creating config..."
cat > config << 'EOF'
IMG_NAME='CustomRaspberryPi3B'
RELEASE=bookworm
DEPLOY_COMPRESSION=zip
ENABLE_SSH=1
STAGE_LIST="stage0 stage1 stage2"
TARGET_HOSTNAME=raspberrypi-custom
FIRST_USER_NAME=pi
FIRST_USER_PASS=raspberry
DISABLE_FIRST_BOOT_USER_RENAME=1
DEPLOY_ZIP=1
EOF
log "✅ Config created"

step "5/8: Adding custom packages and scripts..."
# Add custom packages to stage2
mkdir -p stage2/99-custom-packages

cat > stage2/99-custom-packages/00-packages << 'EOFPKG'
# Core Python packages
python3
python3-pip
python3-pyqt5
python3-psutil
python3-requests
python3-flask
python3-flask-cors

# Desktop environment
xserver-xorg
xinit
lightdm
lxde-core
openbox
pcmanfm
lxterminal

# AirPlay and audio
shairport-sync
avahi-daemon
avahi-utils
alsa-utils
pulseaudio
pulseaudio-utils

# Network discovery and services
samba
samba-common-bin
nginx
openssh-server

# WiFi tools
iw
wireless-tools
aircrack-ng
wireshark-common

# System utilities
htop
vim
curl
wget
git
EOFPKG

cat > stage2/99-custom-packages/01-run.sh << 'EOFRUN'
#!/bin/bash -e

on_chroot << 'EOFCHROOT'
# Install Python packages
pip3 install --break-system-packages flask flask-cors requests psutil || \
    pip3 install flask flask-cors requests psutil

# Create directories
mkdir -p /usr/local/bin
mkdir -p /home/pi/.config/autostart

# Create GUI application
cat > /usr/local/bin/raspberry-pi-gui.py << 'EOFGUI'
#!/usr/bin/env python3
import sys
from PyQt5.QtWidgets import QApplication, QMainWindow, QLabel, QVBoxLayout, QWidget
from PyQt5.QtCore import QTimer, Qt
import psutil

class RaspberryPiGUI(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle('🍓 Raspberry Pi Custom OS')
        self.setGeometry(0, 0, 800, 480)
        
        # Main widget
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        layout = QVBoxLayout(central_widget)
        
        # Title
        title = QLabel('🍓 Raspberry Pi 3B Custom OS')
        title.setAlignment(Qt.AlignCenter)
        title.setStyleSheet('font-size: 24pt; font-weight: bold; color: #e91e63;')
        layout.addWidget(title)
        
        # System info
        self.cpu_label = QLabel('CPU: --')
        self.cpu_label.setStyleSheet('font-size: 16pt;')
        layout.addWidget(self.cpu_label)
        
        self.mem_label = QLabel('Memory: --')
        self.mem_label.setStyleSheet('font-size: 16pt;')
        layout.addWidget(self.mem_label)
        
        # Update timer
        self.timer = QTimer()
        self.timer.timeout.connect(self.update_stats)
        self.timer.start(2000)
        self.update_stats()
    
    def update_stats(self):
        cpu = psutil.cpu_percent(interval=1)
        mem = psutil.virtual_memory().percent
        self.cpu_label.setText(f'CPU: {cpu:.1f}%')
        self.mem_label.setText(f'Memory: {mem:.1f}%')

if __name__ == '__main__':
    app = QApplication(sys.argv)
    gui = RaspberryPiGUI()
    gui.show()
    sys.exit(app.exec_())
EOFGUI

chmod +x /usr/local/bin/raspberry-pi-gui.py

# Create autostart entry
cat > /home/pi/.config/autostart/custom-gui.desktop << 'EOFAUTO'
[Desktop Entry]
Type=Application
Name=Custom GUI
Exec=python3 /usr/local/bin/raspberry-pi-gui.py
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOFAUTO

chown -R 1000:1000 /home/pi/.config

# Configure auto-login for LightDM
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/01-autologin.conf << 'EOFLIGHTDM'
[Seat:*]
autologin-user=pi
autologin-user-timeout=0
EOFLIGHTDM

# Enable graphical boot
systemctl set-default graphical.target

# Enable services
systemctl enable ssh shairport-sync avahi-daemon smbd nginx lightdm

# Configure Samba
cat >> /etc/samba/smb.conf << 'EOFSAMBA'

[pi]
   path = /home/pi
   browseable = yes
   read only = no
   guest ok = no
EOFSAMBA

# Set Samba password (password: raspberry)
(echo "raspberry"; echo "raspberry") | smbpasswd -a pi -s 2>/dev/null || true

echo "✅ Custom OS configuration complete!"
EOFCHROOT
EOFRUN

chmod +x stage2/99-custom-packages/01-run.sh
log "✅ Custom scripts created"

step "6/8: Starting build process..."
info "This will take 30-60 minutes depending on your system"
info "Features being installed:"
info "  ✅ PyQt5 GUI Dashboard (auto-starts on boot)"
info "  ✅ Desktop environment (LXDE)"
info "  ✅ Auto-login as user 'pi'"
info "  ✅ AirPlay receiver"
info "  ✅ Samba file sharing"
info "  ✅ SSH enabled"
echo

# Run the build
sudo ./build.sh

step "7/8: Build complete!"
log "✅ Image created"

step "8/8: Locating and displaying results..."
if [ -d "deploy" ]; then
    IMAGE_FILE=$(find deploy -name "*.img" -o -name "*.zip" | head -1)
    if [ -n "$IMAGE_FILE" ]; then
        IMAGE_SIZE=$(du -h "$IMAGE_FILE" | cut -f1)
        
        echo
        log "🎉 SUCCESS! Your Custom Raspberry Pi OS is Ready!"
        log "================================================="
        echo
        info "Image location:"
        info "  $(pwd)/$IMAGE_FILE"
        info "  Size: $IMAGE_SIZE"
        echo
        info "To flash to SD card:"
        info "  1. Insert SD card (8GB minimum)"
        info "  2. Find device: lsblk"
        info "  3. Unmount: sudo umount /dev/sdX*"
        if [[ "$IMAGE_FILE" == *.zip ]]; then
            info "  4. Flash: unzip -p $IMAGE_FILE | sudo dd of=/dev/sdX bs=4M status=progress"
        else
            info "  4. Flash: sudo dd if=$IMAGE_FILE of=/dev/sdX bs=4M status=progress"
        fi
        info "  5. Sync: sync"
        echo
        info "Features included:"
        info "  ✅ PyQt5 GUI Dashboard (auto-starts on boot)"
        info "  ✅ Auto-login as user 'pi' (password: raspberry)"
        info "  ✅ Desktop environment (LXDE)"
        info "  ✅ AirPlay receiver"
        info "  ✅ File sharing (Samba)"
        info "  ✅ SSH enabled"
        info "  ✅ Web dashboard ready"
        echo
        log "🍓 Insert SD card into Raspberry Pi 3B and power on!"
    else
        error "No image file found in deploy directory"
    fi
else
    error "Build failed. Deploy directory not found"
fi

cd ..
log "Build script completed!"

