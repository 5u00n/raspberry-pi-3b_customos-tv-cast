# 🍓 Raspberry Pi 3B Custom OS - Smart TV & Casting Solution

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/5u00n/raspberry-pi-3b_customos-tv-cast)
[![Platform](https://img.shields.io/badge/platform-Raspberry%20Pi%203B+-red)](https://www.raspberrypi.com/)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Python](https://img.shields.io/badge/python-3.11+-blue)](https://www.python.org/)

Transform your Raspberry Pi into a **Smart TV with wireless casting**, **beautiful GUI dashboard**, and **powerful network tools** - all configured to auto-start on boot!

---

## 📺 What Is This?

A complete custom Raspberry Pi OS that turns your Pi into a multi-functional smart device featuring:

- **🎨 Professional PyQt5 GUI** - Beautiful dashboard with real-time system monitoring
- **📱 Wireless Display** - AirPlay & Google Cast support for iPhone, Android, Mac, and Chrome
- **🌐 Web Dashboard** - Remote access and control via browser
- **📂 File Sharing** - Network file access via Samba
- **🔒 WiFi Tools** - Network monitoring and security analysis
- **⚡ Auto-Everything** - Boots directly to GUI with all services running

Perfect for media centers, digital signage, IoT dashboards, network monitoring, and smart home controllers!

---

## ✨ Key Features

### 🎨 Beautiful GUI Dashboard

- **Professional PyQt5 Interface** with gradient purple theme
- **Real-time Monitoring**: CPU, Memory, Disk, Temperature
- **Service Status Display**: All services with live indicators
- **System Information**: Hostname, IP address, uptime, current time
- **Auto-starts on boot** - No manual intervention needed
- **Full-screen optimized** for Raspberry Pi displays (1024x600+)

### 📱 Wireless Display Casting

| Feature             | Description                         | Compatible Devices             |
| ------------------- | ----------------------------------- | ------------------------------ |
| **AirPlay**         | Cast from Apple devices             | iPhone, iPad, Mac              |
| **Google Cast**     | Cast from Android & Chrome          | Android phones, Chrome browser |
| **Auto-Discovery**  | Appears as "Raspberry Pi Custom OS" | All devices on network         |
| **Audio Streaming** | High-quality audio over network     | Any AirPlay/Cast source        |

### 🌐 Remote Access & Control

- **Web Dashboard** on port 8080 - Access from any browser
- **SSH Server** - Remote terminal access (pre-configured)
- **Samba File Server** - Access Pi files from Windows/Mac/Linux
- **Remote Monitoring** - View system stats from anywhere

### 🔒 Network & Security Tools

- WiFi network scanning and analysis
- Signal strength monitoring
- Network interface management
- Security testing capabilities (ethical use only)

### ⚡ Auto-Configuration

- **Auto-login** - No password prompt on boot
- **Auto-start Desktop** - LXDE environment loads automatically
- **Auto-start GUI** - Dashboard appears immediately
- **Auto-start Services** - All features ready on boot

---

## 🚀 Installation

Choose the method that best fits your needs:

### Method 1: Quick Install (⚡ Fastest - 15 minutes)

**Best for:** Single Pi, testing, development, quick setup

#### Requirements:

- Raspberry Pi 3B or newer
- Fresh Raspberry Pi OS installation (Lite or Desktop)
- Internet connection

#### Steps:

1. **Flash Raspberry Pi OS** to your SD card:

   - Download: [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
   - Flash **Raspberry Pi OS Lite** or **Raspberry Pi OS with Desktop**
   - Minimum 8GB SD card (16GB recommended)

2. **Boot your Pi** and connect via SSH or directly with monitor/keyboard

3. **Clone and install:**

   ```bash
   git clone https://github.com/5u00n/raspberry-pi-3b_customos-tv-cast.git
   cd raspberry-pi-3b_customos-tv-cast
   chmod +x INSTALL-ON-PI.sh
   ./INSTALL-ON-PI.sh
   ```

4. **Reboot:**

   ```bash
   sudo reboot
   ```

5. **Done!** Your custom GUI appears automatically! 🎉

---

### Method 2: Build Custom Image (🏗️ Advanced - 1-2 hours)

**Best for:** Multiple Pi deployments, distribution, pre-configured installations

#### Requirements:

- Linux system (Ubuntu, Debian, or Raspberry Pi OS)
- Docker installed (or native Linux)
- 20GB free disk space
- 1-2 hours build time

#### Option A: Build on Linux

```bash
# Clone repository
git clone https://github.com/5u00n/raspberry-pi-3b_customos-tv-cast.git
cd raspberry-pi-3b_customos-tv-cast

# Run build script
chmod +x build-custom-os.sh
./build-custom-os.sh

# Wait for build to complete (1-2 hours)
# Image will be at: pi-gen/deploy/CustomRaspberryPi3B.img
```

#### Option B: Build in VM

If you're on macOS or Windows, use a Linux VM:

```bash
# Inside Ubuntu VM:
sudo apt-get update
sudo apt-get install -y git docker.io
git clone https://github.com/5u00n/raspberry-pi-3b_customos-tv-cast.git
cd raspberry-pi-3b_customos-tv-cast
sudo ./build-custom-os.sh
```

See [BUILD-OPTIONS.md](BUILD-OPTIONS.md) for detailed VM setup instructions.

#### Option C: Use GitHub Actions (☁️ Cloud Build)

1. Fork this repository on GitHub
2. Go to **Actions** tab
3. Click **"Build Custom Raspberry Pi OS"**
4. Click **"Run workflow"**
5. Wait for build to complete (~1-2 hours)
6. Download the generated image from **Artifacts**

The GitHub Actions workflow automatically builds the image in the cloud!

---

### Method 3: Flash Pre-Built Image (if available)

```bash
# Download the latest release
# Flash to SD card:
sudo dd if=CustomRaspberryPi3B.img of=/dev/sdX bs=4M status=progress
sync
```

---

## 💾 Flashing to SD Card / USB Drive

### macOS:

```bash
# Find your device
diskutil list

# Unmount (replace diskX with your disk number)
diskutil unmountDisk /dev/diskX

# Flash the image (use rdiskX for faster write)
sudo dd if=pi-gen/deploy/CustomRaspberryPi3B.img of=/dev/rdiskX bs=1m status=progress

# Eject safely
sudo diskutil eject /dev/diskX
```

### Linux:

```bash
# Find your device
lsblk

# Flash the image (replace sdX with your device)
sudo dd if=pi-gen/deploy/CustomRaspberryPi3B.img of=/dev/sdX bs=4M status=progress
sync

# Eject
sudo umount /dev/sdX*
```

### Windows:

Use [balenaEtcher](https://www.balena.io/etcher/) or [Raspberry Pi Imager](https://www.raspberrypi.com/software/)

**💡 Tip:** USB drives work great and are often faster than SD cards! See [USB-DRIVE-BOOT.md](USB-DRIVE-BOOT.md) for details.

---

## 🖥️ What You'll See

When you power on your Raspberry Pi, this beautiful interface greets you:

```
┌─────────────────────────────────────────────────────────────────┐
│  🍓 Raspberry Pi 3B Custom OS Dashboard                        │
│  Live System Monitoring & Control                               │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐           │
│  │ CPU     │  │ Memory  │  │  Disk   │  │  Temp   │           │
│  │ 25.3%   │  │ 42.1%   │  │ 15.8%   │  │ 45.2°C  │           │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘           │
├─────────────────────────────────────────────────────────────────┤
│  Hostname: raspberrypi-custom    IP: 192.168.1.100             │
│  Uptime: 2h 15m                  Time: 16:30:45                │
├─────────────────────────────────────────────────────────────────┤
│  Services Status:                                               │
│  ● AirPlay Receiver      Running  ● Google Cast         Running│
│  ● WiFi Security Tools   Running  ● Remote Control      Running│
│  ● File Server (Samba)   Running  ● GUI Dashboard       Running│
└─────────────────────────────────────────────────────────────────┘
```

**Features shown in real-time:**

- CPU usage with visual indicator
- Memory usage and available RAM
- Disk usage and free space
- CPU temperature
- Network information (hostname, IP)
- System uptime
- All service statuses

---

## 🔌 How to Access Your Pi

### 1. Direct Access (GUI)

- Connect HDMI monitor + keyboard/mouse
- Power on your Raspberry Pi
- GUI appears automatically after ~30 seconds
- No login required (auto-login enabled)

### 2. SSH Access

```bash
# Using hostname
ssh pi@raspberrypi-custom

# Or using IP address
ssh pi@192.168.1.XXX

# Default password
Password: raspberry
```

**Change password immediately:**

```bash
passwd
```

### 3. Web Dashboard

Open in any browser:

```
http://raspberrypi-custom:8080
```

Or using IP:

```
http://192.168.1.XXX:8080
```

### 4. File Sharing (Samba)

**Windows:**

```
\\raspberrypi-custom\pi
```

**Mac:**

```
smb://raspberrypi-custom/pi
```

**Linux:**

```
smb://raspberrypi-custom/pi
```

**Credentials:**

- Username: `pi`
- Password: `raspberry`

### 5. Wireless Casting

#### From iPhone/iPad (AirPlay):

1. Swipe down from top-right for Control Center
2. Tap **Screen Mirroring** or **AirPlay**
3. Select **"Raspberry Pi Custom OS"**
4. Content displays on connected monitor

#### From Android/Chrome (Google Cast):

1. Open YouTube, Netflix, or Chrome browser
2. Tap the **Cast** icon
3. Select **"Raspberry Pi Custom OS"**
4. Content streams to your Pi

#### From Mac (AirPlay):

1. Click **Control Center** in menu bar
2. Click **Screen Mirroring**
3. Select **"Raspberry Pi Custom OS"**
4. Desktop mirrors to Pi

---

## 🛠️ Technical Stack

### Operating System

- **Base OS:** Raspberry Pi OS (Debian 12 Bookworm)
- **Kernel:** Latest stable Linux kernel for ARM
- **Architecture:** ARM (ARMv7/ARMv8)

### Desktop Environment

- **Desktop:** LXDE (Lightweight X11 Desktop Environment)
- **Display Manager:** LightDM with auto-login
- **Window Manager:** Openbox
- **Display Server:** X.org

### GUI & Applications

- **GUI Framework:** PyQt5 5.15+
- **Web Framework:** Flask 3.0+
- **Language:** Python 3.11+
- **Monitoring:** psutil for system stats

### Network Services

- **AirPlay Server:** shairport-sync 4.3+
- **Service Discovery:** avahi-daemon
- **File Sharing:** Samba 4.17+
- **Web Server:** Nginx 1.22+
- **SSH Server:** OpenSSH (latest stable)

### Additional Tools

- **WiFi Tools:** iw, wireless-tools
- **Python Packages:** flask-cors, requests, psutil
- **System Tools:** systemd service management

---

## 📊 System Requirements

### Minimum Requirements

| Component   | Specification    |
| ----------- | ---------------- |
| **Model**   | Raspberry Pi 3B  |
| **RAM**     | 1GB              |
| **Storage** | 8GB SD card      |
| **Display** | 1024x600 HDMI    |
| **Network** | WiFi or Ethernet |

### Recommended Configuration

| Component   | Specification         |
| ----------- | --------------------- |
| **Model**   | Raspberry Pi 4 (2GB+) |
| **Storage** | 16GB+ USB 3.0 drive   |
| **Display** | 1920x1080 HDMI        |
| **Network** | Gigabit Ethernet      |
| **Cooling** | Heatsink + Fan        |

**💡 Pro Tip:** USB 3.0 drives are **significantly faster** than SD cards for both boot time and app performance!

---

## 🎯 Use Cases

### Home Media Center

Turn any TV into a smart TV with wireless casting from all your devices. Stream from Netflix, YouTube, Spotify, and more!

### Digital Signage

Deploy beautiful, remotely-managed displays for businesses, schools, or public spaces with the professional GUI interface.

### Network Monitoring Station

Use the built-in WiFi tools and system monitoring dashboard to keep tabs on your network health and security.

### Smart Home Controller

Central hub for IoT devices with the web dashboard accessible from any device on your network.

### Educational Projects

Perfect for learning Linux, Python, PyQt5, network services, and Raspberry Pi programming.

### Development & Testing

Quick-start platform for testing applications, services, and configurations on Raspberry Pi hardware.

---

## 🔧 Customization

### Change GUI Appearance

Edit the GUI script:

```bash
sudo nano /usr/local/bin/raspberry-pi-gui.py
```

Customize:

- Colors and theme
- Layout and card sizes
- Monitoring intervals
- Service displays

### Add Services to Dashboard

Edit the service list in the GUI script to add your own systemd services to the status display.

### Configure Auto-Start Applications

Add .desktop files to:

```bash
~/.config/autostart/
```

### Modify System Settings

All system configuration follows standard Raspberry Pi OS conventions. Modify:

- `/etc/` for system configs
- `/boot/config.txt` for hardware settings
- `raspi-config` for common settings

---

## 📝 Default Credentials

### System Login

- **Username:** `pi`
- **Password:** `raspberry`
- **Hostname:** `raspberrypi-custom`

### SSH Access

- **Port:** 22 (default)
- **User:** pi
- **Password:** raspberry

### Samba (File Sharing)

- **Share Name:** `\\raspberrypi-custom\pi`
- **Username:** pi
- **Password:** raspberry

### Web Dashboard

- **URL:** `http://raspberrypi-custom:8080`
- **No authentication** (local network only)

⚠️ **SECURITY WARNING:** Change the default password immediately after first boot!

```bash
# Change user password
passwd

# Change Samba password
sudo smbpasswd -a pi
```

---

## 🆘 Troubleshooting

### GUI doesn't appear on boot

```bash
# Check LightDM status
sudo systemctl status lightdm

# Restart display manager
sudo systemctl restart lightdm

# Check autostart configuration
ls -la ~/.config/autostart/

# View GUI logs
journalctl -u lightdm
```

### Can't connect via SSH

```bash
# Check SSH service
sudo systemctl status ssh

# Enable SSH if disabled
sudo systemctl enable ssh
sudo systemctl start ssh

# Check if port 22 is listening
sudo ss -tulpn | grep :22
```

### Services not working

```bash
# Check all service statuses
sudo systemctl status shairport-sync  # AirPlay
sudo systemctl status avahi-daemon     # Discovery
sudo systemctl status smbd             # File sharing
sudo systemctl status nginx            # Web server

# Restart a service
sudo systemctl restart <service-name>

# View service logs
journalctl -u <service-name> -f
```

### AirPlay/Cast not visible

```bash
# Restart discovery service
sudo systemctl restart avahi-daemon

# Restart AirPlay
sudo systemctl restart shairport-sync

# Check network connectivity
ping 8.8.8.8

# Ensure devices are on same network
ip addr show
```

### System running slow

```bash
# Check CPU/Memory usage
top
htop

# Check disk space
df -h

# Check temperature
vcgencmd measure_temp

# Reduce services if needed
sudo systemctl disable <service-name>
```

### WiFi not working

```bash
# Scan for networks
sudo iwlist wlan0 scan | grep ESSID

# Configure WiFi
sudo raspi-config
# Select: System Options → Wireless LAN

# Or edit directly
sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
```

---

## 📚 Additional Documentation

- **[QUICK-START.md](QUICK-START.md)** - Quick reference guide
- **[BUILD-OPTIONS.md](BUILD-OPTIONS.md)** - All build methods explained
- **[USB-DRIVE-BOOT.md](USB-DRIVE-BOOT.md)** - USB drive setup guide
- **[SMART-TV-FEATURES.md](SMART-TV-FEATURES.md)** - Smart TV interface details
- **[FINAL-OS-DETAILS.md](FINAL-OS-DETAILS.md)** - Complete feature documentation
- **[FLASH-INSTRUCTIONS.txt](FLASH-INSTRUCTIONS.txt)** - Flashing guide for all platforms

---

## 🔄 Updates & Maintenance

### Keep System Updated

```bash
# Update package lists
sudo apt update

# Upgrade all packages
sudo apt upgrade -y

# Update Pi firmware
sudo rpi-update

# Reboot after updates
sudo reboot
```

### Update Custom OS Features

```bash
cd raspberry-pi-3b_customos-tv-cast
git pull
./INSTALL-ON-PI.sh
sudo reboot
```

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Ideas for Contributions

- Additional GUI themes
- New service integrations
- Performance improvements
- Documentation improvements
- Bug fixes
- New wireless display protocols
- Mobile app for remote control

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

You are free to:

- ✅ Use commercially
- ✅ Modify
- ✅ Distribute
- ✅ Private use

---

## 🙏 Acknowledgments

- **[pi-gen](https://github.com/RPi-Distro/pi-gen)** - Raspberry Pi OS image builder
- **[PyQt5](https://www.riverbankcomputing.com/software/pyqt/)** - Python GUI framework
- **[shairport-sync](https://github.com/mikebrady/shairport-sync)** - AirPlay audio receiver
- **[Raspberry Pi Foundation](https://www.raspberrypi.org/)** - For the amazing hardware
- **[Debian Project](https://www.debian.org/)** - Base operating system
- **All contributors** who help improve this project

---

## 📧 Support & Contact

### Need Help?

- 🐛 **Report bugs:** [Open an issue](https://github.com/5u00n/raspberry-pi-3b_customos-tv-cast/issues)
- 💡 **Request features:** [Open an issue](https://github.com/5u00n/raspberry-pi-3b_customos-tv-cast/issues)
- 💬 **Ask questions:** [Discussions](https://github.com/5u00n/raspberry-pi-3b_customos-tv-cast/discussions)

### Show Your Support

If you find this project useful:

- ⭐ **Star** the repository
- 🔀 **Fork** and customize it
- 📢 **Share** with others
- ☕ **Sponsor** the development (if available)

---

## 🎉 Quick Command Reference

```bash
# Installation
git clone https://github.com/5u00n/raspberry-pi-3b_customos-tv-cast.git
cd raspberry-pi-3b_customos-tv-cast
./INSTALL-ON-PI.sh

# Access
ssh pi@raspberrypi-custom           # SSH
http://raspberrypi-custom:8080      # Web Dashboard
\\raspberrypi-custom\pi             # File Share (Windows)

# Service Management
sudo systemctl restart lightdm      # Restart GUI
sudo systemctl restart shairport-sync  # Restart AirPlay
sudo systemctl status <service>     # Check status

# System Info
hostname -I                         # Show IP address
vcgencmd measure_temp              # Show temperature
free -h                            # Show memory usage
df -h                              # Show disk usage

# Updates
sudo apt update && sudo apt upgrade -y
sudo reboot
```

---

<div align="center">

### 🍓 Built with ❤️ for the Raspberry Pi Community

**Transform your Raspberry Pi into something extraordinary!**

[![GitHub](https://img.shields.io/github/stars/5u00n/raspberry-pi-3b_customos-tv-cast?style=social)](https://github.com/5u00n/raspberry-pi-3b_customos-tv-cast)
[![Follow](https://img.shields.io/github/followers/5u00n?style=social)](https://github.com/5u00n)

**Made with 🚀 by [5u00n](https://github.com/5u00n)**

</div>
