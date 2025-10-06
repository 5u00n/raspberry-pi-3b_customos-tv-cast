# Manual Raspberry Pi Service Check

Your Raspberry Pi is running and accessible, but the services may not be fully set up yet. Here's how to check and fix:

## Current Status

- ✅ **Pi is online**: 10.123.42.225
- ✅ **SSH is working**: Port 22 is open
- ❌ **Services not running**: Ports 8080, 8008 not accessible
- ❌ **SSH requires key auth**: Password authentication disabled

## Manual Check Steps

### 1. Connect to Pi (you'll need to do this manually)

```bash
# Try connecting with SSH key if you have one
ssh pi@10.123.42.225

# Or if you have physical access, use monitor/keyboard
# The Pi should be auto-logged in as user 'pi'
```

### 2. Check System Status

```bash
# Check if first-boot setup completed
ls -la /boot/firstboot/
cat /boot/firstboot/setup.sh

# Check system uptime
uptime
whoami
hostname
```

### 3. Check Services Status

```bash
# Check if services are installed
systemctl list-units --type=service | grep -E "(airplay|google-cast|remote-control)"

# Check service status
sudo systemctl status airplay.service
sudo systemctl status google-cast.service
sudo systemctl status remote-control.service

# Check if custom GUI is running
ps aux | grep raspberry-pi-gui
```

### 4. Start Services Manually (if needed)

```bash
# Enable and start services
sudo systemctl enable airplay.service
sudo systemctl start airplay.service

sudo systemctl enable google-cast.service
sudo systemctl start google-cast.service

sudo systemctl enable remote-control.service
sudo systemctl start remote-control.service

# Check if they're running
sudo systemctl status airplay.service
sudo systemctl status google-cast.service
sudo systemctl status remote-control.service
```

### 5. Check Custom GUI

```bash
# Check if GUI script exists
ls -la /usr/local/bin/raspberry-pi-gui.py

# Run GUI manually if needed
python3 /usr/local/bin/raspberry-pi-gui.py
```

### 6. Check Network Services

```bash
# Check what ports are listening
sudo netstat -tlnp | grep -E ":(22|8080|8008|5353)"

# Test web dashboard locally
curl http://localhost:8080
```

### 7. Check WiFi Connection

```bash
# Check WiFi status
iwconfig wlan0
ip addr show wlan0

# Check if connected to "connection" network
iwconfig wlan0 | grep "connection"
```

## Troubleshooting

### If Services Won't Start:

```bash
# Check service logs
sudo journalctl -u airplay.service -f
sudo journalctl -u google-cast.service -f
sudo journalctl -u remote-control.service -f

# Check system logs
sudo journalctl -f
```

### If Custom GUI Won't Start:

```bash
# Check if Python packages are installed
pip3 list | grep -E "(flask|psutil)"

# Install missing packages
pip3 install flask flask-cors requests psutil

# Run GUI manually
cd /usr/local/bin
python3 raspberry-pi-gui.py
```

### If WiFi Not Connected:

```bash
# Check WiFi configuration
cat /etc/wpa_supplicant/wpa_supplicant.conf

# Restart WiFi
sudo systemctl restart wpa_supplicant
sudo systemctl restart networking
```

## Expected Results

After everything is working, you should see:

- ✅ Web dashboard at: http://10.123.42.225:8080
- ✅ Google Cast on port 8008
- ✅ AirPlay service running
- ✅ Custom GUI displaying on screen
- ✅ WiFi connected to "connection" network

## Quick Fix Script

If you want to run everything at once:

```bash
# Run this on the Pi
sudo systemctl enable airplay.service google-cast.service remote-control.service
sudo systemctl start airplay.service google-cast.service remote-control.service
sudo systemctl status airplay.service google-cast.service remote-control.service
```

Let me know what you find when you check these!
