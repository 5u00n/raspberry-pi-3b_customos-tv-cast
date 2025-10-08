#!/bin/bash
#
# Build Custom Raspberry Pi OS on Debian AMD64 Machine
# Compatible with: Debian 11/12, Ubuntu 20.04/22.04/24.04
#
# Usage: ./BUILD-DEBIAN-AMD64.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║     🍓 Custom Raspberry Pi OS Builder for Debian AMD64        ║"
    echo "║        Builds a complete custom OS with all features          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

step() {
    echo -e "${BLUE}▶${NC} $1"
    echo ""
}

# Check if running on correct architecture
check_architecture() {
    ARCH=$(uname -m)
    if [ "$ARCH" != "x86_64" ]; then
        error "This script is designed for AMD64/x86_64 architecture. Detected: $ARCH"
    fi
    log "✓ Architecture check passed: $ARCH"
}

# Check if running on Debian/Ubuntu
check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "debian" && "$ID" != "ubuntu" ]]; then
            warn "This script is designed for Debian/Ubuntu. Detected: $ID"
            warn "Continuing anyway, but some issues may occur..."
        else
            log "✓ OS check passed: $PRETTY_NAME"
        fi
    fi
}

# Check available disk space
check_disk_space() {
    AVAILABLE=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
    if [ "$AVAILABLE" -lt 20 ]; then
        error "Insufficient disk space. Need at least 20GB, available: ${AVAILABLE}GB"
    fi
    log "✓ Disk space check passed: ${AVAILABLE}GB available"
}

# Main script starts here
print_header

log "Starting build process..."
echo ""

# Pre-flight checks
step "🔍 Step 0/6: Pre-flight checks"
check_architecture
check_os
check_disk_space
echo ""

# Step 1: Free up disk space
step "🧹 Step 1/6: Freeing up disk space (optional)"
log "Cleaning package cache..."
sudo apt-get clean || true
log "✓ Cleanup complete"
echo ""

# Step 2: Install dependencies
step "📦 Step 2/6: Installing build dependencies"
log "This may take 5-10 minutes depending on your internet connection..."

sudo apt-get update

log "Installing required packages..."
sudo apt-get install -y \
    pigz \
    coreutils \
    quilt \
    parted \
    qemu-user-static \
    debootstrap \
    zerofree \
    zip \
    unzip \
    dosfstools \
    libarchive-tools \
    libcap2-bin \
    grep \
    rsync \
    xz-utils \
    file \
    git \
    curl \
    bc \
    qemu-utils \
    kpartx \
    arch-test \
    binfmt-support \
    fdisk \
    gpg \
    e2fsprogs \
    bsdtar \
    pxz \
    whois \
    python3 \
    python3-pip

log "✓ All dependencies installed successfully!"
echo ""

# Step 3: Clone and setup pi-gen
step "📥 Step 3/6: Setting up pi-gen build system"

if [ -d "pi-gen" ]; then
    warn "pi-gen directory already exists"
    read -p "Do you want to remove it and clone fresh? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Removing old pi-gen..."
        sudo rm -rf pi-gen
    else
        error "Build cancelled. Please remove pi-gen directory manually or choose 'y' to remove."
    fi
fi

log "Cloning pi-gen repository..."
git clone https://github.com/RPi-Distro/pi-gen.git
cd pi-gen

log "Checking out stable branch (bookworm)..."
git checkout 2024-07-04-raspios-bookworm || git checkout master

log "✓ pi-gen setup complete!"
echo ""

# Step 4: Configure custom OS
step "⚙️  Step 4/6: Configuring custom Raspberry Pi OS"

log "Cleaning previous builds..."
sudo rm -rf work deploy

log "Creating build configuration..."
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

log "Creating custom package installation stage..."
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

# WiFi and networking
iw
wireless-tools
hostapd
dnsmasq
wpasupplicant
net-tools
iputils-ping
curl
wget

# Web browsers and media
chromium-browser
firefox-esr

# Additional casting/streaming packages
vlc
ffmpeg
youtube-dl
nodejs
npm

# System utilities
htop
nano
vim
git
unzip
zip
EOFPKG

log "Creating package installation script..."
cat > stage2/99-custom-packages/00-run.sh << 'EOFRUN'
#!/bin/bash -e
on_chroot << EOFCHROOT
apt-get update
apt-get upgrade -y
pip3 install --break-system-packages flask flask-cors requests psutil || pip3 install flask flask-cors requests psutil
systemctl enable ssh shairport-sync avahi-daemon smbd nginx lightdm
systemctl set-default graphical.target
EOFCHROOT
EOFRUN

chmod +x stage2/99-custom-packages/00-run.sh

log "Creating custom GUI configuration..."
mkdir -p stage2/99-custom-gui/files

# Copy GUI file if exists
if [ -f "../overlays/usr/local/bin/raspberry-pi-gui.py" ]; then
    cp ../overlays/usr/local/bin/raspberry-pi-gui.py stage2/99-custom-gui/files/
    log "✓ Custom GUI script copied"
else
    warn "Custom GUI script not found, will create basic version during build"
fi

cat > stage2/99-custom-gui/00-run.sh << 'EOFGUI'
#!/bin/bash -e
on_chroot << EOFCHROOT
mkdir -p /usr/local/bin
mkdir -p /home/pi/.config/autostart

# Install GUI script if it exists
if [ -f "/tmp/files/raspberry-pi-gui.py" ]; then
  install -m 755 /tmp/files/raspberry-pi-gui.py /usr/local/bin/
  echo "Custom GUI script installed"
else
  echo "Custom GUI script not found, creating basic one"
  cat > /usr/local/bin/raspberry-pi-gui.py << 'GUISCRIPT'
#!/usr/bin/env python3
import sys
from PyQt5.QtWidgets import QApplication, QWidget, QVBoxLayout, QLabel, QPushButton
from PyQt5.QtCore import Qt, QTimer
from PyQt5.QtGui import QFont
import psutil

class SimpleGUI(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Raspberry Pi Custom OS")
        self.setGeometry(100, 100, 800, 600)
        self.setWindowState(Qt.WindowFullScreen)
        self.initUI()
    
    def initUI(self):
        layout = QVBoxLayout()
        
        title = QLabel("🍓 Raspberry Pi Custom OS")
        title.setAlignment(Qt.AlignCenter)
        title.setFont(QFont("Arial", 24))
        layout.addWidget(title)
        
        self.cpu_label = QLabel("CPU: Loading...")
        self.cpu_label.setAlignment(Qt.AlignCenter)
        self.cpu_label.setFont(QFont("Arial", 16))
        layout.addWidget(self.cpu_label)
        
        self.mem_label = QLabel("Memory: Loading...")
        self.mem_label.setAlignment(Qt.AlignCenter)
        self.mem_label.setFont(QFont("Arial", 16))
        layout.addWidget(self.mem_label)
        
        info = QLabel("SSH: pi@raspberrypi-custom\nPassword: raspberry")
        info.setAlignment(Qt.AlignCenter)
        info.setFont(QFont("Arial", 14))
        layout.addWidget(info)
        
        self.setLayout(layout)
        
        # Update stats every 2 seconds
        self.timer = QTimer()
        self.timer.timeout.connect(self.update_stats)
        self.timer.start(2000)
        self.update_stats()
    
    def update_stats(self):
        cpu = psutil.cpu_percent(interval=0.1)
        mem = psutil.virtual_memory().percent
        self.cpu_label.setText(f"CPU: {cpu}%")
        self.mem_label.setText(f"Memory: {mem}%")

if __name__ == '__main__':
    app = QApplication(sys.argv)
    gui = SimpleGUI()
    gui.show()
    sys.exit(app.exec_())
GUISCRIPT
  chmod +x /usr/local/bin/raspberry-pi-gui.py
fi

# Create autostart desktop entry
cat > /home/pi/.config/autostart/custom-gui.desktop << 'AUTOSTART'
[Desktop Entry]
Type=Application
Name=Custom GUI
Exec=python3 /usr/local/bin/raspberry-pi-gui.py
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
AUTOSTART

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

chmod +x stage2/99-custom-gui/00-run.sh

log "Creating web dashboard service..."
mkdir -p stage2/99-web-dashboard/files

cat > stage2/99-web-dashboard/files/web-dashboard.py << 'WEBDASH'
#!/usr/bin/env python3
from flask import Flask, render_template_string, jsonify
import subprocess
import psutil

app = Flask(__name__)

@app.route('/')
def dashboard():
    return render_template_string('''
<!DOCTYPE html>
<html>
<head>
    <title>Raspberry Pi Dashboard</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial; background: #1a1a1a; color: #fff; margin: 0; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; }
        .card { background: #2d2d2d; padding: 20px; margin: 10px 0; border-radius: 8px; }
        h1 { text-align: center; color: #4CAF50; }
        .status { padding: 5px 10px; border-radius: 4px; margin: 5px; display: inline-block; }
        .running { background: #4CAF50; }
        .stopped { background: #f44336; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🍓 Raspberry Pi Custom OS Dashboard</h1>
        <div class="card">
            <h2>System Status</h2>
            <p>CPU: <span id="cpu">Loading...</span></p>
            <p>Memory: <span id="memory">Loading...</span></p>
            <p>Disk: <span id="disk">Loading...</span></p>
        </div>
        <div class="card">
            <h2>Services</h2>
            <div id="services">Loading...</div>
        </div>
    </div>
    <script>
        function updateStatus() {
            fetch('/api/status')
                .then(r => r.json())
                .then(d => {
                    document.getElementById('cpu').textContent = d.cpu + '%';
                    document.getElementById('memory').textContent = d.memory + '%';
                    document.getElementById('disk').textContent = d.disk + '%';
                });
        }
        setInterval(updateStatus, 2000);
        updateStatus();
    </script>
</body>
</html>
''')

@app.route('/api/status')
def api_status():
    return jsonify({
        'cpu': psutil.cpu_percent(),
        'memory': psutil.virtual_memory().percent,
        'disk': psutil.disk_usage('/').percent
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
WEBDASH

cat > stage2/99-web-dashboard/00-run.sh << 'WEBRUN'
#!/bin/bash -e
on_chroot << EOFCHROOT
install -m 755 /tmp/files/web-dashboard.py /usr/local/bin/

cat > /etc/systemd/system/web-dashboard.service << 'WEBSERVICE'
[Unit]
Description=Web Dashboard
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi
ExecStart=/usr/bin/python3 /usr/local/bin/web-dashboard.py
Restart=always

[Install]
WantedBy=multi-user.target
WEBSERVICE

systemctl enable web-dashboard.service
EOFCHROOT
WEBRUN

chmod +x stage2/99-web-dashboard/00-run.sh

log "✓ Configuration complete!"
echo ""

info "Build will include:"
info "  ✓ Python 3 + PyQt5"
info "  ✓ Desktop environment (LXDE)"
info "  ✓ Custom GUI dashboard"
info "  ✓ AirPlay receiver (shairport-sync)"
info "  ✓ Web dashboard (port 8080)"
info "  ✓ File sharing (Samba)"
info "  ✓ SSH server"
info "  ✓ WiFi tools"
info "  ✓ Auto-login as 'pi'"
echo ""

# Step 5: Build the OS
step "🔨 Step 5/6: Building custom OS image"
warn "This will take 45-90 minutes depending on your system"
warn "You can monitor progress in another terminal with:"
warn "  tail -f $(pwd)/work/*/build.log"
echo ""

log "Starting build..."
sudo ./build.sh

log "✓ Build completed successfully!"
echo ""

# Step 6: Show results
step "📦 Step 6/6: Build complete!"

cd deploy
sudo chown -R $USER:$USER .

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ✅ BUILD SUCCESSFUL!                        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

log "Build artifacts:"
ls -lh *.img *.zip 2>/dev/null || ls -lh

IMG_FILE=$(ls -t *.img 2>/dev/null | head -1)
ZIP_FILE=$(ls -t *.zip 2>/dev/null | head -1)

if [ -n "$IMG_FILE" ]; then
    IMG_SIZE=$(du -h "$IMG_FILE" | cut -f1)
    echo ""
    info "Image file: $IMG_FILE ($IMG_SIZE)"
fi

if [ -n "$ZIP_FILE" ]; then
    ZIP_SIZE=$(du -h "$ZIP_FILE" | cut -f1)
    info "Compressed: $ZIP_FILE ($ZIP_SIZE)"
fi

echo ""
echo -e "${CYAN}📝 Default Credentials:${NC}"
echo "   Username: pi"
echo "   Password: raspberry"
echo "   Hostname: raspberrypi-custom"
echo ""

echo -e "${CYAN}🔧 Flash to SD card:${NC}"
echo "   1. Insert SD card (8GB+ recommended)"
echo "   2. Find device: lsblk"
echo "   3. Unmount: sudo umount /dev/sdX*"
echo "   4. Flash: sudo dd if=$IMG_FILE of=/dev/sdX bs=4M status=progress conv=fsync"
echo "   5. Sync: sync"
echo "   6. Eject: sudo eject /dev/sdX"
echo ""

echo -e "${CYAN}🌐 After booting:${NC}"
echo "   • SSH: ssh pi@raspberrypi-custom"
echo "   • Web Dashboard: http://raspberrypi-custom:8080"
echo "   • File Sharing: smb://raspberrypi-custom/pi"
echo ""

echo -e "${GREEN}🍓 Your custom Raspberry Pi OS is ready!${NC}"
echo ""

# Ask if user wants to upload
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
read -p "Would you like to upload the image? (y/N): " -n 1 -r
echo
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}📤 Upload Options:${NC}"
    echo "1. Transfer.sh (Quick temporary upload - 14 days)"
    echo "2. GitHub Release (Permanent, requires gh CLI)"
    echo "3. Copy to remote server (via scp)"
    echo "4. Skip upload"
    echo ""
    read -p "Select option (1-4): " UPLOAD_CHOICE
    
    case $UPLOAD_CHOICE in
        1)
            # Upload to transfer.sh
            echo ""
            log "Uploading to transfer.sh..."
            if [ -n "$ZIP_FILE" ]; then
                UPLOAD_FILE="$ZIP_FILE"
            else
                UPLOAD_FILE="$IMG_FILE"
            fi
            
            log "Uploading $UPLOAD_FILE (this may take several minutes)..."
            DOWNLOAD_URL=$(curl --upload-file "$UPLOAD_FILE" "https://transfer.sh/$UPLOAD_FILE" 2>/dev/null)
            
            if [ -n "$DOWNLOAD_URL" ]; then
                echo ""
                echo -e "${GREEN}✅ Upload successful!${NC}"
                echo ""
                echo -e "${CYAN}Download URL (valid for 14 days):${NC}"
                echo "$DOWNLOAD_URL"
                echo ""
                echo "Save this URL! You can download with:"
                echo "  wget $DOWNLOAD_URL"
                echo "  or"
                echo "  curl -O $DOWNLOAD_URL"
                echo ""
                
                # Save URL to file
                echo "$DOWNLOAD_URL" > transfer-url.txt
                log "URL saved to: $(pwd)/transfer-url.txt"
            else
                error "Upload failed. Check your internet connection."
            fi
            ;;
            
        2)
            # Upload to GitHub Release
            echo ""
            log "Preparing GitHub Release upload..."
            
            # Check if gh CLI is installed
            if ! command -v gh &> /dev/null; then
                echo ""
                warn "GitHub CLI (gh) is not installed."
                echo ""
                echo "Install it with:"
                echo "  Debian/Ubuntu: sudo apt install gh"
                echo "  Or: curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
                echo "       echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null"
                echo "       sudo apt update && sudo apt install gh"
                echo ""
                read -p "Install now? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    log "Installing GitHub CLI..."
                    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
                    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                    sudo apt update
                    sudo apt install -y gh
                    log "✓ GitHub CLI installed"
                else
                    warn "Skipping GitHub upload."
                fi
            fi
            
            if command -v gh &> /dev/null; then
                echo ""
                log "Authenticating with GitHub..."
                gh auth status || gh auth login
                
                echo ""
                read -p "Enter release tag (e.g., v1.0.0): " RELEASE_TAG
                read -p "Enter release title (e.g., Custom Pi OS v1.0.0): " RELEASE_TITLE
                
                log "Creating GitHub release..."
                
                if [ -n "$ZIP_FILE" ]; then
                    gh release create "$RELEASE_TAG" "$ZIP_FILE" \
                        --title "$RELEASE_TITLE" \
                        --notes "Custom Raspberry Pi OS Image
                        
Features:
- Desktop Environment (LXDE)
- PyQt5 GUI Dashboard
- AirPlay Receiver
- Web Dashboard (port 8080)
- File Sharing (Samba)
- SSH Enabled
- Auto-login as 'pi'

Default Credentials:
- Username: pi
- Password: raspberry
- Hostname: raspberrypi-custom

Flash with:
\`\`\`
sudo dd if=CustomRaspberryPi3B.img of=/dev/sdX bs=4M status=progress
\`\`\`"
                    
                    echo ""
                    echo -e "${GREEN}✅ Release created successfully!${NC}"
                    echo "View at: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/releases"
                else
                    warn "ZIP file not found. Upload manually."
                fi
            fi
            ;;
            
        3)
            # Upload via SCP
            echo ""
            log "Upload to remote server via SCP..."
            echo ""
            read -p "Enter remote server (user@hostname): " REMOTE_SERVER
            read -p "Enter remote path (e.g., /home/user/): " REMOTE_PATH
            
            if [ -n "$ZIP_FILE" ]; then
                UPLOAD_FILE="$ZIP_FILE"
            else
                UPLOAD_FILE="$IMG_FILE"
            fi
            
            log "Uploading $UPLOAD_FILE to $REMOTE_SERVER:$REMOTE_PATH"
            log "This may take several minutes..."
            
            scp "$UPLOAD_FILE" "$REMOTE_SERVER:$REMOTE_PATH"
            
            if [ $? -eq 0 ]; then
                echo ""
                echo -e "${GREEN}✅ Upload successful!${NC}"
                echo "File uploaded to: $REMOTE_SERVER:$REMOTE_PATH$UPLOAD_FILE"
            else
                error "Upload failed. Check your SSH connection."
            fi
            ;;
            
        4)
            log "Skipping upload."
            ;;
            
        *)
            warn "Invalid option. Skipping upload."
            ;;
    esac
    
    echo ""
fi

echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}All done! 🎉${NC}"
echo ""

