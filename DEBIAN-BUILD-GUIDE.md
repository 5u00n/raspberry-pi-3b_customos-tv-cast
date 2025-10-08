# 🐧 Building on Debian/Ubuntu - Complete Guide

## Quick Start

If you have a **Debian or Ubuntu** system, run:

```bash
chmod +x build-debian.sh
./build-debian.sh
```

That's it! The script will:

- ✅ Install all dependencies
- ✅ Clone and configure pi-gen
- ✅ Build your custom Raspberry Pi OS
- ✅ Create a flashable image

**Build time:** 30-60 minutes

---

## Manual Build Process

If you prefer to run commands manually:

### Step 1: Install Dependencies

```bash
sudo apt-get update
sudo apt-get install -y \
    coreutils quilt parted qemu-user-static debootstrap zerofree zip \
    dosfstools libarchive-tools libcap2-bin grep rsync xz-utils file \
    git curl bc qemu-utils kpartx arch-test
```

### Step 2: Clone pi-gen

```bash
git clone https://github.com/RPi-Distro/pi-gen.git
cd pi-gen
git checkout 2024-07-04-raspios-bookworm
```

### Step 3: Configure Build

```bash
cat > config << 'EOF'
IMG_NAME='CustomRaspberryPi3B'
RELEASE=bookworm
DEPLOY_COMPRESSION=zip
ENABLE_SSH=1
STAGE_LIST="stage0 stage1 stage2"
TARGET_HOSTNAME=raspberrypi-custom
FIRST_USER_NAME=pi
FIRST_USER_PASS=raspberry
DISABLE_FIRST_BOOT_USER_RENAME=1
EOF
```

### Step 4: Add Custom Packages

```bash
mkdir -p stage2/99-custom-packages

cat > stage2/99-custom-packages/00-packages << 'EOF'
python3
python3-pip
python3-pyqt5
python3-psutil
xserver-xorg
xinit
lightdm
lxde-core
shairport-sync
avahi-daemon
samba
nginx
EOF

cat > stage2/99-custom-packages/01-run.sh << 'EOF'
#!/bin/bash -e
on_chroot << 'CHROOT'
pip3 install --break-system-packages flask flask-cors requests psutil
systemctl enable ssh shairport-sync avahi-daemon lightdm
systemctl set-default graphical.target
CHROOT
EOF

chmod +x stage2/99-custom-packages/01-run.sh
```

### Step 5: Build

```bash
sudo ./build.sh
```

### Step 6: Flash to SD Card

```bash
# Find your SD card
lsblk

# Unmount it (replace sdX with your device)
sudo umount /dev/sdX*

# Flash the image
sudo dd if=deploy/CustomRaspberryPi3B.img of=/dev/sdX bs=4M status=progress

# Sync and eject
sync
sudo eject /dev/sdX
```

---

## Using Docker on Debian/Ubuntu

```bash
# Install Docker
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker

# Run pi-gen in Docker
cd pi-gen
sudo ./build-docker.sh
```

---

## GitHub Actions (Cloud Build)

Your repository already has GitHub Actions configured!

### To use it:

1. **Push to GitHub:**

   ```bash
   git push origin main
   ```

2. **Check Actions tab** on GitHub

3. **Download artifact** when build completes

### Local execution of GitHub Actions workflow:

The build steps from `.github/workflows/build-custom-os.yml` can be run locally:

```bash
# Install dependencies (from workflow)
sudo apt-get update
sudo apt-get install -y coreutils quilt parted qemu-user-static \
    debootstrap zerofree zip dosfstools libarchive-tools libcap2-bin \
    grep rsync xz-utils file git curl bc qemu-utils kpartx arch-test

# Clone and configure pi-gen (from workflow)
rm -rf pi-gen
git clone https://github.com/RPi-Distro/pi-gen.git
cd pi-gen
git checkout 2024-07-04-raspios-bookworm || git checkout master

# Create config and build
# (See manual steps above or run build-debian.sh)
```

---

## System Requirements

### Minimum:

- 2 CPU cores
- 4GB RAM
- 20GB free disk space
- Debian 11+ or Ubuntu 20.04+

### Recommended:

- 4 CPU cores
- 8GB RAM
- 30GB free disk space
- Ubuntu 22.04 LTS

---

## Build Options

### Fast Build (Minimal)

```bash
STAGE_LIST="stage0 stage1 stage2" sudo ./build.sh
```

**Time:** ~30 minutes  
**Size:** ~2GB image  
**Includes:** Base system + your custom features

### Full Build (Complete)

```bash
STAGE_LIST="stage0 stage1 stage2 stage3 stage4 stage5" sudo ./build.sh
```

**Time:** ~90 minutes  
**Size:** ~8GB image  
**Includes:** Full desktop + all Raspberry Pi tools

### Desktop Only

```bash
STAGE_LIST="stage0 stage1 stage2" sudo ./build.sh
```

Best for your use case!

---

## Testing Your Build

### Option 1: Real Hardware

Flash to SD card and test on Raspberry Pi 3B

### Option 2: QEMU Emulation

```bash
sudo apt-get install -y qemu-system-arm

qemu-system-arm \
    -M versatilepb \
    -cpu arm1176 \
    -m 256 \
    -kernel kernel-qemu \
    -hda deploy/CustomRaspberryPi3B.img \
    -append "root=/dev/sda2"
```

---

## Troubleshooting

### "debootstrap: command not found"

```bash
sudo apt-get install -y debootstrap
```

### "Permission denied" errors

- Use `sudo` for build.sh
- Ensure your user is in the `docker` group (if using Docker)

### Build fails with "No space left on device"

- Free up disk space
- Need at least 20GB free

### "Invalid release" error

- Make sure you're using a supported release: `bookworm`, `bullseye`, or `buster`

### Build hangs or is very slow

- Check CPU/RAM usage
- Consider using a faster machine or cloud instance
- Use SSD instead of HDD

---

## Output Files

After build completes, you'll find:

```
pi-gen/deploy/
├── CustomRaspberryPi3B.img       # Main image file
├── CustomRaspberryPi3B.img.zip   # Compressed version
├── CustomRaspberryPi3B.info      # Build info
└── build.log                      # Build logs
```

---

## Features in Your Build

✅ **Desktop Environment** - LXDE lightweight desktop  
✅ **PyQt5 GUI** - Custom dashboard (auto-starts)  
✅ **Auto-login** - No password needed  
✅ **AirPlay** - Cast from iPhone/iPad  
✅ **File Sharing** - Samba server  
✅ **SSH** - Remote access enabled  
✅ **Web Dashboard** - Port 8080

---

## Alternative: Quick Install Method

If you just want to **install features on existing Raspberry Pi OS**:

```bash
# On your Raspberry Pi:
git clone https://github.com/YOUR_USERNAME/raspberry-pi-3b_customos-tv-cast.git
cd raspberry-pi-3b_customos-tv-cast

# For Lite version:
./setup_pi_features.sh

# For Desktop version:
./INSTALL-ON-PI.sh

# Reboot
sudo reboot
```

**Advantages:**

- ✅ Much faster (10 min vs 60 min)
- ✅ No build required
- ✅ Easy to update
- ✅ Same features

**Use custom image build when:**

- 🔧 Mass deployment needed
- 🔧 Factory provisioning
- 🔧 Multiple identical Pis

---

## Cloud Build Options

### AWS EC2

```bash
# Launch Ubuntu instance (t3.medium or larger)
ssh ubuntu@your-instance

# Install dependencies and build
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/RPi-Distro/pi-gen.git
cd pi-gen
# ... (follow manual steps)
sudo ./build.sh

# Download the image
scp ubuntu@your-instance:~/pi-gen/deploy/*.img ./
```

### DigitalOcean Droplet

Same as AWS, use Ubuntu 22.04 droplet

### Google Cloud Platform

Use Ubuntu VM, follow same steps

---

## Best Practices

### 1. Clean builds

```bash
# Before building again
sudo rm -rf pi-gen/work pi-gen/deploy
```

### 2. Save configs

```bash
# Keep your config file
cp pi-gen/config my-custom-config.txt
```

### 3. Version control

```bash
# Save your stage modifications
tar czf my-custom-stages.tar.gz pi-gen/stage*/99-*
```

### 4. Test incrementally

- Build with minimal stages first
- Add features one at a time
- Test after each addition

---

## Performance Tips

### Speed up builds:

1. **Use SSD** for build directory
2. **Increase RAM** (8GB recommended)
3. **More CPU cores** = faster
4. **Local mirror** for apt packages
5. **Disable compression** during testing:
   ```bash
   echo "DEPLOY_COMPRESSION=none" >> config
   ```

### Reduce image size:

1. Remove unnecessary packages
2. Use Lite base instead of Desktop
3. Clean apt cache in final stage
4. Compress final image

---

## Scripts in This Repository

| Script                 | Purpose                  | Run Where       |
| ---------------------- | ------------------------ | --------------- |
| `build-debian.sh`      | **Full automated build** | Debian/Ubuntu   |
| `setup_pi_features.sh` | Install on existing OS   | Raspberry Pi    |
| `INSTALL-ON-PI.sh`     | Install with desktop     | Raspberry Pi    |
| `build-with-docker.sh` | Build using Docker       | Any with Docker |
| `BUILD-IN-VM.sh`       | VM setup guide           | macOS           |

---

## Next Steps

1. ✅ Build your image using `build-debian.sh`
2. ✅ Flash to SD card
3. ✅ Boot Raspberry Pi
4. ✅ Test all features
5. ✅ Customize as needed
6. ✅ Share or deploy!

---

## Support

- **GitHub Issues:** Report problems
- **README.md:** Feature overview
- **BUILD-OPTIONS.md:** Alternative methods
- **SETUP_GUIDE.md:** Post-install guide

---

## 🎉 Summary

**Fastest way to build on Debian/Ubuntu:**

```bash
./build-debian.sh
```

**Wait 30-60 minutes, then flash and enjoy!** 🍓
