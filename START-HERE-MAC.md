# 🚀 START HERE - Building on Apple Silicon Mac

**Detected:** Apple Silicon Mac (arm64)

## 📋 What You Need to Do

I've created all the scripts and guides you need. Here's your step-by-step process:

---

## ⚡ Quick Decision Guide

### Do you already have a Raspberry Pi with Raspberry Pi OS installed?

**YES** → Skip the VM! Use Quick Install (10 minutes):

```bash
# On your Raspberry Pi (via SSH):
cd ~
git clone https://github.com/YOUR_USERNAME/raspberry-pi-3b_customos-tv-cast.git
cd raspberry-pi-3b_customos-tv-cast
chmod +x INSTALL-ON-PI.sh
./INSTALL-ON-PI.sh
sudo reboot
```

**NO** → Need to build custom .img file first → Follow steps below

---

## 🖥️ Building Custom .img on Apple Silicon Mac

### Step 1: Install UTM (VM Software)

**Option A: Download from Website (Recommended)**

```bash
# Open this URL in your browser:
open https://mac.getutm.app/

# Download UTM.dmg
# Drag UTM to Applications folder
# Open UTM
```

**Option B: Install via Homebrew**

```bash
# If you have Homebrew installed:
brew install --cask utm

# If you don't have Homebrew:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install --cask utm
```

### Step 2: Download Ubuntu for ARM64

```bash
# Download Ubuntu for ARM (Apple Silicon)
cd ~/Downloads

# Ubuntu 22.04 LTS for ARM64
curl -L -o ubuntu-22.04-live-server-arm64.iso \
  https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.3-live-server-arm64.iso
```

This will download ~2.5GB (takes 5-15 minutes depending on your internet)

### Step 3: Create VM in UTM

1. **Open UTM** from Applications

2. **Click "+" → "Virtualize"**

3. **Select "Linux"**

4. **Configuration:**

   - **Boot ISO Image:** Browse to `~/Downloads/ubuntu-22.04-live-server-arm64.iso`
   - **Memory:** 4096 MB (or more if you have RAM available)
   - **CPU Cores:** 4 (or 2 minimum)
   - **Storage:** 40 GB

5. **Click "Save"** and name it `RaspberryPi-Builder`

6. **Click ▶️ Play button** to start the VM

### Step 4: Install Ubuntu in VM

1. **Select "Try or Install Ubuntu Server"**

2. **Follow installation:**

   - Language: English
   - Keyboard: Your layout
   - Network: Automatic DHCP
   - Proxy: (leave blank)
   - Mirror: (default)
   - Storage: Use entire disk
   - Profile setup:
     - Your name: builder
     - Server name: pi-builder
     - Username: builder
     - Password: (choose a password)
   - SSH: Install OpenSSH server (select with Space)
   - Featured snaps: (skip, don't select any)

3. **Wait for installation** (~10-15 minutes)

4. **Reboot when prompted**

5. **Login** with the username and password you created

### Step 5: Build Your Custom Image

**In the Ubuntu VM terminal:**

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker and build tools
sudo apt install -y git docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# IMPORTANT: Log out and log back in
# Press Ctrl+D to logout, then login again

# Clone your project
cd ~
git clone https://github.com/YOUR_USERNAME/raspberry-pi-3b_customos-tv-cast.git
cd raspberry-pi-3b_customos-tv-cast

# Start the build (this takes 30-60 minutes)
chmod +x build-custom-os.sh
./build-custom-os.sh 2>&1 | tee build.log

# The build log will show progress
# When it completes, your image will be at:
# ~/raspberry-pi-3b_customos-tv-cast/pi-gen/deploy/CustomRaspberryPi3B.img
```

**Go get coffee ☕ - this takes 30-60 minutes!**

### Step 6: Transfer Image to Your Mac

**In the Ubuntu VM:**

```bash
# Find the image
cd ~/raspberry-pi-3b_customos-tv-cast/pi-gen/deploy
ls -lh *.img

# Start a web server
python3 -m http.server 8000

# Keep this terminal open and note the IP address
# Run this in another terminal (Ctrl+Alt+T to open new terminal):
ip addr show | grep "inet "
# Look for an address like 192.168.x.x
```

**On your Mac (in a new terminal window):**

```bash
# Replace VM_IP with the IP address from above
cd ~/Downloads
curl -O http://VM_IP_ADDRESS:8000/CustomRaspberryPi3B.img

# Example:
# curl -O http://192.168.64.2:8000/CustomRaspberryPi3B.img
```

### Step 7: Flash to SD Card

**On your Mac:**

```bash
# Insert your SD card

# Find it
diskutil list
# Look for your SD card (usually /dev/disk2 or /dev/disk4)
# Check the size to make sure it's the right one!

# Unmount it (replace diskX with your SD card number)
diskutil unmountDisk /dev/diskX

# Flash the image (CAREFUL - this will erase the SD card!)
sudo dd if=~/Downloads/CustomRaspberryPi3B.img of=/dev/rdiskX bs=1m status=progress

# Eject
sudo diskutil eject /dev/diskX
```

### Step 8: Boot Your Raspberry Pi

1. **Insert SD card** into Raspberry Pi 3B
2. **Connect HDMI monitor** (optional - to see the GUI)
3. **Power on**
4. **Wait ~2 minutes** for first boot
5. **Your custom GUI appears automatically!** 🎉

---

## 📊 Time Estimates

| Task                   | Time          |
| ---------------------- | ------------- |
| Install UTM            | 5 min         |
| Download Ubuntu ISO    | 10-20 min     |
| Create & Install VM    | 20 min        |
| **Build Custom Image** | **30-60 min** |
| Transfer to Mac        | 5 min         |
| Flash to SD            | 10 min        |
| **TOTAL**              | **~2 hours**  |

---

## 🆘 Troubleshooting

### UTM VM is slow:

- Allocate more RAM (6-8 GB)
- Give more CPU cores (4-6)
- Make sure you selected "Virtualize" not "Emulate"

### Build fails with "out of space":

```bash
# In Ubuntu VM:
sudo docker system prune -a
df -h  # Check space
```

### Can't transfer file:

- Make sure VM and Mac are on same network
- Try using a USB drive mounted in VM
- Or use `scp` if you enabled SSH

### SD card won't boot:

- Verify the image file is complete (should be 2-4 GB)
- Try flashing again
- Use Raspberry Pi Imager as alternative

---

## 🎯 Still Too Complex?

### Use Quick Install Instead! (Much Easier)

1. Flash regular Raspberry Pi OS Lite using [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. Boot your Pi
3. Run the `INSTALL-ON-PI.sh` script
4. **Same result, way faster!**

See `BUILD-OPTIONS.md` for details.

---

## 📚 Files Created for You

- **`VM-SETUP-GUIDE.md`** - Detailed VM setup instructions
- **`BUILD-OPTIONS.md`** - All build methods compared
- **`INSTALL-ON-PI.sh`** - Quick install script (no VM needed)
- **`START-HERE-MAC.md`** - This file (you are here!)

---

## ✅ Next Steps

**Choose your path:**

1. **Quick & Easy:** Use `INSTALL-ON-PI.sh` on existing Raspberry Pi OS
2. **Custom Image:** Follow the steps above to build in VM

Both give you the same amazing custom OS with auto-starting GUI! 🍓

---

**Questions?** Check `BUILD-OPTIONS.md` for more details!
