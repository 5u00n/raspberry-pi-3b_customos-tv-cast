#!/bin/bash

# First Boot Setup Script for Raspberry Pi 3B
# This script ensures auto-login and GUI startup work correctly

set -e

LOG_FILE="/var/log/first-boot-setup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "🍓 Starting first boot setup for Raspberry Pi 3B..."

# Check if setup has already been run
if [ -f "/etc/setup-complete" ]; then
    log "Setup already completed, skipping..."
    exit 0
fi

# Wait for system to be fully ready
sleep 10

log "📦 Installing required packages..."
apt-get update
apt-get install -y $(cat /boot/packages.txt 2>/dev/null || echo "python3-tk python3-psutil")

log "🐍 Installing Python packages..."
pip3 install psutil requests flask flask-cors

log "🔓 Configuring auto-login for console..."
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM
Type=idle
Restart=always
RestartSec=1
EOF

log "🖥️ Configuring auto-login for desktop..."
mkdir -p /etc/lightdm
cat > /etc/lightdm/lightdm.conf << 'EOF'
[SeatDefaults]
autologin-user=pi
autologin-user-timeout=0
autologin-session=openbox
user-session=openbox
autologin-guest=false
EOF

log "⚙️ Creating systemd services..."

# AirPlay service
cat > /etc/systemd/system/airplay.service << 'EOF'
[Unit]
Description=AirPlay Receiver Service
After=network.target sound.target
Wants=network.target

[Service]
Type=simple
User=pi
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
WorkingDirectory=/home/pi
ExecStart=/usr/bin/shairport-sync -a "Raspberry Pi 3B"
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Google Cast service
cat > /etc/systemd/system/google-cast.service << 'EOF'
[Unit]
Description=Google Cast Receiver Service
After=network.target sound.target
Wants=network.target

[Service]
Type=simple
User=pi
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
WorkingDirectory=/home/pi
ExecStart=/usr/bin/python3 /usr/local/bin/cast-receiver.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# WiFi Tools service
cat > /etc/systemd/system/wifi-tools.service << 'EOF'
[Unit]
Description=WiFi Security Tools Daemon
After=network.target
Wants=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi
ExecStart=/usr/bin/python3 /usr/local/bin/wifi-tools-daemon.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Remote Control service
cat > /etc/systemd/system/remote-control.service << 'EOF'
[Unit]
Description=Remote Control Web Interface
After=network.target
Wants=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi
ExecStart=/usr/bin/python3 /usr/local/bin/remote-control-server
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Desktop GUI service
cat > /etc/systemd/system/desktop-ui.service << 'EOF'
[Unit]
Description=Desktop GUI Application Service
After=graphical.target network.target
Wants=graphical.target

[Service]
Type=simple
User=pi
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
WorkingDirectory=/home/pi
ExecStart=/usr/local/bin/start-desktop-gui.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical.target
EOF

# Auto-login service
cat > /etc/systemd/system/autologin.service << 'EOF'
[Unit]
Description=Force Auto-Login and Start All Services
After=graphical.target
Wants=graphical.target

[Service]
Type=oneshot
User=pi
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
WorkingDirectory=/home/pi
ExecStart=/usr/local/bin/force-autologin.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical.target
EOF

# Console auto-login service
cat > /etc/systemd/system/console-autologin.service << 'EOF'
[Unit]
Description=Console Auto-Login Service
After=getty@tty1.service
Wants=getty@tty1.service

[Service]
Type=oneshot
User=pi
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
WorkingDirectory=/home/pi
ExecStart=/usr/local/bin/console-autologin.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=getty.target
EOF

# Complete startup service
cat > /etc/systemd/system/raspberry-pi-startup.service << 'EOF'
[Unit]
Description=Raspberry Pi 3B Complete Startup Service
After=graphical.target network.target
Wants=graphical.target network.target

[Service]
Type=simple
User=pi
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
WorkingDirectory=/home/pi
ExecStart=/usr/local/bin/complete-startup.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical.target
EOF

# Auto-start GUI after login
mkdir -p /home/pi/.config/openbox
cat > /home/pi/.config/openbox/autostart << 'EOF'
#!/bin/bash
# Auto-start the desktop GUI
sleep 5
/usr/local/bin/start-desktop-gui.sh
EOF

chmod +x /home/pi/.config/openbox/autostart
chown -R pi:pi /home/pi/.config

# Create .bashrc for auto-start
cat > /home/pi/.bashrc << 'EOF'
# .bashrc for pi user - Auto-start GUI

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Auto-start GUI if this is an interactive login
if [[ $- == *i* ]] && [[ -n "$DISPLAY" ]]; then
    echo "🍓 Auto-starting Raspberry Pi GUI..."
    
    # Start GUI in background
    if [ -f "/usr/local/bin/raspberry-pi-gui.py" ]; then
        echo "✅ Starting GUI application..."
        nohup python3 /usr/local/bin/raspberry-pi-gui.py > /var/log/gui-auto.log 2>&1 &
        echo "🍓 GUI started with PID: $!"
    else
        echo "⚠️ GUI script not found, starting terminal dashboard..."
        nohup python3 /usr/local/bin/terminal-dashboard.py > /var/log/terminal-auto.log 2>&1 &
        echo "🍓 Terminal dashboard started with PID: $!"
    fi
fi

# Set display environment
export DISPLAY=:0
export XAUTHORITY=/home/pi/.Xauthority
EOF

chown pi:pi /home/pi/.bashrc

log "🚀 Enabling all services..."
systemctl enable airplay.service
systemctl enable google-cast.service
systemctl enable wifi-tools.service
systemctl enable remote-control.service
systemctl enable desktop-ui.service
systemctl enable autologin.service
systemctl enable console-autologin.service
systemctl enable raspberry-pi-startup.service

log "📶 Configuring WiFi auto-connection..."
if [ -f /boot/wifi-credentials.txt ]; then
    log "Found WiFi credentials, configuring networks..."
    
    # Read WiFi credentials
    source /boot/wifi-credentials.txt
    
    # Generate wpa_supplicant.conf
    cat > /etc/wpa_supplicant/wpa_supplicant.conf << EOF
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
EOF
    
    log "WiFi networks configured: $WIFI_SSID_1 (priority $WIFI_PRIORITY_1), $WIFI_SSID_2 (priority $WIFI_PRIORITY_2)"
else
    log "No WiFi credentials found, using default configuration"
fi

log "🔥 Configuring firewall..."
ufw --force enable
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 139/tcp   # Samba
ufw allow 445/tcp   # Samba
ufw allow 5000/tcp  # AirPlay
ufw allow 8009/tcp  # Google Cast
ufw allow 8080/tcp  # Remote Control
ufw allow 5353/udp  # mDNS
ufw allow 1900/udp  # UPnP

log "📁 Configuring Samba file sharing..."
cat > /etc/samba/smb.conf << 'EOF'
[global]
workgroup = WORKGROUP
server string = Raspberry Pi 3B
security = user
map to guest = bad user
dns proxy = no

[wifi-captures]
path = /var/wifi-captures
browseable = yes
read only = no
guest ok = yes
create mask = 0644
directory mask = 0755
EOF

# Create WiFi captures directory
mkdir -p /var/wifi-captures
chmod 777 /var/wifi-captures

log "🔊 Configuring audio..."
usermod -a -G audio pi
cat > /etc/asound.conf << 'EOF'
pcm.!default {
    type hw
    card 0
}
ctl.!default {
    type hw
    card 0
}
EOF

log "🔧 Making scripts executable..."
chmod +x /usr/local/bin/*.py
chmod +x /usr/local/bin/*.sh

log "🚀 Starting all services..."
systemctl start airplay.service
systemctl start google-cast.service
systemctl start wifi-tools.service
systemctl start remote-control.service
systemctl start desktop-ui.service
systemctl start autologin.service
systemctl start console-autologin.service
systemctl start raspberry-pi-startup.service

# Force enable graphical target
systemctl set-default graphical.target

log "✅ Setup completed successfully!"
log "🍓 Your Raspberry Pi 3B is now ready!"
log "📱 The desktop GUI will start automatically on next boot"
log "🌐 All services are running and accessible"
log "🔓 Auto-login is configured (no password needed)"
log "📝 Detailed logging is enabled for all services"

# Mark setup as complete
echo "$(date): Setup completed successfully" > /etc/setup-complete

log "🔄 Rebooting in 10 seconds to apply all changes..."
sleep 10
reboot
