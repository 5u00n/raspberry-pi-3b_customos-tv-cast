# ✅ YOU'RE READY TO BUILD!

## 🎉 Good News!

Your Mac is set up with:

- ✅ **Apple Silicon Mac** (arm64)
- ✅ **Homebrew** installed
- ✅ **UTM** installed

You just need to download Ubuntu and create the VM!

---

## 🚀 Quick Start (3 Simple Commands)

### Step 1: Download Ubuntu ISO (~10 minutes)

```bash
cd ~/Downloads
curl -# -L -o ubuntu-22.04-live-server-arm64.iso \
  https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.3-live-server-arm64.iso
```

**This downloads ~2.5 GB. Get a coffee! ☕**

---

### Step 2: Create VM in UTM

1. **Open UTM** from Applications
2. **Click "Create a New Virtual Machine"**
3. **Select "Virtualize"** (important for Apple Silicon!)
4. **Choose "Linux"**
5. **Browse** and select: `~/Downloads/ubuntu-22.04-live-server-arm64.iso`
6. **Memory:** 4096 MB (or 8192 if you have 16GB+ RAM)
7. **CPU Cores:** 4 (or 2 minimum)
8. **Storage:** 40 GB
9. **Save** as "RaspberryPi-Builder"
10. **Click ▶️** to start

---

### Step 3: Install Ubuntu (~15 minutes)

When Ubuntu boots:

1. Select **"Try or Install Ubuntu Server"**
2. Follow prompts:
   - Language: English
   - Keyboard: Your layout
   - Type: Ubuntu Server (default)
   - Network: Automatic (default)
   - Proxy: (blank)
   - Mirror: (default)
   - Storage: **Use entire disk**
   - Profile:
     - Name: builder
     - Server: pi-builder
     - Username: builder
     - Password: `raspberry` (or your choice)
   - SSH: **Enable "Install OpenSSH server"** (important!)
   - Snaps: (skip all)
3. Wait for installation
4. **Reboot** when prompted
5. **Login** with builder/raspberry

---

### Step 4: Build Your Custom OS (~45 minutes)

**In the Ubuntu VM terminal:**

Copy and paste these commands one at a time:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y git docker.io
sudo systemctl start docker
sudo usermod -aG docker $USER

# IMPORTANT: Log out and log back in for Docker permissions
# Type: exit
# Then log back in
```

**After logging back in:**

```bash
# Clone your project
git clone https://github.com/YOUR_USERNAME/raspberry-pi-3b_customos-tv-cast.git
cd raspberry-pi-3b_customos-tv-cast

# Start the build
chmod +x build-custom-os.sh
./build-custom-os.sh
```

**🎮 Now go play a game or watch a show - this takes 30-60 minutes!**

---

### Step 5: Get Your Image (~5 minutes)

**In Ubuntu VM:**

```bash
# Start a simple web server
cd ~/raspberry-pi-3b_customos-tv-cast/pi-gen/deploy
python3 -m http.server 8000

# In a NEW terminal in VM (Ctrl+Alt+T):
hostname -I
# Note the IP address (like 192.168.64.2)
```

**On your Mac (new Terminal window):**

```bash
cd ~/Downloads

# Replace 192.168.64.2 with your VM's IP
curl -O http://192.168.64.2:8000/CustomRaspberryPi3B.img
```

---

### Step 6: Flash to SD Card (~10 minutes)

```bash
# Insert SD card

# Find it
diskutil list
# Look for your SD card (check size to confirm!)

# Unmount (replace disk2 with your SD card number)
diskutil unmountDisk /dev/disk2

# Flash (CAREFUL - double-check disk number!)
sudo dd if=~/Downloads/CustomRaspberryPi3B.img of=/dev/rdisk2 bs=1m status=progress

# Eject
sudo diskutil eject /dev/disk2
```

---

### Step 7: Boot Your Pi! 🎉

1. Insert SD card into Raspberry Pi 3B
2. Connect HDMI monitor (optional)
3. Power on
4. **Your custom GUI appears automatically!**

---

## ⏱️ Time Breakdown

| Step                 | Time             |
| -------------------- | ---------------- |
| Download Ubuntu ISO  | 10 min           |
| Install Ubuntu in VM | 15 min           |
| **Build Custom OS**  | **30-60 min**    |
| Transfer to Mac      | 5 min            |
| Flash to SD          | 10 min           |
| **TOTAL**            | **~1.5-2 hours** |

---

## 🆘 Troubleshooting

### ISO download is slow?

- Download overnight if internet is slow
- Or download from alternate mirror

### VM won't start?

- Make sure you selected "Virtualize" not "Emulate"
- Allocate more RAM if available
- Give more CPU cores

### Build fails?

```bash
# Free up space:
sudo docker system prune -a

# Check space:
df -h
```

### Can't transfer file?

- Try using a USB drive mounted in VM
- Or check VM network settings

---

## 🎯 OR: Use Quick Install (Way Easier!)

If VM setup seems too complex:

1. **Flash regular Raspberry Pi OS** using [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. **Boot Pi and SSH in:** `ssh pi@raspberrypi.local`
3. **Run:**
   ```bash
   git clone <your-repo>
   cd raspberry-pi-3b_customos-tv-cast
   ./INSTALL-ON-PI.sh
   sudo reboot
   ```
4. **Done!** Same features, 10 minutes total!

---

## 📚 All Your Guides

- **`READY-TO-BUILD.md`** ← You are here (quickstart)
- **`START-HERE-MAC.md`** - Detailed step-by-step for Mac
- **`VM-SETUP-GUIDE.md`** - Complete VM guide
- **`BUILD-OPTIONS.md`** - All methods compared
- **`INSTALL-ON-PI.sh`** - Quick install script

---

## ✨ What You Get

Your custom Raspberry Pi OS includes:

- 🎨 **Beautiful PyQt5 GUI** (auto-starts on boot)
- 📱 **AirPlay receiver** (cast from iPhone/iPad)
- 📲 **Google Cast** (cast from Android/Chrome)
- 🌐 **Web dashboard** (port 8080)
- 📁 **File sharing** (Samba)
- 🔐 **SSH access**
- 🔒 **WiFi tools**
- ⚡ **Auto-login** (no password)

All automatically configured and ready to use!

---

## 🎬 Ready?

### To start building right now:

```bash
# Download Ubuntu ISO
cd ~/Downloads && curl -# -L -o ubuntu-22.04-live-server-arm64.iso \
  https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.3-live-server-arm64.iso

# Then open UTM and follow Step 2 above!
```

**Let's build your custom Raspberry Pi OS! 🍓**
