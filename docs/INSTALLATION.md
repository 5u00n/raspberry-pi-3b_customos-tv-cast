# Installation Guide

## Prerequisites

### Hardware Requirements

- Raspberry Pi 3B (Model B)
- MicroSD card (16GB+ recommended, Class 10)
- Power supply (5V/2.5A minimum)
- HDMI cable and display (for initial setup)
- USB keyboard and mouse (for initial setup)
- WiFi network access

### Software Requirements

- Host computer with Linux/macOS/Windows
- Docker installed and running
- Git
- SD card reader/writer

## Quick Installation

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd my_rasp_OS
```

### 2. Build the OS Image

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run the build script
./scripts/build.sh
```

**Note**: This process may take 30-60 minutes depending on your internet connection and system performance.

### 3. Flash to SD Card

**⚠️ WARNING**: This will completely erase the target SD card!

```bash
# List available devices
lsblk

# Flash the image (replace sdX with your SD card device)
./scripts/flash.sh /dev/sdX
```

**Important**: Make sure you're targeting the correct device. Double-check the device name to avoid accidentally erasing your system drive.

### 4. Configure WiFi (Optional)

Before first boot, you can configure WiFi by editing the `configs/wpa_supplicant.conf` file and copying it to the boot partition of the SD card.

### 5. Boot Your Raspberry Pi

1. Insert the SD card into your Pi 3B
2. Connect HDMI display, keyboard, and mouse
3. Power on the Pi
4. Wait for the first boot setup (5-10 minutes)
5. The system will automatically reboot

### 6. Access Your Pi

After setup completes, you can access your Pi in several ways:

- **Web Interface**: `http://<pi-ip>:8080`
- **SSH**: `ssh pi@<pi-ip>` (password: `raspberry`)
- **File Server**: `\\<pi-ip>\wifi-captures` (Windows) or `smb://<pi-ip/wifi-captures` (macOS/Linux)

## Manual Installation

If you prefer to build manually or encounter issues with the automated build:

### 1. Download Base OS

```bash
# Download Raspberry Pi OS Lite
wget https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2023-12-05/2023-12-05-raspios-bookworm-armhf-lite.img.xz

# Extract the image
xz -d 2023-12-05-raspios-bookworm-armhf-lite.img.xz
```

### 2. Mount and Modify

```bash
# Mount the image
sudo losetup -P /dev/loop0 2023-12-05-raspios-bookworm-armhf-lite.img

# Mount the boot and root partitions
sudo mount /dev/loop0p1 /mnt/boot
sudo mount /dev/loop0p2 /mnt/root

# Copy configuration files
sudo cp configs/config.txt /mnt/boot/
sudo cp configs/wpa_supplicant.conf /mnt/boot/

# Copy overlay files
sudo cp -r overlays/* /mnt/root/

# Unmount
sudo umount /mnt/boot /mnt/root
sudo losetup -d /dev/loop0
```

### 3. Flash and Boot

Follow steps 4-6 from the Quick Installation section above.

## Configuration

### WiFi Setup

Edit `/boot/wpa_supplicant.conf` on the SD card:

```bash
network={
    ssid="YOUR_WIFI_SSID"
    psk="YOUR_WIFI_PASSWORD"
    key_mgmt=WPA-PSK
}
```

### Custom Settings

Modify `/boot/config.txt` for hardware-specific configurations:

- CPU overclocking
- GPU memory allocation
- HDMI settings
- GPIO configurations

### Service Configuration

Services are automatically configured during first boot, but you can modify them:

- **AirPlay**: `/etc/shairport-sync.conf`
- **WiFi Tools**: `/etc/wifi-tools/config.json`
- **Samba**: `/etc/samba/smb.conf`
- **Nginx**: `/etc/nginx/sites-available/remote-control`

## Troubleshooting

### Common Issues

#### Build Failures

- Ensure Docker is running
- Check available disk space (20GB+ required)
- Verify internet connection
- Check build logs in `build/build.log`

#### Boot Issues

- Verify SD card is properly flashed
- Check power supply (5V/2.5A minimum)
- Ensure HDMI cable is connected
- Check boot partition for configuration files

#### Network Issues

- Verify WiFi credentials in `wpa_supplicant.conf`
- Check WiFi country code setting
- Ensure WiFi is enabled in `config.txt`
- Check network logs: `journalctl -u networking`

#### Service Issues

- Check service status: `systemctl status <service-name>`
- View service logs: `journalctl -u <service-name>`
- Restart services: `sudo systemctl restart <service-name>`

### Getting Help

1. **Check Logs**: `/var/log/setup.log` for setup issues
2. **Service Logs**: Use `journalctl` for service-specific problems
3. **Build Logs**: Check `build/build.log` for build issues
4. **GitHub Issues**: Create an issue with detailed error information

## Security Considerations

### Default Credentials

- **SSH**: `pi:raspberry`
- **Samba**: `pi:raspberry`
- **Web Interface**: No authentication by default

### Recommendations

1. Change default passwords immediately after first boot
2. Configure firewall rules
3. Use strong WiFi passwords
4. Regularly update the system
5. Monitor logs for suspicious activity

### Legal Compliance

- Ensure compliance with local laws regarding WiFi security tools
- Use only on networks you own or have permission to test
- Respect privacy and data protection regulations

## Updates and Maintenance

### System Updates

```bash
sudo apt update && sudo apt upgrade
```

### Automatic Updates

The system is configured with unattended-upgrades for security updates.

### Backup

Regularly backup your configuration and data:

```bash
# Backup configuration
sudo tar -czf config-backup.tar.gz /boot/config.txt /etc/wifi-tools/

# Backup WiFi captures
sudo tar -czf captures-backup.tar.gz /home/pi/wifi-captures/
```

## Support

For additional support:

- Check the troubleshooting section above
- Review build and service logs
- Create GitHub issues with detailed information
- Consult the project documentation

---

**Note**: This is a custom OS build. Use at your own risk and ensure compliance with applicable laws and regulations.
