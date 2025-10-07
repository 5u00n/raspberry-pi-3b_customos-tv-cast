#!/bin/bash
#
# Build Custom Raspberry Pi OS in Debian VM
# Run this script INSIDE your Debian VM
#

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     🍓 Building Custom Raspberry Pi OS in Debian VM           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo

# Step 1: Install dependencies
echo "📦 Step 1/5: Installing dependencies..."
sudo apt-get update
sudo apt-get install -y \
    coreutils quilt parted qemu-user-static debootstrap zerofree zip \
    dosfstools libarchive-tools libcap2-bin grep rsync xz-utils file \
    git curl bc qemu-utils kpartx arch-test

echo "✅ Dependencies installed!"
echo

# Step 2: Clone pi-gen
echo "📥 Step 2/5: Cloning pi-gen..."
if [ -d "pi-gen" ]; then
    echo "Removing old pi-gen..."
    sudo rm -rf pi-gen
fi

git clone https://github.com/RPi-Distro/pi-gen.git
cd pi-gen

# Checkout bookworm-compatible branch
git checkout 2024-07-04-raspios-bookworm || git checkout master

echo "✅ pi-gen cloned!"
echo

# Step 3: Configure pi-gen
echo "⚙️  Step 3/5: Configuring custom OS..."

# Clean previous builds
sudo rm -rf work deploy

# Create config file
cat > config << 'EOF'
IMG_NAME='CustomRaspberryPi3B'
RELEASE=bookworm
DEPLOY_COMPRESSION=zip
ENABLE_SSH=1
STAGE_LIST="stage0 stage1 stage2 stage3"
TARGET_HOSTNAME=raspberrypi-custom
FIRST_USER_NAME=pi
FIRST_USER_PASS=raspberry
DISABLE_FIRST_BOOT_USER_RENAME=1
DEPLOY_ZIP=1
EOF

# Create stage3 with custom packages
sudo rm -rf stage3
mkdir -p stage3/00-install-packages
mkdir -p stage3/01-custom-gui/files

# Package list
cat > stage3/00-install-packages/00-packages << 'EOFPKG'
python3
python3-pip
python3-pyqt5
python3-psutil
xserver-xorg
xinit
lightdm
lxde-core
openbox
pcmanfm
lxterminal
shairport-sync
avahi-daemon
samba
nginx
iw
wireless-tools
chromium-browser
EOFPKG

# Install script
cat > stage3/00-install-packages/00-run.sh << 'EOFRUN'
#!/bin/bash -e
on_chroot << EOFCHROOT
apt-get update
apt-get upgrade -y
pip3 install --break-system-packages flask flask-cors requests psutil || pip3 install flask flask-cors requests psutil
systemctl enable ssh shairport-sync avahi-daemon smbd nginx lightdm
systemctl set-default graphical.target
EOFCHROOT
EOFRUN

chmod +x stage3/00-install-packages/00-run.sh

# Copy GUI file
if [ -f "../overlays/usr/local/bin/raspberry-pi-gui.py" ]; then
    cp ../overlays/usr/local/bin/raspberry-pi-gui.py stage3/01-custom-gui/files/
    echo "✅ GUI file copied"
fi

# GUI setup script
cat > stage3/01-custom-gui/00-run.sh << 'EOFGUI'
#!/bin/bash -e
on_chroot << EOFCHROOT
mkdir -p /usr/local/bin
mkdir -p /home/pi/.config/autostart

# Copy GUI if exists
if [ -f "/tmp/raspberry-pi-gui.py" ]; then
    cp /tmp/raspberry-pi-gui.py /usr/local/bin/
    chmod +x /usr/local/bin/raspberry-pi-gui.py
fi

# Configure auto-login
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'AUTOLOGIN'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM
AUTOLOGIN

mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/01-autologin.conf << 'LIGHTDM'
[Seat:*]
autologin-user=pi
autologin-user-timeout=0
LIGHTDM

# Create autostart for GUI
cat > /home/pi/.config/autostart/custom-gui.desktop << 'AUTOSTART'
[Desktop Entry]
Type=Application
Name=Custom GUI
Exec=python3 /usr/local/bin/raspberry-pi-gui.py
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
AUTOSTART

# Configure Samba
cat >> /etc/samba/smb.conf << 'SAMBA'

[pi]
   path = /home/pi
   browseable = yes
   read only = no
   guest ok = no
SAMBA

(echo "raspberry"; echo "raspberry") | smbpasswd -a pi -s || true

chown -R 1000:1000 /home/pi/.config || true
EOFCHROOT
EOFGUI

chmod +x stage3/01-custom-gui/00-run.sh

# Mark stage3 for export
touch stage3/EXPORT_IMAGE

echo "✅ Configuration complete!"
echo

# Step 4: Build the OS
echo "🔨 Step 4/5: Building custom OS (this takes 45-60 minutes)..."
echo "You can monitor progress in another terminal with:"
echo "  tail -f pi-gen/work/*/build.log"
echo

sudo ./build.sh

echo "✅ Build complete!"
echo

# Step 5: Show results
echo "📦 Step 5/5: Build artifacts:"
ls -lh deploy/

echo
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                ✅ BUILD COMPLETE!                              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo
echo "📥 Your custom OS image is ready:"
echo "   Location: pi-gen/deploy/"
echo
ls -lh deploy/*.zip deploy/*.img 2>/dev/null || true
echo
echo "🔧 Next steps:"
echo "   1. Copy the .img or .zip file to your Mac"
echo "   2. Flash to your 64GB USB drive"
echo "   3. Boot your Raspberry Pi!"
echo
echo "Default credentials:"
echo "   Username: pi"
echo "   Password: raspberry"
echo "   Hostname: raspberrypi-custom"
echo

