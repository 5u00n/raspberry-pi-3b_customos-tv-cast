# Raspberry Pi 3B Custom OS - Final Instructions

## Overview

This SD card contains a custom Raspberry Pi OS with the following features:

- Auto-login without password
- Graphical user interface that starts automatically
- AirPlay, Google Cast, and Miracast support (always on)
- Remote control interface accessible via WiFi
- Background WiFi tools (wifite/aircrack) for key capture
- File servers for accessing captured data

## Using Your SD Card

### Step 1: Insert SD Card into Raspberry Pi 3B

- Insert the SD card into your Raspberry Pi 3B
- Connect the Raspberry Pi to a display via HDMI
- Connect power to the Raspberry Pi

### Step 2: First Boot Process

- On first boot, the system will run a setup script automatically
- This process will:
  - Copy all overlay files to the root filesystem
  - Configure auto-login
  - Set up WiFi with your configured networks
  - Install required packages
  - Enable all services
  - Reboot automatically when complete

**Note:** The first boot process may take 5-10 minutes. Please be patient and do not disconnect power during this time.

### Step 3: After Reboot

- The system will automatically:
  - Log in without asking for a password
  - Start the graphical user interface
  - Connect to WiFi (if available)
  - Start all services (AirPlay, Google Cast, etc.)

### WiFi Configuration

The following WiFi networks are pre-configured:

1. "connection" (Priority 1)
2. "Nomita" (Priority 2)

The system will try to connect to these networks in priority order.

## Features

### Graphical User Interface

- Shows system status (CPU, memory, disk usage)
- Displays service status
- Shows WiFi connection status
- Logs important events

### Wireless Display Protocols

- **AirPlay**: Connect from Apple devices
- **Google Cast**: Connect from Android/Chrome devices
- **Miracast**: Connect from Windows/Android devices

### Remote Control

- Access the remote control interface at `http://<raspberry-pi-ip>:8080`
- Control media playback
- View system status
- Configure settings

### WiFi Security Tools

- Background services capture WiFi authentication data
- Captured keys are stored in `/var/lib/wifi-tools/captures`
- Access via Samba or FTP

## Troubleshooting

### If Auto-Login Doesn't Work

- Login with username: `pi` and password: `raspberry`
- Check the logs: `cat /boot/firstrun.log`

### If WiFi Doesn't Connect

- Connect via Ethernet
- Edit WiFi settings: `sudo nano /etc/wpa_supplicant/wpa_supplicant.conf`

### If Services Don't Start

- Check service status: `systemctl status airplay.service`
- Restart services: `sudo systemctl restart airplay.service`

### If GUI Doesn't Start

- Start manually: `startx`
- Check logs: `cat ~/.xsession-errors`

## Logging

All setup and boot processes are logged to:

- `/boot/firstrun.log` (first boot setup)
- `/var/log/syslog` (system logs)
- Console output (visible on screen during boot)

## GitHub Repository

All files and scripts for this custom OS are available on GitHub:

- Repository URL: https://github.com/5u00n/my_rasp_OS
- You can clone this repository to set up the system on another Raspberry Pi
- One-line installation command:
  ```
  curl -L https://raw.githubusercontent.com/5u00n/my_rasp_OS/main/install.sh | sudo bash
  ```

### Setting Up from GitHub

To set up this system on another Raspberry Pi:

1. Start with a fresh Raspberry Pi OS installation
2. Connect to the internet
3. Run the one-line installer:
   ```
   curl -L https://raw.githubusercontent.com/5u00n/my_rasp_OS/main/install.sh | sudo bash
   ```
4. Follow the prompts to enter your WiFi credentials
5. Reboot when prompted
6. The system will automatically configure itself on first boot

## Enjoy Your Custom Raspberry Pi OS!

Your Raspberry Pi 3B is now configured with all the features you requested. The system will automatically start all services and provide a user-friendly interface for monitoring and control.
