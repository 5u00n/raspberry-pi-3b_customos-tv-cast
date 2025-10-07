# 🍓 Build Custom Raspberry Pi OS in Your Debian VM

## Quick Start - 3 Commands!

### 1️⃣ Copy Project to Your VM

**From your Mac terminal:**

```bash
# Find your VM's IP (check UTM or your VM settings)
# Replace <VM_IP> with your actual IP (e.g., 192.168.64.2)

cd /Users/suren/Documents/GitProjects/raspberry-pi-3b_customos-tv-cast
tar czf project.tar.gz overlays/ BUILD-IN-DEBIAN-VM.sh
scp project.tar.gz user@<VM_IP>:~/
```

### 2️⃣ SSH into Your VM

**From your Mac terminal:**

```bash
ssh user@<VM_IP>
```

### 3️⃣ Build the Custom OS

**Inside your Debian VM:**

```bash
# Extract project
tar xzf project.tar.gz

# Run the build script
chmod +x BUILD-IN-DEBIAN-VM.sh
./BUILD-IN-DEBIAN-VM.sh
```

**That's it!** The script will:

- ✅ Install all dependencies
- ✅ Clone pi-gen
- ✅ Configure your custom OS
- ✅ Build the complete image (~45-60 minutes)
- ✅ Create a flashable .img file

---

## Alternative: Clone from GitHub

**Inside your Debian VM:**

```bash
# Install git if needed
sudo apt-get update
sudo apt-get install -y git

# Clone your repository
git clone https://github.com/5u00n/raspberry-pi-3b_customos-tv-cast.git
cd raspberry-pi-3b_customos-tv-cast

# Run build script
chmod +x BUILD-IN-DEBIAN-VM.sh
./BUILD-IN-DEBIAN-VM.sh
```

---

## What Gets Built

Your custom OS includes:

- 🎨 **Custom Qt Desktop** (fullscreen on boot)
- 📊 **System monitoring** (CPU, RAM, Disk, Temperature)
- 🔧 **Service controls** (one-click start/stop)
- 📱 **AirPlay receiver** (shairport-sync)
- 📲 **Google Cast receiver**
- 🌐 **Web dashboard** (port 8080)
- 📁 **Samba file sharing**
- 🔐 **SSH enabled**
- ⚡ **Auto-login** as 'pi'
- ⚡ **Desktop auto-starts**

---

## Monitor Build Progress

**In another SSH session:**

```bash
# Watch build progress
tail -f pi-gen/work/*/build.log
```

---

## After Build Completes

### Copy Image to Your Mac

**From your Mac terminal:**

```bash
# Copy the built image from VM to Mac
scp user@<VM_IP>:~/raspberry-pi-3b_customos-tv-cast/pi-gen/deploy/*.img ~/Downloads/
```

### Flash to USB Drive

**On your Mac:**

```bash
# Find your USB drive
diskutil list

# Unmount it (replace disk4 with your USB drive)
diskutil unmountDisk /dev/disk4

# Flash the image
sudo dd if=~/Downloads/CustomRaspberryPi3B.img of=/dev/rdisk4 bs=1m status=progress

# Eject safely
sudo diskutil eject /dev/disk4
```

### Boot Your Raspberry Pi!

1. Insert USB drive into Raspberry Pi 3B
2. Power on
3. ✅ Desktop starts automatically
4. ✅ Your custom Qt GUI appears fullscreen
5. ✅ All features work out of the box!

---

## Troubleshooting

### Can't SSH to VM?

```bash
# Find VM IP address (run inside VM console)
ip addr show

# Enable SSH in VM (if not enabled)
sudo apt-get update
sudo apt-get install -y openssh-server
sudo systemctl start ssh
sudo systemctl enable ssh
```

### Build Fails?

```bash
# Check error in build log
tail -100 pi-gen/work/*/build.log

# Clean and retry
cd pi-gen
sudo rm -rf work deploy
cd ..
./BUILD-IN-DEBIAN-VM.sh
```

### Out of Disk Space?

```bash
# Check available space
df -h

# You need at least 8-10GB free
# Resize your VM disk if needed
```

---

## Default Credentials

**Raspberry Pi OS:**

- Username: `pi`
- Password: `raspberry`
- Hostname: `raspberrypi-custom`

**SSH Access:**

```bash
ssh pi@raspberrypi-custom.local
# or
ssh pi@<raspberry-pi-ip>
```

**Samba File Share:**

```
smb://raspberrypi-custom.local/pi
Username: pi
Password: raspberry
```

---

## Need Help?

The build script is fully automated and includes:

- ✅ Dependency installation
- ✅ Configuration setup
- ✅ Error handling
- ✅ Progress reporting

Just run `./BUILD-IN-DEBIAN-VM.sh` and wait! 🍓
