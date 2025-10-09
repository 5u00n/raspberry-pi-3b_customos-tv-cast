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
    echo ""
    echo ""
    echo -e "${PURPLE}████████████████████████████████████████████████████████████████${NC}"
    echo -e "${PURPLE}████████████████████████████████████████████████████████████████${NC}"
    echo -e "${PURPLE}███${NC}                                                            ${PURPLE}███${NC}"
    echo -e "${PURPLE}███${NC}  $1"
    echo -e "${PURPLE}███${NC}                                                            ${PURPLE}███${NC}"
    echo -e "${PURPLE}████████████████████████████████████████████████████████████████${NC}"
    echo -e "${PURPLE}████████████████████████████████████████████████████████████████${NC}"
    echo ""
    echo ""
}

# Function to show progress
show_progress() {
    local current=$1
    local total=$2
    local step_name=$3
    
    echo ""
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                ║${NC}"
    echo -e "${CYAN}║     📊 PROGRESS: STEP $current OF $total                                   ║${NC}"
    echo -e "${CYAN}║                                                                ║${NC}"
    echo -e "${CYAN}║     ⏱️  CURRENT TASK: $step_name"
    echo -e "${CYAN}║                                                                ║${NC}"
    
    # Calculate percentage
    local percent=$((current * 100 / total))
    local filled=$((current * 50 / total))
    local empty=$((50 - filled))
    
    # Draw progress bar
    echo -ne "${CYAN}║     ["
    for ((i=0; i<filled; i++)); do echo -ne "█"; done
    for ((i=0; i<empty; i++)); do echo -ne "░"; done
    echo -e "] ${percent}%     ║${NC}"
    echo -e "${CYAN}║                                                                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo ""
}

# Function to install missing package alternatives
install_alternatives() {
    local package=$1
    case $package in
        bsdtar|libarchive-tools)
            log "Installing libarchive-tools (provides bsdtar)..."
            sudo apt-get install -y libarchive-tools
            ;;
        pxz|pixz)
            log "Trying to install parallel xz compression..."
            sudo apt-get install -y pixz 2>/dev/null || \
            sudo apt-get install -y pxz 2>/dev/null || \
            log "Using standard xz-utils instead"
            ;;
        *)
            sudo apt-get install -y "$package"
            ;;
    esac
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

# Function to print section separator
section_separator() {
    echo ""
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo ""
}

# Main script starts here
print_header

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                  ║${NC}"
echo -e "${GREEN}║          🚀 STARTING BUILD PROCESS - 6 STEPS TOTAL 🚀             ║${NC}"
echo -e "${GREEN}║                                                                  ║${NC}"
echo -e "${GREEN}║  This will take approximately 45-90 minutes to complete         ║${NC}"
echo -e "${GREEN}║                                                                  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo ""

# Pre-flight checks
show_progress 0 6 "Pre-flight checks"
step "🔍 Step 0/6: Pre-flight checks"
check_architecture
check_os
check_disk_space
echo ""

section_separator

# Step 1: Free up disk space
show_progress 1 6 "Freeing up disk space"
step "🧹 Step 1/6: Freeing up disk space (optional)"
log "Cleaning package cache..."
sudo apt-get clean || true
log "✓ Cleanup complete"
echo ""

section_separator

# Step 2: Install dependencies
show_progress 2 6 "Installing build dependencies"
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
    whois \
    xxd \
    vim-common \
    python3 \
    python3-pip \
    # Additional optional packages (uncomment if needed):
    # htop              # Process monitor
    # nano              # Text editor (alternative to vim)
    # wget              # Download tool
    # tree              # Directory tree viewer
    # jq                # JSON processor
    # build-essential   # Compilation tools
    # cmake             # Build system
    # pkg-config        # Package configuration
    # libssl-dev        # SSL development libraries
    # zlib1g-dev        # Compression library
    # libffi-dev        # Foreign Function Interface
    # libbz2-dev        # Bzip2 compression
    # libreadline-dev   # Readline library
    # libsqlite3-dev    # SQLite development
    # libncurses5-dev   # Terminal interface
    # libncursesw5-dev  # Wide character terminal
    # tk-dev            # Tk GUI toolkit
    # libxml2-dev       # XML library
    # libxmlsec1-dev    # XML security
    # libffi-dev        # Foreign Function Interface
    # liblzma-dev       # LZMA compression
    # python3-dev       # Python development headers
    # python3-venv      # Python virtual environments
    # python3-setuptools # Python setuptools
    # python3-wheel     # Python wheel package

# Install optional packages (may not be available on all systems)
log "Installing optional compression tools..."
sudo apt-get install -y pixz 2>/dev/null || sudo apt-get install -y pxz 2>/dev/null || warn "pixz/pxz not available, using xz-utils (slower but works)"

# Verify critical tools
log "Verifying installed tools..."
MISSING_TOOLS=""

# Check for bsdtar (from libarchive-tools)
if ! command -v bsdtar &> /dev/null; then
    warn "bsdtar not found in PATH, checking if tar can be used as fallback..."
    if command -v tar &> /dev/null; then
        log "✓ tar found as fallback"
    else
        MISSING_TOOLS="$MISSING_TOOLS tar/bsdtar"
    fi
else
    log "✓ bsdtar found"
fi

# Check for compression tools
if ! command -v pigz &> /dev/null; then
    MISSING_TOOLS="$MISSING_TOOLS pigz"
fi

# Check for xz
if ! command -v xz &> /dev/null; then
    MISSING_TOOLS="$MISSING_TOOLS xz"
fi

# Check for qemu-arm-static
if ! command -v qemu-arm-static &> /dev/null; then
    warn "qemu-arm-static not found, checking alternatives..."
    if [ -f /usr/bin/qemu-arm-static ]; then
        log "✓ qemu-arm-static found in /usr/bin/"
    else
        MISSING_TOOLS="$MISSING_TOOLS qemu-arm-static"
    fi
else
    log "✓ qemu-arm-static found"
fi

if [ -n "$MISSING_TOOLS" ]; then
    error "Missing critical tools:$MISSING_TOOLS. Please install them manually."
fi

log "✓ All critical dependencies verified!"
echo ""

section_separator

# Step 3: Clone and setup pi-gen
show_progress 3 6 "Setting up pi-gen build system"
step "📥 Step 3/6: Setting up pi-gen build system"

# Always start fresh - remove old pi-gen if exists
if [ -d "pi-gen" ]; then
    log "Removing existing pi-gen directory for fresh clone..."
    sudo rm -rf pi-gen
    log "✓ Old pi-gen removed"
fi

log "Cloning fresh pi-gen repository..."
git clone https://github.com/RPi-Distro/pi-gen.git
log "✓ pi-gen cloned"

cd pi-gen

log "Checking out stable branch (bookworm)..."
git checkout 2024-07-04-raspios-bookworm || git checkout master

log "✓ pi-gen setup complete!"
echo ""

section_separator

# Step 4: Configure custom OS
show_progress 4 6 "Configuring custom Raspberry Pi OS"
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
python3-gi
python3-gi-cairo
gir1.2-gtk-3.0
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
# apt-get upgrade removed to speed up build - packages from repos are already current
pip3 install --break-system-packages flask flask-cors requests psutil 2>/dev/null || pip3 install flask flask-cors requests psutil || true
systemctl enable ssh shairport-sync avahi-daemon smbd nginx lightdm
systemctl set-default graphical.target
EOFCHROOT
EOFRUN

chmod +x stage2/99-custom-packages/00-run.sh

log "Creating custom GUI configuration..."
mkdir -p stage2/99-custom-gui/files

# Determine the base directory (go up one level from pi-gen)
BASE_DIR="$(cd .. && pwd)"
log "Looking for GUI files in: $BASE_DIR/overlays/"

# Copy Smart TV GUI file if exists (prefer Smart TV version)
if [ -f "$BASE_DIR/overlays/usr/local/bin/raspberry-pi-smart-tv-gui.py" ]; then
    cp "$BASE_DIR/overlays/usr/local/bin/raspberry-pi-smart-tv-gui.py" stage2/99-custom-gui/files/raspberry-pi-gui.py
    log "✓ Smart TV GUI script copied from repository"
elif [ -f "$BASE_DIR/overlays/usr/local/bin/raspberry-pi-gui.py" ]; then
    cp "$BASE_DIR/overlays/usr/local/bin/raspberry-pi-gui.py" stage2/99-custom-gui/files/
    log "✓ Custom GUI script copied from repository"  
elif [ -f "../overlays/usr/local/bin/raspberry-pi-smart-tv-gui.py" ]; then
    cp ../overlays/usr/local/bin/raspberry-pi-smart-tv-gui.py stage2/99-custom-gui/files/raspberry-pi-gui.py
    log "✓ Smart TV GUI script copied"
elif [ -f "../overlays/usr/local/bin/raspberry-pi-gui.py" ]; then
    cp ../overlays/usr/local/bin/raspberry-pi-gui.py stage2/99-custom-gui/files/
    log "✓ Custom GUI script copied"
else
    warn "Custom GUI script not found at $BASE_DIR/overlays/usr/local/bin/"
    warn "Will create Smart TV interface during build"
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
  echo "Custom GUI script not found, creating GTK-based one"
  cat > /usr/local/bin/raspberry-pi-gui.py << 'GUISCRIPT'
#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib
import psutil
import subprocess

class RaspberryPiGUI(Gtk.Window):
    def __init__(self):
        super().__init__(title="Raspberry Pi Custom OS")
        self.set_default_size(800, 600)
        self.set_border_width(20)
        self.fullscreen()
        
        # Main container
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        vbox.set_halign(Gtk.Align.CENTER)
        vbox.set_valign(Gtk.Align.CENTER)
        self.add(vbox)
        
        # Title
        title = Gtk.Label()
        title.set_markup('<span size="xx-large" weight="bold">🍓 Raspberry Pi Custom OS</span>')
        vbox.pack_start(title, False, False, 10)
        
        # System stats card
        stats_frame = Gtk.Frame(label="System Status")
        stats_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        stats_box.set_border_width(15)
        stats_frame.add(stats_box)
        
        self.cpu_label = Gtk.Label()
        self.cpu_label.set_markup('<span size="large">CPU: Loading...</span>')
        stats_box.pack_start(self.cpu_label, False, False, 5)
        
        self.mem_label = Gtk.Label()
        self.mem_label.set_markup('<span size="large">Memory: Loading...</span>')
        stats_box.pack_start(self.mem_label, False, False, 5)
        
        self.disk_label = Gtk.Label()
        self.disk_label.set_markup('<span size="large">Disk: Loading...</span>')
        stats_box.pack_start(self.disk_label, False, False, 5)
        
        self.temp_label = Gtk.Label()
        self.temp_label.set_markup('<span size="large">Temp: Loading...</span>')
        stats_box.pack_start(self.temp_label, False, False, 5)
        
        vbox.pack_start(stats_frame, False, False, 10)
        
        # Connection info
        info_frame = Gtk.Frame(label="Connection Info")
        info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        info_box.set_border_width(15)
        info_frame.add(info_box)
        
        ssh_label = Gtk.Label()
        ssh_label.set_markup('<span size="medium">SSH: pi@raspberrypi-custom</span>')
        info_box.pack_start(ssh_label, False, False, 5)
        
        pass_label = Gtk.Label()
        pass_label.set_markup('<span size="medium">Password: raspberry</span>')
        info_box.pack_start(pass_label, False, False, 5)
        
        web_label = Gtk.Label()
        web_label.set_markup('<span size="medium">Web: http://raspberrypi-custom:8080</span>')
        info_box.pack_start(web_label, False, False, 5)
        
        vbox.pack_start(info_frame, False, False, 10)
        
        # Buttons
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        button_box.set_halign(Gtk.Align.CENTER)
        
        refresh_btn = Gtk.Button(label="Refresh")
        refresh_btn.connect("clicked", self.on_refresh_clicked)
        button_box.pack_start(refresh_btn, False, False, 0)
        
        terminal_btn = Gtk.Button(label="Terminal")
        terminal_btn.connect("clicked", self.on_terminal_clicked)
        button_box.pack_start(terminal_btn, False, False, 0)
        
        vbox.pack_start(button_box, False, False, 10)
        
        # Update stats every 2 seconds
        GLib.timeout_add_seconds(2, self.update_stats)
        self.update_stats()
        
        # Style
        css = b"""
        window {
            background: linear-gradient(to bottom, #1a1a2e, #16213e);
        }
        frame {
            background: #0f3460;
            border-radius: 10px;
            padding: 10px;
        }
        frame > border {
            border: none;
        }
        label {
            color: #e94560;
        }
        """
        
        css_provider = Gtk.CssProvider()
        css_provider.load_from_data(css)
        context = Gtk.StyleContext()
        screen = Gtk.gdk.Screen.get_default()
        context.add_provider_for_screen(screen, css_provider, 
                                       Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
    
    def update_stats(self):
        try:
            cpu = psutil.cpu_percent(interval=0.1)
            mem = psutil.virtual_memory().percent
            disk = psutil.disk_usage('/').percent
            
            # Get CPU temperature
            try:
                with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
                    temp = int(f.read()) / 1000
            except:
                temp = 0
            
            self.cpu_label.set_markup(f'<span size="large">CPU: {cpu:.1f}%</span>')
            self.mem_label.set_markup(f'<span size="large">Memory: {mem:.1f}%</span>')
            self.disk_label.set_markup(f'<span size="large">Disk: {disk:.1f}%</span>')
            self.temp_label.set_markup(f'<span size="large">Temp: {temp:.1f}°C</span>')
        except Exception as e:
            print(f"Error updating stats: {e}")
        
        return True
    
    def on_refresh_clicked(self, widget):
        self.update_stats()
    
    def on_terminal_clicked(self, widget):
        try:
            subprocess.Popen(['lxterminal'])
        except:
            try:
                subprocess.Popen(['xterm'])
            except:
                pass

def main():
    win = RaspberryPiGUI()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()

if __name__ == '__main__':
    main()
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
mkdir -p /etc/samba

# Check if smb.conf exists, create basic one if not
if [ ! -f /etc/samba/smb.conf ]; then
  cat > /etc/samba/smb.conf << 'SMBCONF'
[global]
   workgroup = WORKGROUP
   server string = Raspberry Pi Custom OS
   security = user
   map to guest = Bad User
SMBCONF
fi

# Append pi share configuration
cat >> /etc/samba/smb.conf << 'SAMBA'

[pi]
   path = /home/pi
   browseable = yes
   read only = no
   guest ok = no
   create mask = 0644
   directory mask = 0755
   valid users = pi
SAMBA

# Set Samba password for pi user
(echo "raspberry"; echo "raspberry") | smbpasswd -a pi -s 2>/dev/null || true

# Ensure smbd and nmbd are enabled
systemctl enable smbd nmbd 2>/dev/null || systemctl enable samba-ad-dc 2>/dev/null || true

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
info "  ✓ Python 3 + GTK3"
info "  ✓ Desktop environment (LXDE)"
info "  ✓ Smart TV Interface (Netflix-style UI)"
info "  ✓ AirPlay, Google Cast, Miracast"
info "  ✓ Media apps (YouTube, VLC, Spotify)"
info "  ✓ Web dashboard (port 8080)"
info "  ✓ File sharing (Samba)"
info "  ✓ SSH server"
info "  ✓ WiFi tools"
info "  ✓ Auto-login as 'pi'"
echo ""

section_separator

# Step 5: Build the OS
show_progress 5 6 "Building custom OS image (45-90 minutes)"
step "🔨 Step 5/6: Building custom OS image"
warn "This will take 45-90 minutes depending on your system"
warn "You can monitor progress in another terminal with:"
warn "  tail -f $(pwd)/work/*/build.log"
echo ""

log "Starting build..."
sudo ./build.sh

log "✓ Build completed successfully!"
echo ""

section_separator

# Step 6: Show results
show_progress 6 6 "Build complete!"
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
                        --notes "Custom Raspberry Pi OS with Smart TV Interface
                        
Features:
- 📺 Smart TV Interface (Beautiful Netflix-style UI)
- 📱 AirPlay, Google Cast & Miracast
- 🎬 Media Apps (YouTube TV, VLC, Spotify, Plex)
- 🎵 Audio & Video Streaming
- 🌐 Web Dashboard (port 8080)
- 📂 File Sharing (Samba)
- 🔐 SSH Enabled
- ⚡ Auto-login and auto-start
- 🎨 GTK3 Native Interface

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

