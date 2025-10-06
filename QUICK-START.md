# 🚀 Quick Start Guide

## Get Your Custom Raspberry Pi OS Running in Minutes!

---

## ⚡ Fastest Method (Recommended)

### What You Need:

- Raspberry Pi 3B
- SD card with Raspberry Pi OS installed
- Internet connection

### Installation (5 minutes):

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/raspberry-pi-3b_customos-tv-cast.git
cd raspberry-pi-3b_customos-tv-cast

# 2. Run the installer
chmod +x INSTALL-ON-PI.sh
./INSTALL-ON-PI.sh

# 3. Reboot
sudo reboot
```

**That's it!** Your beautiful PyQt5 GUI will appear automatically! 🎉

---

## 🎨 What You Get

### On Boot:

1. **Auto-login** - No password needed
2. **Desktop loads** - LXDE environment
3. **GUI appears** - Beautiful full-screen dashboard
4. **Services start** - AirPlay, Cast, Web dashboard, File sharing

### The Interface:

- **Real-time stats**: CPU, Memory, Disk, Temperature
- **Service monitoring**: All services with status indicators
- **System info**: Hostname, IP, Uptime, Time
- **Professional design**: Gradient purple theme, smooth animations

---

## 📱 Access Methods

### 1. Direct (GUI):

- Connect monitor via HDMI
- Power on
- **GUI shows automatically!**

### 2. SSH:

```bash
ssh pi@raspberrypi-custom
# Password: raspberry
```

### 3. Web Dashboard:

```
Open browser: http://raspberrypi-custom:8080
```

### 4. File Sharing:

```
Windows: \\raspberrypi-custom\pi
Mac:     smb://raspberrypi-custom/pi
```

### 5. Wireless Display:

- Open AirPlay/Cast menu on your phone
- Select "Raspberry Pi 3B Custom OS"
- Start casting!

---

## 🎯 Key Features

✅ **PyQt5 GUI** - Professional, beautiful interface  
✅ **Auto-start** - Everything ready on boot  
✅ **AirPlay** - Cast from iPhone/iPad  
✅ **Google Cast** - Cast from Android/Chrome  
✅ **Web Dashboard** - Remote browser access  
✅ **File Sharing** - Samba network access  
✅ **SSH** - Remote terminal access  
✅ **WiFi Tools** - Network monitoring

---

## 🔧 Quick Commands

### Restart GUI:

```bash
sudo systemctl restart lightdm
```

### Check Services:

```bash
systemctl status lightdm        # GUI
systemctl status ssh            # SSH
systemctl status smbd           # File sharing
systemctl status shairport-sync # AirPlay
```

### View Logs:

```bash
journalctl -u lightdm           # GUI logs
journalctl -f                   # All logs (live)
```

### Change Password:

```bash
passwd
```

---

## 📊 System Info

**Default Credentials:**

- Username: `pi`
- Password: `raspberry`

**Network Ports:**

- SSH: 22
- Web Dashboard: 8080
- Samba: 445
- AirPlay: 5000

**Disk Space:**

- Minimum: 8GB SD card
- Recommended: 16GB SD card

---

## 🎬 Demo

**See it in action:**

1. Open `GUI-PREVIEW.html` in your browser
2. Watch the live preview with real-time updates
3. See exactly what your Raspberry Pi will look like!

---

## 💡 Tips

### For Best Performance:

- Use Class 10 SD card or better
- Connect via Ethernet for faster speeds
- Use official Raspberry Pi power supply
- Keep system updated: `sudo apt update && sudo apt upgrade`

### For Touch Screens:

- GUI is optimized for 1024x600 displays
- Touch-friendly interface
- Full-screen mode by default

### For Headless Use:

- Access via SSH or web dashboard
- No monitor needed after initial setup
- All features work remotely

---

## 🆘 Need Help?

### GUI Not Showing?

```bash
sudo systemctl status lightdm
sudo systemctl restart lightdm
```

### Can't Connect?

```bash
# Check IP address
hostname -I

# Check SSH
sudo systemctl status ssh
```

### Services Not Working?

```bash
# Restart all services
sudo systemctl restart lightdm smbd ssh shairport-sync
```

---

## 📚 More Information

- **Full Documentation**: See `README.md`
- **Technical Details**: See `FINAL-OS-DETAILS.md`
- **Development History**: See `system.md`

---

## 🎉 You're All Set!

Your Raspberry Pi is now a powerful, beautiful system with:

- Professional GUI interface
- Wireless display capabilities
- Remote access and control
- File sharing
- Network monitoring tools

**Enjoy your custom Raspberry Pi OS!** 🍓

---

**Questions?** Open an issue on GitHub!  
**Love it?** Give us a star ⭐
