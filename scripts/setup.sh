#!/bin/bash

# Raspberry Pi 3B Custom OS Setup Script
# This script runs on first boot to configure the system

set -e

echo "🍓 Starting Raspberry Pi 3B Custom OS Setup..."

# Update package list
echo "📦 Updating package list..."
apt-get update

# Install required packages
echo "📥 Installing required packages..."
apt-get install -y $(cat /boot/packages.txt)

# Install additional Python packages
echo "🐍 Installing Python packages..."
pip3 install psutil requests flask flask-cors

# Configure auto-login for console
echo "🔓 Configuring console auto-login..."
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM
Type=idle
EOF

# Configure auto-login for desktop
echo "🖥️ Configuring desktop auto-login..."
cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=pi
autologin-user-timeout=0
autologin-session=lightdm-autologin
user-session=openbox
autologin-guest=false
EOF

# Create systemd services
echo "⚙️ Creating systemd services..."

# AirPlay service
cat > /etc/systemd/system/airplay.service << EOF
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
cat > /etc/systemd/system/google-cast.service << EOF
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
ExecStartPre=/bin/bash -c 'if ! pgrep -f "chromecast-daemon\|cast-receiver" > /dev/null; then echo "Starting Google Cast service"; fi'
ExecStart=/usr/bin/python3 /usr/local/bin/cast-receiver.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# WiFi Tools service
cat > /etc/systemd/system/wifi-tools.service << EOF
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
cat > /etc/systemd/system/remote-control.service << EOF
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
cat > /etc/systemd/system/desktop-ui.service << EOF
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
cat > /etc/systemd/system/auto-login.service << EOF
[Unit]
Description=Auto-login Configuration Service
After=graphical.target
Wants=graphical.target

[Service]
Type=oneshot
User=pi
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
ExecStart=/bin/bash -c 'echo "Auto-login configured successfully"'
RemainAfterExit=yes

[Install]
WantedBy=graphical.target
EOF

# Enable services
echo "🚀 Enabling services..."
systemctl enable airplay.service
systemctl enable google-cast.service
systemctl enable wifi-tools.service
systemctl enable remote-control.service
systemctl enable desktop-ui.service
systemctl enable auto-login.service

# Configure WiFi auto-connection
echo "📶 Configuring WiFi auto-connection..."
if [ -f /boot/wifi-credentials.txt ]; then
    echo "Found WiFi credentials, configuring networks..."
    
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
    
    echo "WiFi networks configured: $WIFI_SSID_1 (priority $WIFI_PRIORITY_1), $WIFI_SSID_2 (priority $WIFI_PRIORITY_2)"
else
    echo "No WiFi credentials found, using default configuration"
fi

# Configure firewall
echo "🔥 Configuring firewall..."
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

# Configure Samba file sharing
echo "📁 Configuring Samba file sharing..."
cat > /etc/samba/smb.conf << EOF
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

# Configure audio
echo "🔊 Configuring audio..."
usermod -a -G audio pi
cat > /etc/asound.conf << EOF
pcm.!default {
    type hw
    card 0
}
ctl.!default {
    type hw
    card 0
}
EOF

# Set up desktop environment
echo "🖥️ Setting up desktop environment..."
mkdir -p /home/pi/.config/openbox
cat > /home/pi/.config/openbox/autostart << EOF
#!/bin/bash
# Auto-start the desktop GUI
sleep 10
/usr/local/bin/start-desktop-gui.sh
EOF

chmod +x /home/pi/.config/openbox/autostart
chown -R pi:pi /home/pi/.config

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x /usr/local/bin/*.py
chmod +x /usr/local/bin/*.sh

# Start services
echo "🚀 Starting services..."
systemctl start airplay.service
systemctl start google-cast.service
systemctl start wifi-tools.service
systemctl start remote-control.service
systemctl start desktop-ui.service

echo "✅ Setup completed successfully!"
echo "🍓 Your Raspberry Pi 3B is now ready!"
echo "📱 The desktop GUI will start automatically on next boot"
echo "🌐 All services are running and accessible"
echo "🔓 Auto-login is configured (no password needed)"

# Remove this script from startup
systemctl disable setup.service
rm -f /etc/systemd/system/setup.service

echo "🔄 Rebooting in 10 seconds to apply all changes..."
sleep 10
reboot
