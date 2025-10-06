#!/bin/bash

# Install Custom OS Features on Raspberry Pi
# Run this on a fresh Raspberry Pi OS installation

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INSTALL]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Check if running on Raspberry Pi
if [ ! -f /proc/device-tree/model ]; then
    error "This script must be run on a Raspberry Pi"
fi

log "🍓 Installing Custom Raspberry Pi OS Features"
log "============================================="
echo

step "1/10: Updating system..."
sudo apt-get update
log "✅ System updated"

step "2/10: Installing desktop environment..."
sudo apt-get install -y xserver-xorg xinit lightdm lxde-core openbox pcmanfm lxterminal
log "✅ Desktop installed"

step "3/10: Installing Python and PyQt5..."
sudo apt-get install -y python3 python3-pip python3-pyqt5 python3-psutil
log "✅ Python and PyQt5 installed"

step "4/10: Installing wireless display services..."
sudo apt-get install -y shairport-sync avahi-daemon
log "✅ AirPlay installed"

step "5/10: Installing network services..."
sudo apt-get install -y samba nginx iw wireless-tools
log "✅ Network services installed"

step "6/10: Installing Python packages..."
sudo pip3 install flask flask-cors requests psutil
log "✅ Python packages installed"

step "7/10: Installing custom GUI..."
sudo mkdir -p /usr/local/bin
sudo cp overlays/usr/local/bin/raspberry-pi-gui.py /usr/local/bin/
sudo chmod +x /usr/local/bin/raspberry-pi-gui.py
log "✅ GUI installed"

step "8/10: Configuring auto-login..."
# Configure console auto-login
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo bash -c 'cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM
EOF'

# Configure desktop auto-login
sudo sed -i 's/#autologin-user=/autologin-user=pi/' /etc/lightdm/lightdm.conf
sudo sed -i 's/#autologin-user-timeout=0/autologin-user-timeout=0/' /etc/lightdm/lightdm.conf

log "✅ Auto-login configured"

step "9/10: Configuring GUI auto-start..."
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/custom-gui.desktop << EOF
[Desktop Entry]
Type=Application
Name=Custom GUI
Exec=python3 /usr/local/bin/raspberry-pi-gui.py
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

log "✅ GUI auto-start configured"

step "10/10: Enabling graphical boot..."
sudo systemctl set-default graphical.target
sudo systemctl enable lightdm

log "✅ Graphical boot enabled"

echo
log "🎉 Installation Complete!"
log "========================"
echo
info "Your Raspberry Pi is now configured with:"
info "  ✅ PyQt5 GUI Dashboard (auto-starts on boot)"
info "  ✅ Auto-login as user 'pi'"
info "  ✅ Desktop environment (LXDE)"
info "  ✅ AirPlay receiver service"
info "  ✅ Network services (Samba, SSH)"
echo
info "Please reboot your Raspberry Pi to see the changes:"
info "  sudo reboot"
echo
log "🍓 Enjoy your custom Raspberry Pi OS!"
