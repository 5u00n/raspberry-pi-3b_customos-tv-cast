#!/bin/bash

# Enable SSH password authentication on Raspberry Pi
# This script should be run directly on the Pi

echo "Enabling SSH password authentication..."

# Enable password authentication
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Restart SSH service
sudo systemctl restart ssh

echo "SSH password authentication enabled!"
echo "You can now SSH with: ssh pi@$(hostname -I | awk '{print $1}')"
echo "Password: raspberry"
