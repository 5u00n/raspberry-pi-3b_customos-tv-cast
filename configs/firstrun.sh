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
