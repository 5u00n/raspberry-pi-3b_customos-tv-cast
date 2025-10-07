#!/bin/bash -e
on_chroot << EOFCHROOT
apt-get update
apt-get upgrade -y
pip3 install --break-system-packages flask flask-cors requests psutil || pip3 install flask flask-cors requests psutil
systemctl enable ssh
systemctl enable shairport-sync
systemctl enable avahi-daemon
systemctl enable smbd
systemctl enable nginx
echo "✅ All packages installed and services enabled"
EOFCHROOT
