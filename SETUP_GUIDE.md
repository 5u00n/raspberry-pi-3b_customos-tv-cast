# 🍓 Custom Raspberry Pi 3B OS Setup Guide

## Overview

This guide will help you build and test your custom Raspberry Pi 3B OS with all the features mentioned in your README and system.md files.

## Prerequisites

### Required Software

- **QEMU**: `brew install qemu` (already installed ✅)
- **Git**: For cloning pi-gen repository
- **Docker** (optional): For alternative testing

### System Requirements

- **macOS** (you're using this ✅)
- **20GB+ free disk space** (for building the image)
- **Internet connection** (for downloading packages)

## Quick Start

### 1. Build Your Custom OS

```bash
# Build the custom Raspberry Pi OS image
./build-custom-os.sh
```

This will:

- Clone and configure pi-gen
- Install all your custom packages
- Set up all services (AirPlay, Google Cast, WiFi Tools, etc.)
- Create the custom GUI dashboard
- Build a complete OS image

**Expected time**: 30-60 minutes

### 2. Test in Virtual Machine

```bash
# Test your custom OS in QEMU
./test-custom-os.sh
```

This will:

- Start QEMU with your custom OS
- Show the actual desktop interface
- Enable web dashboard at http://localhost:8080
- Allow SSH access at localhost:2222

## What You'll See

### 🖥️ Desktop Interface

- **Full-screen GUI** (800x480) with dark theme
- **Real-time system monitoring** (CPU, memory, temperature)
- **Service status indicators** (green/red dots)
- **System log display** with live updates
- **Professional dashboard** with your custom branding

### 🌐 Web Dashboard

- **Access**: http://localhost:8080
- **Real-time monitoring** of all services
- **Service control** (start/stop/restart buttons)
- **Quick actions** (reboot/shutdown)
- **Mobile-responsive** design

### 📱 Wireless Display Features

- **AirPlay**: iPhone/iPad users see "Raspberry Pi 3B Custom OS"
- **Google Cast**: Android/Chrome users see "Raspberry Pi 3B Custom OS"
- **Miracast**: Windows/Android users can mirror to your Pi

### 🔐 WiFi Security Tools

- **Background network scanning**
- **WiFi network discovery** with signal strength
- **Data logging** to `/var/lib/wifi-tools/`
- **Encryption detection**

### 📁 File Sharing

- **Samba server** running
- **Access**: `\\localhost\pi` (Windows) or `smb://localhost/pi` (Mac)
- **Username**: `pi`, **Password**: `raspberry`

## Custom Features Included

### ✅ **Wireless Display Receiver**

- AirPlay support (Shairport-sync)
- Google Cast support (Custom HTTP receiver)
- Miracast support (Built-in)
- Auto-discovery as "Raspberry Pi 3B Custom OS"

### ✅ **Remote Control Interface**

- Web dashboard with real-time monitoring
- Service management (start/stop/restart)
- System control (reboot/shutdown)
- Mobile-responsive design

### ✅ **WiFi Security Tools**

- Network scanning and monitoring
- WiFi network discovery
- Data capture and logging
- Background monitoring service

### ✅ **Custom GUI Dashboard**

- Full-screen 800x480 interface
- Real-time system monitoring
- Service status indicators
- System log display
- Professional dark theme

### ✅ **File Sharing**

- Samba server for data access
- Captured WiFi data storage
- Remote file transfer

### ✅ **Auto-Login & Auto-Start**

- No password required after setup
- Desktop starts automatically
- GUI dashboard launches on boot
- All services start automatically

## File Structure

```
raspberry-pi-3b_customos-tv-cast/
├── README.md                    # Your original documentation
├── system.md                    # Complete system record
├── build-custom-os.sh          # Build script
├── test-custom-os.sh           # QEMU testing script
├── SETUP_GUIDE.md              # This guide
└── pi-gen/                     # Pi-gen build system
    ├── config                  # Build configuration
    ├── stage3/                 # Custom OS stage
    │   ├── 00-custom-packages/ # Package installation
    │   ├── 01-custom-services/ # Service setup
    │   ├── 02-custom-gui/      # GUI applications
    │   └── 03-custom-config/   # System configuration
    └── deploy/                 # Generated images (after build)
```

## Troubleshooting

### Build Issues

- **Low disk space**: Ensure 20GB+ free space
- **Permission errors**: Run with `sudo` if needed
- **Network issues**: Check internet connection

### QEMU Issues

- **Port conflicts**: Change ports in test script
- **No display**: Use `-nographic` flag (already included)
- **Slow performance**: Increase memory with `-m 512`

### Service Issues

- **Services not starting**: Check logs with `journalctl -u <service>`
- **Web dashboard not accessible**: Check if port 8080 is available
- **AirPlay not visible**: Ensure shairport-sync is running

## Next Steps

### For Real Hardware

1. **Flash the image** to an SD card
2. **Insert into Raspberry Pi 3B**
3. **Boot and test** all features
4. **Configure WiFi** in `/etc/wpa_supplicant/wpa_supplicant.conf`

### For Production

1. **Test thoroughly** on real hardware
2. **Customize branding** and features
3. **Create installation script** for easy deployment
4. **Document user guide** for end users

## Support

If you encounter issues:

1. Check the build logs for errors
2. Verify all prerequisites are installed
3. Ensure sufficient disk space
4. Check network connectivity

Your custom Raspberry Pi 3B OS is now ready for building and testing! 🍓


