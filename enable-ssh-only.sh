#!/bin/bash

# Quick SSH Enable Script
# Run this on your Raspberry Pi to enable SSH password authentication

echo "🔧 Enabling SSH password authentication..."

# Enable password authentication
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Restart SSH service
sudo systemctl restart ssh

echo "✅ SSH password authentication enabled!"
echo "You can now SSH with: ssh pi@$(hostname -I | awk '{print $1}')"
echo "Password: raspberry"
echo ""
echo "Now run the full setup:"
echo "curl -s https://raw.githubusercontent.com/5u00n/raspberry-pi-3b_customos-tv-cast/main/one-command-setup.sh | bash"
