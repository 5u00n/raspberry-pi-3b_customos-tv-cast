# 🖥️ Setting Up Linux VM on macOS to Build Custom Raspberry Pi Image

## Step 1: Install Virtualization Software

### For Intel Mac (Recommended: VirtualBox):

1. **Download VirtualBox:**

   ```bash
   # Visit: https://www.virtualbox.org/wiki/Downloads
   # Download "macOS / Intel hosts"
   ```

2. **Install VirtualBox:**
   - Open the downloaded .dmg file
   - Run VirtualBox.pkg installer
   - Follow installation prompts
   - Grant necessary permissions in System Preferences > Security & Privacy

### For Apple Silicon Mac (M1/M2/M3) (Recommended: UTM):

1. **Download UTM:**

   ```bash
   # Visit: https://mac.getutm.app/
   # Download UTM (Free version)
   # Or install via Homebrew:
   brew install --cask utm
   ```

2. **Install UTM:**
   - Open the downloaded .dmg
   - Drag UTM to Applications
   - Open UTM from Applications

---

## Step 2: Download Ubuntu ISO

```bash
# Download Ubuntu 22.04 LTS Desktop
# Visit: https://ubuntu.com/download/desktop

# Direct link:
curl -L -o ~/Downloads/ubuntu-22.04.3-desktop-amd64.iso \
  https://releases.ubuntu.com/22.04/ubuntu-22.04.3-desktop-amd64.iso
```

**File size:** ~4.5 GB (will take 5-15 minutes to download)

---

## Step 3: Create Ubuntu VM

### For VirtualBox (Intel Mac):

1. **Open VirtualBox** and click "New"

2. **Configure VM:**

   - Name: `RaspberryPi-Builder`
   - Type: Linux
   - Version: Ubuntu (64-bit)
   - Memory: 4096 MB (4 GB)
   - Hard disk: Create virtual hard disk now
   - Hard disk type: VDI
   - Storage: Dynamically allocated
   - Size: 30 GB

3. **Settings > System:**

   - Processors: 2 CPUs minimum (or more if available)
   - Enable PAE/NX

4. **Settings > Storage:**

   - Click "Empty" under Controller: IDE
   - Click disk icon on right
   - Choose "Choose a disk file"
   - Select the Ubuntu ISO you downloaded

5. **Click Start** to boot the VM

### For UTM (Apple Silicon Mac):

1. **Open UTM** and click "+"

2. **Select "Virtualize"** (not Emulate)

3. **Choose Linux**

4. **Configure:**

   - Browse and select Ubuntu ISO
   - Memory: 4096 MB
   - CPU Cores: 2 or more
   - Storage: 30 GB

5. **Click Create** and then **Start**

---

## Step 4: Install Ubuntu in VM

1. **When Ubuntu boots**, select "Try or Install Ubuntu"

2. **Choose "Install Ubuntu"**

3. **Installation options:**

   - Language: English
   - Keyboard: Your layout
   - Updates: Normal installation
   - Installation type: Erase disk and install Ubuntu (don't worry, this is only the VM disk)

4. **Create user account:**

   - Your name: (your choice)
   - Computer name: raspberrypi-builder
   - Username: builder (or your choice)
   - Password: (choose a password)

5. **Wait for installation** (~15 minutes)

6. **Restart when prompted**

7. **Remove ISO:**
   - VirtualBox: Devices > Optical Drives > Remove disk from virtual drive
   - UTM: Click CD icon and eject

---

## Step 5: Setup Ubuntu for Building

Once Ubuntu is running in your VM:

1. **Open Terminal** in Ubuntu (Ctrl+Alt+T)

2. **Update system:**

   ```bash
   sudo apt update
   sudo apt upgrade -y
   ```

3. **Install build tools:**

   ```bash
   sudo apt install -y git docker.io build-essential
   sudo systemctl start docker
   sudo systemctl enable docker
   sudo usermod -aG docker $USER
   ```

4. **Log out and log back in** (for Docker permissions)

5. **Clone your repository:**

   ```bash
   cd ~
   git clone https://github.com/YOUR_USERNAME/raspberry-pi-3b_customos-tv-cast.git
   cd raspberry-pi-3b_customos-tv-cast
   ```

6. **Start the build:**

   ```bash
   chmod +x build-custom-os.sh
   ./build-custom-os.sh
   ```

7. **Wait 30-60 minutes** for build to complete

---

## Step 6: Copy Image to Mac

### Method 1: Shared Folder (Recommended)

#### VirtualBox:

1. **In VirtualBox menu:** Devices > Shared Folders > Shared Folder Settings
2. Click "+" to add folder
3. Folder Path: Choose a folder on your Mac (e.g., ~/Downloads)
4. Folder Name: `share`
5. Check "Auto-mount" and "Make Permanent"

**In Ubuntu VM:**

```bash
# Install Guest Additions first (if not already)
sudo apt install virtualbox-guest-utils

# Copy image to shared folder
sudo cp ~/raspberry-pi-3b_customos-tv-cast/pi-gen/deploy/*.img /media/sf_share/
```

#### UTM:

1. **In UTM:** Click the disk icon in toolbar
2. Select "New Shared Directory"
3. Choose a folder on your Mac
4. Name it `share`

**In Ubuntu VM:**

```bash
# Mount shared folder
sudo mkdir -p /mnt/share
sudo mount -t 9p -o trans=virtio share /mnt/share -oversion=9p2000.L

# Copy image
sudo cp ~/raspberry-pi-3b_customos-tv-cast/pi-gen/deploy/*.img /mnt/share/
```

### Method 2: Transfer via Network

**In Ubuntu VM:**

```bash
# Start a simple web server
cd ~/raspberry-pi-3b_customos-tv-cast/pi-gen/deploy
python3 -m http.server 8000
```

**On your Mac:**

```bash
# Find VM IP (look in Ubuntu VM terminal)
# In Ubuntu, run: ip addr show

# Download file
curl -O http://VM_IP_ADDRESS:8000/CustomRaspberryPi3B.img
```

---

## Step 7: Flash Image to SD Card

Once you have the .img file on your Mac:

```bash
# Find your SD card
diskutil list

# Unmount (replace diskX with your SD card)
diskutil unmountDisk /dev/diskX

# Flash image
sudo dd if=CustomRaspberryPi3B.img of=/dev/rdiskX bs=1m status=progress

# Eject
sudo diskutil eject /dev/diskX
```

---

## Troubleshooting

### VM Won't Boot:

- **Intel Mac:** Enable VT-x in BIOS/UEFI (usually enabled by default)
- **Apple Silicon:** Make sure you selected "Virtualize" not "Emulate"

### Not Enough Disk Space:

- Free up space on your Mac
- Ensure VM has 30GB+ allocated

### Build Fails in VM:

- Increase RAM to 6GB or 8GB if possible
- Check internet connection in VM
- Run: `sudo docker system prune -a` to free space

### Can't Transfer File:

- Use Method 2 (web server) if shared folders don't work
- Or use `scp` if SSH is enabled

---

## Quick Reference Commands

### In Ubuntu VM:

```bash
# Check disk space
df -h

# Check memory
free -h

# Monitor build progress
tail -f ~/raspberry-pi-3b_customos-tv-cast/pi-gen/work/build.log

# Clean up after build
cd ~/raspberry-pi-3b_customos-tv-cast/pi-gen
sudo rm -rf work deploy
```

### VM Resource Recommendations:

- **Minimum:** 4GB RAM, 2 CPU cores, 30GB disk
- **Recommended:** 8GB RAM, 4 CPU cores, 50GB disk
- **Optimal:** 16GB RAM, 6 CPU cores, 100GB disk

---

## Estimated Time:

| Step                    | Time          |
| ----------------------- | ------------- |
| Download VirtualBox/UTM | 5 min         |
| Download Ubuntu ISO     | 10-20 min     |
| Create VM               | 5 min         |
| Install Ubuntu          | 15 min        |
| Setup build tools       | 10 min        |
| **Build custom image**  | **30-60 min** |
| Transfer to Mac         | 5 min         |
| Flash to SD card        | 10 min        |
| **TOTAL**               | **~2 hours**  |

---

## Alternative: Quick Install (No VM Needed!)

If this seems too complex, remember you can use the **Quick Install method**:

1. Flash standard Raspberry Pi OS to SD card (5 min)
2. Boot Pi and SSH in
3. Run `./INSTALL-ON-PI.sh` (10 min)
4. Reboot
5. **Done!** Same features, much faster!

The Quick Install method gives you the **exact same result** but skips all the VM complexity.

---

Choose the method that works best for you! 🍓
