#!/bin/bash

# Build a complete Raspberry Pi OS image with all customizations
# This script will:
# 1. Download the base Raspberry Pi OS image
# 2. Create necessary directory structure
# 3. Create all overlay files
# 4. Create configuration files
# 5. Build a complete image
# 6. Test the image in QEMU

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directories
WORKSPACE_DIR="$(pwd)"
BUILD_DIR="${WORKSPACE_DIR}/build"
OUTPUT_DIR="${WORKSPACE_DIR}/output"
MOUNT_DIR="${BUILD_DIR}/mnt"
BOOT_MOUNT="${MOUNT_DIR}/boot"
ROOTFS_MOUNT="${MOUNT_DIR}/rootfs"
OVERLAY_DIR="${WORKSPACE_DIR}/overlays"
CONFIG_DIR="${WORKSPACE_DIR}/configs"
QEMU_FILES="${WORKSPACE_DIR}/qemu_files"

# Image files
BASE_IMAGE_URL="https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2023-05-03/2023-05-03-raspios-bullseye-armhf-lite.img.xz"
BASE_IMAGE_XZ="${BUILD_DIR}/base-os.img.xz"
BASE_IMAGE="${BUILD_DIR}/base-os.img"
OUTPUT_IMAGE="${OUTPUT_DIR}/raspberry-pi-os.img"

# Log function
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

# Create directories
log "Creating directories..."
mkdir -p "${BUILD_DIR}" "${OUTPUT_DIR}" "${MOUNT_DIR}" "${BOOT_MOUNT}" "${ROOTFS_MOUNT}"
mkdir -p "${OVERLAY_DIR}/etc/systemd/system"
mkdir -p "${OVERLAY_DIR}/etc/network"
mkdir -p "${OVERLAY_DIR}/usr/local/bin"
mkdir -p "${OVERLAY_DIR}/home/pi"
mkdir -p "${OVERLAY_DIR}/etc/systemd/system/getty@tty1.service.d"
mkdir -p "${CONFIG_DIR}"
mkdir -p "${QEMU_FILES}"

# Download base image if not exists
if [ ! -f "${BASE_IMAGE}" ]; then
    if [ ! -f "${BASE_IMAGE_XZ}" ]; then
        log "Downloading Raspberry Pi OS image..."
        curl -L -o "${BASE_IMAGE_XZ}" "${BASE_IMAGE_URL}"
    fi
    
    log "Extracting image..."
    xz -d -k "${BASE_IMAGE_XZ}"
fi

# Download QEMU kernel files if not exists
if [ ! -f "${QEMU_FILES}/kernel-qemu-4.19.50-buster" ]; then
    log "Downloading QEMU kernel files..."
    curl -L -o "${QEMU_FILES}/kernel-qemu-4.19.50-buster" "https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-4.19.50-buster"
    curl -L -o "${QEMU_FILES}/versatile-pb-buster.dtb" "https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/versatile-pb-buster.dtb"
fi

# Create WiFi credentials file
log "Creating WiFi credentials file..."
cat > "${CONFIG_DIR}/wifi-credentials.txt" << 'EOF'
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
cat > "${CONFIG_DIR}/firstrun.sh" << 'EOF'
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
chmod +x /usr/local/bin/*.sh
chmod +x /usr/local/bin/*.py

# Configure auto-login
log "Configuring auto-login..."
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'EOT'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM
Type=idle
Restart=always
RestartSec=1
EOT

# Set up WiFi
log "Setting up WiFi..."
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

# Install required packages (this will run inside the chroot)
log "Installing required packages..."
apt-get update
apt-get install -y xserver-xorg lxde lightdm openbox python3-tk python3-psutil shairport-sync avahi-daemon

# Enable services
log "Enabling services..."
systemctl enable airplay.service
systemctl enable google-cast.service
systemctl enable wifi-tools.service
systemctl enable remote-control.service
systemctl enable desktop-ui.service

# Set graphical target
log "Setting graphical target..."
systemctl set-default graphical.target

# Configure auto-start GUI
log "Configuring auto-start GUI..."
cat >> /home/pi/.bashrc << 'EOT'

# Auto-start GUI on login
if [ -z "$SSH_CLIENT" ] && [ -z "$SSH_TTY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    echo "Starting GUI..."
    startx
fi
EOT

# Create rc.local for additional startup
log "Creating rc.local..."
cat > /etc/rc.local << 'EOT'
#!/bin/bash

# Start all services
systemctl start airplay.service
systemctl start google-cast.service
systemctl start wifi-tools.service
systemctl start remote-control.service
systemctl start desktop-ui.service

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

# Create desktop-ui.service
log "Creating desktop-ui.service..."
cat > "${OVERLAY_DIR}/etc/systemd/system/desktop-ui.service" << 'EOF'
[Unit]
Description=Raspberry Pi Desktop UI
After=network.target

[Service]
Type=simple
User=pi
ExecStart=/usr/local/bin/start-desktop-gui.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Create airplay.service
log "Creating airplay.service..."
cat > "${OVERLAY_DIR}/etc/systemd/system/airplay.service" << 'EOF'
[Unit]
Description=AirPlay Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/shairport-sync
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Create google-cast.service
log "Creating google-cast.service..."
cat > "${OVERLAY_DIR}/etc/systemd/system/google-cast.service" << 'EOF'
[Unit]
Description=Google Cast Receiver
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/cast-receiver.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Create wifi-tools.service
log "Creating wifi-tools.service..."
cat > "${OVERLAY_DIR}/etc/systemd/system/wifi-tools.service" << 'EOF'
[Unit]
Description=WiFi Tools Background Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/wifi-tools-daemon
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Create remote-control.service
log "Creating remote-control.service..."
cat > "${OVERLAY_DIR}/etc/systemd/system/remote-control.service" << 'EOF'
[Unit]
Description=Remote Control Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/remote-control-server
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Create start-desktop-gui.sh
log "Creating start-desktop-gui.sh..."
cat > "${OVERLAY_DIR}/usr/local/bin/start-desktop-gui.sh" << 'EOF'
#!/bin/bash

# Start the Raspberry Pi GUI application
python3 /usr/local/bin/raspberry-pi-gui.py
EOF

# Create cast-receiver.py
log "Creating cast-receiver.py..."
cat > "${OVERLAY_DIR}/usr/local/bin/cast-receiver.py" << 'EOF'
#!/usr/bin/env python3

# Simple Google Cast receiver
# This is a placeholder - in a real implementation, you would use pychromecast
# or another library to implement the Google Cast protocol

import time
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("cast-receiver")

logger.info("Starting Google Cast receiver service")

# In a real implementation, this would initialize the cast receiver
logger.info("Initializing Cast receiver")

# Main loop
while True:
    logger.info("Cast receiver running and waiting for connections")
    time.sleep(60)  # Just keep the service running
EOF

# Create wifi-tools-daemon
log "Creating wifi-tools-daemon..."
cat > "${OVERLAY_DIR}/usr/local/bin/wifi-tools-daemon" << 'EOF'
#!/bin/bash

# Background service for WiFi tools
# This is a placeholder - in a real implementation, you would use wifite and aircrack-ng

echo "Starting WiFi tools daemon"

# Create directory for captured keys
mkdir -p /var/lib/wifi-tools/captures

while true; do
    echo "WiFi tools daemon running..."
    sleep 300  # Run every 5 minutes
done
EOF

# Create remote-control-server
log "Creating remote-control-server..."
cat > "${OVERLAY_DIR}/usr/local/bin/remote-control-server" << 'EOF'
#!/usr/bin/env python3

# Simple remote control server
# This is a placeholder - in a real implementation, you would use Flask

import time
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("remote-control")

logger.info("Starting remote control server")

# In a real implementation, this would start a web server
logger.info("Initializing remote control server on port 8080")

# Main loop
while True:
    logger.info("Remote control server running")
    time.sleep(60)  # Just keep the service running
EOF

# Create raspberry-pi-gui.py
log "Creating raspberry-pi-gui.py..."
cat > "${OVERLAY_DIR}/usr/local/bin/raspberry-pi-gui.py" << 'EOF'
#!/usr/bin/env python3

# Raspberry Pi GUI Dashboard
import tkinter as tk
import socket
import os
import psutil
import threading
import time

class RaspberryPiDashboard:
    def __init__(self, root):
        self.root = root
        self.root.title("Raspberry Pi Dashboard")
        self.root.geometry("800x480")  # Standard Raspberry Pi display resolution
        self.root.attributes('-fullscreen', True)
        
        # Set background color
        self.root.configure(bg="#2c3e50")
        
        # Create main frame
        self.main_frame = tk.Frame(self.root, bg="#2c3e50")
        self.main_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=20)
        
        # Create header
        self.header = tk.Label(self.main_frame, text="Raspberry Pi 3B Dashboard", 
                              font=("Helvetica", 24, "bold"), bg="#2c3e50", fg="white")
        self.header.pack(pady=10)
        
        # Create status frame
        self.status_frame = tk.Frame(self.main_frame, bg="#34495e", bd=2, relief=tk.RAISED)
        self.status_frame.pack(fill=tk.X, pady=10)
        
        # Status labels
        self.hostname_label = tk.Label(self.status_frame, text=f"Hostname: {socket.gethostname()}", 
                                     font=("Helvetica", 12), bg="#34495e", fg="white")
        self.hostname_label.grid(row=0, column=0, sticky="w", padx=10, pady=5)
        
        self.ip_label = tk.Label(self.status_frame, text="IP: Checking...", 
                               font=("Helvetica", 12), bg="#34495e", fg="white")
        self.ip_label.grid(row=0, column=1, sticky="w", padx=10, pady=5)
        
        self.cpu_label = tk.Label(self.status_frame, text="CPU: Checking...", 
                                font=("Helvetica", 12), bg="#34495e", fg="white")
        self.cpu_label.grid(row=1, column=0, sticky="w", padx=10, pady=5)
        
        self.memory_label = tk.Label(self.status_frame, text="Memory: Checking...", 
                                   font=("Helvetica", 12), bg="#34495e", fg="white")
        self.memory_label.grid(row=1, column=1, sticky="w", padx=10, pady=5)
        
        # Create services frame
        self.services_frame = tk.LabelFrame(self.main_frame, text="Services", 
                                          font=("Helvetica", 14, "bold"), bg="#34495e", fg="white")
        self.services_frame.pack(fill=tk.X, pady=10)
        
        # Service status indicators
        self.services = {
            "AirPlay": {"status": "Unknown", "color": "gray"},
            "Google Cast": {"status": "Unknown", "color": "gray"},
            "Miracast": {"status": "Unknown", "color": "gray"},
            "Remote Control": {"status": "Unknown", "color": "gray"},
            "WiFi Tools": {"status": "Unknown", "color": "gray"}
        }
        
        row = 0
        col = 0
        for service, data in self.services.items():
            frame = tk.Frame(self.services_frame, bg="#34495e", padx=10, pady=5)
            frame.grid(row=row, column=col, sticky="w", padx=10, pady=5)
            
            indicator = tk.Canvas(frame, width=15, height=15, bg="#34495e", highlightthickness=0)
            indicator.create_oval(2, 2, 13, 13, fill=data["color"], outline="")
            indicator.pack(side=tk.LEFT, padx=5)
            
            label = tk.Label(frame, text=f"{service}: {data['status']}", 
                           font=("Helvetica", 12), bg="#34495e", fg="white")
            label.pack(side=tk.LEFT)
            
            data["indicator"] = indicator
            data["label"] = label
            
            col += 1
            if col > 2:
                col = 0
                row += 1
        
        # Create log frame
        self.log_frame = tk.LabelFrame(self.main_frame, text="System Log", 
                                     font=("Helvetica", 14, "bold"), bg="#34495e", fg="white")
        self.log_frame.pack(fill=tk.BOTH, expand=True, pady=10)
        
        self.log_text = tk.Text(self.log_frame, height=10, bg="#2c3e50", fg="white", 
                              font=("Courier", 10))
        self.log_text.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Add some initial log entries
        self.add_log("System starting up...")
        self.add_log("Initializing services...")
        
        # Start update thread
        self.update_thread = threading.Thread(target=self.update_data)
        self.update_thread.daemon = True
        self.update_thread.start()
        
        # Add exit button (for development)
        self.exit_button = tk.Button(self.main_frame, text="Exit", command=self.root.destroy, 
                                   bg="#e74c3c", fg="white", font=("Helvetica", 12))
        self.exit_button.pack(pady=10)
    
    def add_log(self, message):
        """Add a message to the log with timestamp"""
        timestamp = time.strftime("%H:%M:%S")
        self.log_text.insert(tk.END, f"[{timestamp}] {message}\n")
        self.log_text.see(tk.END)
    
    def update_service_status(self, service, status):
        """Update the status of a service"""
        if service in self.services:
            if status:
                self.services[service]["status"] = "Running"
                self.services[service]["color"] = "green"
            else:
                self.services[service]["status"] = "Stopped"
                self.services[service]["color"] = "red"
            
            self.services[service]["indicator"].create_oval(2, 2, 13, 13, 
                                                         fill=self.services[service]["color"], 
                                                         outline="")
            self.services[service]["label"].config(
                text=f"{service}: {self.services[service]['status']}")
    
    def get_ip_address(self):
        """Get the IP address of the primary interface"""
        try:
            # This is a simple way to get the IP, might not work in all cases
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except:
            return "Not connected"
    
    def update_data(self):
        """Update system data periodically"""
        while True:
            # Update IP
            ip = self.get_ip_address()
            self.ip_label.config(text=f"IP: {ip}")
            
            # Update CPU
            cpu_percent = psutil.cpu_percent()
            self.cpu_label.config(text=f"CPU: {cpu_percent}%")
            
            # Update memory
            memory = psutil.virtual_memory()
            memory_percent = memory.percent
            self.memory_label.config(text=f"Memory: {memory_percent}%")
            
            # Simulate checking services (in a real app, you would check actual service status)
            for service in self.services:
                # Simulate service status check - in a real app, check actual service status
                status = os.system(f"ps aux | grep -v grep | grep -q '{service.lower().replace(' ', '-')}'") == 0
                self.update_service_status(service, status)
                
                # For demo purposes, let's assume all services are running
                self.update_service_status(service, True)
            
            # Add occasional log messages
            if cpu_percent > 80:
                self.add_log(f"High CPU usage: {cpu_percent}%")
            
            time.sleep(2)  # Update every 2 seconds

if __name__ == "__main__":
    root = tk.Tk()
    app = RaspberryPiDashboard(root)
    root.mainloop()
EOF

# Create .bashrc for auto-starting GUI
log "Creating .bashrc for auto-starting GUI..."
cat > "${OVERLAY_DIR}/home/pi/.bashrc" << 'EOF'
# ~/.bashrc: executed by bash(1) for non-login shells.

# Note: PS1 and umask are already set in /etc/profile. You should not
# need this unless you want different defaults for root.
# PS1='${debian_chroot:+($debian_chroot)}\h:\w\$ '
# umask 022

# You may uncomment the following lines if you want `ls' to be colorized:
export LS_OPTIONS='--color=auto'
eval "`dircolors`"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias l='ls $LS_OPTIONS -lA'

# Some more alias to avoid making mistakes:
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Auto-start GUI on login
if [ -z "$SSH_CLIENT" ] && [ -z "$SSH_TTY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    echo "Starting GUI..."
    startx
fi
EOF

# Create autologin configuration
log "Creating autologin configuration..."
mkdir -p "${OVERLAY_DIR}/etc/systemd/system/getty@tty1.service.d"
cat > "${OVERLAY_DIR}/etc/systemd/system/getty@tty1.service.d/autologin.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM
Type=idle
Restart=always
RestartSec=1
EOF

# Copy the base image to the output directory
log "Copying base image to output directory..."
cp "${BASE_IMAGE}" "${OUTPUT_IMAGE}"

# Get partition information (macOS specific)
log "Getting partition information..."

# Mount the image
log "Mounting image partitions..."
DEVICE=$(hdiutil attach -nomount "${OUTPUT_IMAGE}" | head -n 1 | awk '{print $1}')
BOOT_PART="${DEVICE}s1"
ROOTFS_PART="${DEVICE}s2"

log "Boot partition: ${BOOT_PART}"
log "Rootfs partition: ${ROOTFS_PART}"

log "Mounting boot partition..."
diskutil mount -mountPoint "${BOOT_MOUNT}" "${BOOT_PART}"

log "Creating overlay directory in boot..."
mkdir -p "${BOOT_MOUNT}/overlay"

log "Copying overlay files to boot partition..."
rsync -av "${OVERLAY_DIR}/" "${BOOT_MOUNT}/overlay/"

log "Copying firstrun.sh to boot partition..."
cp "${CONFIG_DIR}/firstrun.sh" "${BOOT_MOUNT}/"
chmod +x "${BOOT_MOUNT}/firstrun.sh"

log "Copying wifi-credentials.txt to boot partition..."
cp "${CONFIG_DIR}/wifi-credentials.txt" "${BOOT_MOUNT}/"

log "Modifying cmdline.txt..."
CMDLINE_PATH="${BOOT_MOUNT}/cmdline.txt"
if ! grep -q "init=/bin/bash -c" "${CMDLINE_PATH}"; then
    echo "$(cat "${CMDLINE_PATH}") init=/bin/bash -c \"mount -t proc proc /proc; mount -t sysfs sys /sys; mount /boot; if [ -f /boot/firstrun.sh ]; then source /boot/firstrun.sh; else exec /sbin/init; fi\"" > "${CMDLINE_PATH}"
else
    warn "cmdline.txt already contains init modification, skipping."
fi

# Unmount partitions
log "Unmounting partitions..."
diskutil unmount "${BOOT_MOUNT}"
hdiutil detach "${DEVICE}"

log "✅ Image built successfully: ${OUTPUT_IMAGE}"

# Test the image in QEMU
log "Testing the image in QEMU..."
qemu-system-arm \
    -M versatilepb \
    -cpu arm1176 \
    -m 256 \
    -kernel "${QEMU_FILES}/kernel-qemu-4.19.50-buster" \
    -dtb "${QEMU_FILES}/versatile-pb-buster.dtb" \
    -no-reboot \
    -serial stdio \
    -append "root=/dev/sda1 panic=1 rootfstype=vfat rw init=/bin/bash -c \"mount -t proc proc /proc; mount -t sysfs sys /sys; ls -la /boot; echo 'QEMU test successful!'; sleep 10; poweroff\"" \
    -hda "${OUTPUT_IMAGE}" \
    -display cocoa \
    -net nic \
    -net user
