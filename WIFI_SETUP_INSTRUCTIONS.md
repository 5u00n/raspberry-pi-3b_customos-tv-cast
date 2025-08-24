# 📶 WiFi Setup Instructions

## 🔧 **How to Connect Your Pi to Your Mac's WiFi**

### **Step 1: Get Your Mac's WiFi Information**

1. **On your Mac**, click the WiFi icon in the menu bar
2. **Note down** your WiFi network name (SSID)
3. **Note down** your WiFi password

### **Step 2: Configure WiFi Credentials**

1. **Edit the file**: `configs/wifi-credentials.txt`
2. **WiFi networks are already configured** with your credentials:

   ```bash
   # Primary network (highest priority)
   WIFI_SSID_1="connection"
   WIFI_PASSWORD_1="12qw34er"
   WIFI_PRIORITY_1=1

   # Secondary network (lower priority)
   WIFI_SSID_2="Nomita"
   WIFI_PASSWORD_2="200019981996"
   WIFI_PRIORITY_2=2
   ```

3. **The Pi will automatically try** to connect to "connection" first, then "Nomita" if the first fails

### **Step 3: Build and Flash**

1. **Run the build script**: `./scripts/build.sh`
2. **Flash to SD card**: `./scripts/flash.sh /dev/sdX`
3. **Copy WiFi credentials** to the boot partition of the SD card:

   ```bash
   # After flashing, mount the boot partition
   sudo mount /dev/sdX1 /mnt/boot

   # Copy your WiFi credentials
   cp configs/wifi-credentials.txt /mnt/boot/

   # Unmount
   sudo umount /mnt/boot
   ```

### **Step 4: Boot Your Pi**

1. **Insert SD card** into Pi 3B
2. **Power on** the Pi
3. **Wait for setup** (5-10 minutes)
4. **Pi will automatically connect** to your WiFi network

---

## 🌐 **What Happens on Boot:**

1. **Pi boots** → Auto-login as `pi` user (no password)
2. **Desktop starts** → TV-like interface appears
3. **WiFi connects** → Automatically to your Mac's network
4. **Services start** → AirPlay, Cast, WiFi tools all running
5. **Ready to use** → Pi appears on your network

---

## 📱 **Access Your Pi:**

### **From Your Mac:**

- **Web Dashboard**: `http://<pi-ip>:8080`
- **TV Interface**: `http://<pi-ip>:8081`
- **File Server**: `smb://<pi-ip>/wifi-captures`

### **From Any Device:**

- **Remote Control**: `http://<pi-ip>:8080`
- **Cast Device**: "Raspberry Pi 3B" will appear in Cast apps

---

## 🔍 **Troubleshooting:**

### **WiFi Not Connecting:**

```bash
# Check WiFi status
sudo systemctl status wpa_supplicant
sudo systemctl status networking

# View WiFi logs
sudo journalctl -u wpa_supplicant -f
sudo journalctl -u networking -f

# Manual WiFi setup
sudo /usr/local/bin/wifi-setup.py scan
sudo /usr/local/bin/wifi-setup.py add "connection" "12qw34er" 1
sudo /usr/local/bin/wifi-setup.py add "Nomita" "200019981996" 2
```

### **Desktop Not Starting:**

```bash
# Check desktop service
sudo systemctl status desktop-ui

# View desktop logs
sudo journalctl -u desktop-ui -f

# Manual start
sudo systemctl start desktop-ui
```

### **Services Not Working:**

```bash
# Check all services
sudo systemctl status airplay
sudo systemctl status google-cast
sudo systemctl status wifi-tools

# Restart services
sudo systemctl restart airplay
sudo systemctl restart google-cast
sudo systemctl restart wifi-tools
```

---

## 🎯 **Expected Results:**

✅ **Auto-login** - No password needed  
✅ **Desktop UI** - TV-like interface shows all features  
✅ **WiFi Connected** - Automatically to your Mac's network  
✅ **AirPlay Working** - Pi appears as AirPlay receiver  
✅ **Google Cast Working** - Pi appears as Cast device  
✅ **Remote Control** - Web interface accessible from any device  
✅ **WiFi Tools** - Background security scanning  
✅ **File Server** - Easy access to captured data

---

## 🚀 **Ready to Go!**

After following these steps, your Pi 3B will:

1. **Boot automatically** without password
2. **Show a beautiful TV interface** with all features
3. **Connect to your WiFi** automatically
4. **Work as a wireless display** for AirPlay and Cast
5. **Be accessible** from any device on your network

**Your Pi 3B becomes the ultimate plug-and-play wireless display hub!** 🍓✨
