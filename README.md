# 🍓 Raspberry Pi 3B Custom OS

A beautiful custom Raspberry Pi OS with **PyQt5 GUI**, wireless display capabilities, and remote control features that auto-starts on boot!

![Status](https://img.shields.io/badge/status-ready-brightgreen)
![Platform](https://img.shields.io/badge/platform-Raspberry%20Pi%203B-red)
![GUI](https://img.shields.io/badge/GUI-PyQt5-blue)

---

## ✨ Features

### 🎨 Beautiful Qt GUI

- **Professional PyQt5 interface** with gradient purple theme
- **Full-screen dashboard** optimized for Raspberry Pi displays
- **Real-time monitoring**: CPU, Memory, Disk, Temperature
- **Auto-starts on boot** - no manual intervention needed
- **Modern card-based layout** with smooth animations

### 📱 Wireless Display

- **AirPlay Receiver** - Cast from iPhone/iPad
- **Google Cast** - Cast from Android/Chrome
- Auto-discovery on your network

### 🌐 Remote Access

- **Web Dashboard** - Access via browser (port 8080)
- **SSH Server** - Remote terminal access
- **File Sharing** - Samba server for network access

### 🔒 Network Tools

- **WiFi Monitoring** - Network scanning and analysis
- **Security Tools** - WiFi penetration testing capabilities

### ⚡ Auto-Everything

- **Auto-login** - No password required on boot
- **Auto-start GUI** - Dashboard appears automatically
- **Auto-start services** - All features ready immediately

---

## 📦 Installation Methods

### Method 1: Install on Existing Raspberry Pi OS (Recommended)

This is the **easiest and fastest** way to get your custom OS running!

#### Requirements:

- Raspberry Pi 3B (or newer)
- Fresh Raspberry Pi OS installation
- Internet connection

#### Steps:

1. **Flash Raspberry Pi OS** to your SD card:

   - Download from: https://www.raspberrypi.com/software/
   - Use Raspberry Pi Imager to flash to SD card (8GB minimum)

2. **Boot your Raspberry Pi** and complete initial setup

3. **Clone this repository**:

   ```bash
   git clone https://github.com/YOUR_USERNAME/raspberry-pi-3b_customos-tv-cast.git
   cd raspberry-pi-3b_customos-tv-cast
   ```

4. **Run the installer**:

   ```bash
   chmod +x INSTALL-ON-PI.sh
   ./INSTALL-ON-PI.sh
   ```

5. **Reboot**:

   ```bash
   sudo reboot
   ```

6. **Enjoy!** Your custom GUI will appear automatically on boot! 🎉

---

### Method 2: Build Custom Image (Advanced)

Build a complete custom OS image that you can flash directly to SD cards.

#### Requirements:

- macOS or Linux computer
- Docker installed
- 10GB free disk space
- 30-60 minutes build time

#### Steps:

1. **Clone this repository**:

   ```bash
   git clone https://github.com/YOUR_USERNAME/raspberry-pi-3b_customos-tv-cast.git
   cd raspberry-pi-3b_customos-tv-cast
   ```

2. **Start the build**:

   ```bash
   chmod +x BUILD-CUSTOM-OS.sh
   ./BUILD-CUSTOM-OS.sh
   ```

3. **Wait for build** (30-60 minutes)

4. **Flash the image**:

   ```bash
   # Find your SD card
   diskutil list

   # Unmount
   diskutil unmountDisk /dev/diskX

   # Flash (replace X with your disk number)
   sudo dd if=pi-gen/deploy/CustomRaspberryPi3B.img of=/dev/rdiskX bs=1m

   # Eject
   sudo diskutil eject /dev/diskX
   ```

5. **Insert SD card into Raspberry Pi and power on!**

---

## 🖥️ What You'll See

When you power on your Raspberry Pi, you'll see this beautiful interface:

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

**Preview the GUI**: Open `GUI-PREVIEW.html` in your browser to see a live demo!

---

## 🔌 Access Your Raspberry Pi

### Direct Access (GUI):

- Connect HDMI monitor + keyboard/mouse
- Power on
- GUI appears automatically!

### SSH Access:

```bash
ssh pi@raspberrypi-custom
# Password: raspberry
```

### Web Dashboard:

```
http://raspberrypi-custom:8080
# or
http://YOUR_PI_IP:8080
```

### File Sharing:

```
Windows: \\raspberrypi-custom\pi
Mac:     smb://raspberrypi-custom/pi
Linux:   smb://raspberrypi-custom/pi

Username: pi
Password: raspberry
```

### AirPlay/Cast:

- Look for "Raspberry Pi 3B Custom OS" in your device's cast menu
- Works with iPhone, iPad, Android, Chrome

---

## 🛠️ Technical Details

### Software Stack:

- **OS**: Raspberry Pi OS (Debian Bullseye)
- **GUI**: PyQt5
- **Desktop**: LXDE + Openbox
- **Display Manager**: LightDM (auto-login enabled)
- **Web Framework**: Flask
- **Language**: Python 3

### Services:

- **AirPlay**: shairport-sync
- **File Sharing**: Samba
- **Web Server**: Nginx
- **SSH**: OpenSSH Server
- **WiFi Tools**: iw, wireless-tools

### System Requirements:

- Raspberry Pi 3B or newer
- 8GB SD card minimum (16GB recommended)
- HDMI display (1024x600 or higher)
- WiFi or Ethernet connection

---

## 📝 Default Credentials

**Username**: `pi`  
**Password**: `raspberry`

⚠️ **Security Note**: Change the default password after installation:

```bash
passwd
```

---

## 🎯 Use Cases

Perfect for:

- 📺 Home media centers
- 🖼️ Digital signage
- 📊 Network monitoring stations
- 🎓 Educational projects
- 🏠 Smart home controllers
- 📡 IoT dashboards
- 🔬 Lab equipment displays

---

## 🆘 Troubleshooting

### GUI doesn't appear:

```bash
# Check if GUI service is running
systemctl status lightdm

# Restart GUI
sudo systemctl restart lightdm

# Check logs
journalctl -u lightdm
```

### Can't connect via SSH:

```bash
# Enable SSH
sudo systemctl enable ssh
sudo systemctl start ssh
```

### Services not working:

```bash
# Check service status
sudo systemctl status <service-name>

# Restart service
sudo systemctl restart <service-name>

# View logs
journalctl -u <service-name>
```

---

## 📚 Documentation

- **[FINAL-OS-DETAILS.md](FINAL-OS-DETAILS.md)** - Complete feature documentation
- **[system.md](system.md)** - Development history and technical details
- **[GUI-PREVIEW.html](GUI-PREVIEW.html)** - Live GUI preview in browser

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📄 License

MIT License - feel free to use this project for personal or commercial purposes.

---

## 🙏 Acknowledgments

- Built with [pi-gen](https://github.com/RPi-Distro/pi-gen)
- GUI powered by [PyQt5](https://www.riverbankcomputing.com/software/pyqt/)
- AirPlay by [shairport-sync](https://github.com/mikebrady/shairport-sync)

---

## 📧 Support

Having issues? Please open an issue on GitHub!

---

**Made with ❤️ for the Raspberry Pi community**

🍓 **Raspberry Pi 3B Custom OS** - Where functionality meets beauty!
