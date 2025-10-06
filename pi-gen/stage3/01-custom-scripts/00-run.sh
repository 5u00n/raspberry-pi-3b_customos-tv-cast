#!/bin/bash -e

on_chroot << EOFCHROOT
# Create directories
mkdir -p /usr/local/bin
mkdir -p /home/pi/.config/autostart

# Install scripts
install -m 755 /tmp/stage3-files/raspberry-pi-gui.py /usr/local/bin/
install -m 755 /tmp/stage3-files/airplay-service /usr/local/bin/
install -m 755 /tmp/stage3-files/google-cast-service /usr/local/bin/
install -m 755 /tmp/stage3-files/remote-control-server /usr/local/bin/

# Create autostart desktop entry for GUI
cat > /home/pi/.config/autostart/custom-gui.desktop << 'AUTOSTART'
[Desktop Entry]
Type=Application
Name=Custom GUI
Exec=python3 /usr/local/bin/raspberry-pi-gui.py
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
AUTOSTART

# Set ownership
chown -R 1000:1000 /home/pi/.config

# Enable auto-login for console
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'AUTOLOGIN'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM
AUTOLOGIN

# Configure LightDM for auto-login
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/01-autologin.conf << 'LIGHTDM'
[Seat:*]
autologin-user=pi
autologin-user-timeout=0
LIGHTDM

# Enable desktop to start automatically
systemctl set-default graphical.target
systemctl enable lightdm

# Create systemd services
cat > /etc/systemd/system/airplay.service << 'AIRPLAY'
[Unit]
Description=AirPlay Receiver
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/bin/airplay-service start
ExecStop=/usr/local/bin/airplay-service stop
Restart=always

[Install]
WantedBy=multi-user.target
AIRPLAY

cat > /etc/systemd/system/google-cast.service << 'CAST'
[Unit]
Description=Google Cast Receiver
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/bin/google-cast-service start
ExecStop=/usr/local/bin/google-cast-service stop
Restart=always

[Install]
WantedBy=multi-user.target
CAST

cat > /etc/systemd/system/remote-control.service << 'REMOTE'
[Unit]
Description=Remote Control Web Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/remote-control-server
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
REMOTE

# Enable services
systemctl enable airplay.service
systemctl enable google-cast.service
systemctl enable remote-control.service

# Configure Samba
cat >> /etc/samba/smb.conf << 'SAMBA'

[pi]
   path = /home/pi
   browseable = yes
   read only = no
   guest ok = no
SAMBA

# Set Samba password (default: raspberry)
(echo "raspberry"; echo "raspberry") | smbpasswd -a pi -s

echo "✅ Custom OS configuration complete!"
EOFCHROOT

# Copy files to a temporary location in the image
install -d "${ROOTFS_DIR}/tmp/stage3-files"
install -m 644 files/* "${ROOTFS_DIR}/tmp/stage3-files/"
