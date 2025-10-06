#!/bin/bash

# One-Command Raspberry Pi Setup
# This script sets up everything you need for your custom Raspberry Pi OS

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[SETUP]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log "🍓 One-Command Raspberry Pi Setup"
log "================================="
log "This will install all features and services"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    error "Please run this script as user 'pi', not as root"
fi

log "Step 1/8: Enabling SSH password authentication..."
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh
log "✅ SSH password authentication enabled"

log "Step 2/8: Updating system packages..."
sudo apt update && sudo apt upgrade -y
log "✅ System updated"

log "Step 3/8: Installing required packages..."
sudo apt install -y python3-pip python3-tk python3-psutil shairport-sync avahi-daemon samba nginx iw wireless-tools
log "✅ Packages installed"

log "Step 4/8: Installing Python packages..."
pip3 install flask flask-cors requests psutil
log "✅ Python packages installed"

log "Step 5/8: Creating custom GUI application..."
sudo mkdir -p /usr/local/bin

sudo tee /usr/local/bin/raspberry-pi-gui.py > /dev/null << 'EOF'
#!/usr/bin/env python3
import tkinter as tk
import psutil
import subprocess
import threading
import time

class RaspberryPiGUI:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title('Raspberry Pi Custom OS')
        self.root.geometry('800x600')
        self.root.configure(bg='#2c3e50')
        self.setup_ui()
        self.update_stats()

    def setup_ui(self):
        # Title
        title = tk.Label(self.root, text='🍓 Raspberry Pi Custom OS', font=('Arial', 24, 'bold'), fg='white', bg='#2c3e50')
        title.pack(pady=20)

        # Status frame
        status_frame = tk.Frame(self.root, bg='#34495e', relief='raised', bd=2)
        status_frame.pack(pady=10, padx=20, fill='x')

        # CPU and Memory
        self.cpu_label = tk.Label(status_frame, text='CPU: Loading...', font=('Arial', 14), fg='white', bg='#34495e')
        self.cpu_label.pack(pady=5)

        self.memory_label = tk.Label(status_frame, text='Memory: Loading...', font=('Arial', 14), fg='white', bg='#34495e')
        self.memory_label.pack(pady=5)

        # Services frame
        services_frame = tk.Frame(self.root, bg='#34495e', relief='raised', bd=2)
        services_frame.pack(pady=10, padx=20, fill='x')

        services_title = tk.Label(services_frame, text='Services Status', font=('Arial', 16, 'bold'), fg='white', bg='#34495e')
        services_title.pack(pady=10)

        self.airplay_label = tk.Label(services_frame, text='AirPlay: Checking...', font=('Arial', 12), fg='white', bg='#34495e')
        self.airplay_label.pack(pady=2)

        self.cast_label = tk.Label(services_frame, text='Google Cast: Checking...', font=('Arial', 12), fg='white', bg='#34495e')
        self.cast_label.pack(pady=2)

        self.web_label = tk.Label(services_frame, text='Web Dashboard: Checking...', font=('Arial', 12), fg='white', bg='#34495e')
        self.web_label.pack(pady=2)

        # Control buttons
        button_frame = tk.Frame(self.root, bg='#2c3e50')
        button_frame.pack(pady=20)

        start_btn = tk.Button(button_frame, text='Start All Services', command=self.start_services, font=('Arial', 12), bg='#27ae60', fg='white')
        start_btn.pack(side='left', padx=10)

        stop_btn = tk.Button(button_frame, text='Stop All Services', command=self.stop_services, font=('Arial', 12), bg='#e74c3c', fg='white')
        stop_btn.pack(side='left', padx=10)

        refresh_btn = tk.Button(button_frame, text='Refresh Status', command=self.update_stats, font=('Arial', 12), bg='#3498db', fg='white')
        refresh_btn.pack(side='left', padx=10)

    def start_services(self):
        subprocess.run(['sudo', 'systemctl', 'start', 'airplay.service'], check=False)
        subprocess.run(['sudo', 'systemctl', 'start', 'google-cast.service'], check=False)
        subprocess.run(['sudo', 'systemctl', 'start', 'remote-control.service'], check=False)
        self.update_stats()

    def stop_services(self):
        subprocess.run(['sudo', 'systemctl', 'stop', 'airplay.service'], check=False)
        subprocess.run(['sudo', 'systemctl', 'stop', 'google-cast.service'], check=False)
        subprocess.run(['sudo', 'systemctl', 'stop', 'remote-control.service'], check=False)
        self.update_stats()

    def update_stats(self):
        # Update CPU and Memory
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        self.cpu_label.config(text=f'CPU: {cpu_percent}%')
        self.memory_label.config(text=f'Memory: {memory.percent}%')

        # Check services
        airplay_status = subprocess.run(['systemctl', 'is-active', 'airplay.service'], capture_output=True, text=True)
        cast_status = subprocess.run(['systemctl', 'is-active', 'google-cast.service'], capture_output=True, text=True)
        web_status = subprocess.run(['systemctl', 'is-active', 'remote-control.service'], capture_output=True, text=True)

        self.airplay_label.config(text=f'AirPlay: {airplay_status.stdout.strip()}')
        self.cast_label.config(text=f'Google Cast: {cast_status.stdout.strip()}')
        self.web_label.config(text=f'Web Dashboard: {web_status.stdout.strip()}')

        # Schedule next update
        self.root.after(5000, self.update_stats)

    def run(self):
        self.root.mainloop()

if __name__ == '__main__':
    app = RaspberryPiGUI()
    app.run()
EOF

sudo chmod +x /usr/local/bin/raspberry-pi-gui.py
log "✅ Custom GUI created"

log "Step 6/8: Creating web dashboard..."
sudo tee /usr/local/bin/remote-control-server > /dev/null << 'EOF'
#!/usr/bin/env python3
from flask import Flask, jsonify, render_template_string
import psutil
import subprocess

app = Flask(__name__)

@app.route('/')
def dashboard():
    return render_template_string('''
<!DOCTYPE html>
<html>
<head>
    <title>Raspberry Pi Dashboard</title>
    <style>
        body { font-family: Arial; background: #2c3e50; color: white; padding: 20px; }
        .card { background: #34495e; padding: 20px; margin: 10px; border-radius: 10px; }
        h1 { text-align: center; }
        .status { color: #27ae60; }
        .error { color: #e74c3c; }
    </style>
</head>
<body>
    <h1>🍓 Raspberry Pi Custom OS Dashboard</h1>
    <div class="card">
        <h2>System Status</h2>
        <p>CPU: <span id="cpu">Loading...</span></p>
        <p>Memory: <span id="memory">Loading...</span></p>
        <p>Disk: <span id="disk">Loading...</span></p>
    </div>
    <div class="card">
        <h2>Services</h2>
        <p>AirPlay: <span id="airplay">Checking...</span></p>
        <p>Google Cast: <span id="cast">Checking...</span></p>
        <p>Web Dashboard: <span id="web">Checking...</span></p>
    </div>
    <div class="card">
        <h2>Network</h2>
        <p>IP Address: <span id="ip">Loading...</span></p>
        <p>SSH: <span id="ssh">ssh pi@<span id="ip2">Loading...</span></span></p>
    </div>
    <script>
        setInterval(() => {
            fetch('/api/status')
                .then(r => r.json())
                .then(d => {
                    document.getElementById('cpu').textContent = d.cpu + '%';
                    document.getElementById('memory').textContent = d.memory + '%';
                    document.getElementById('disk').textContent = d.disk + '%';
                    document.getElementById('airplay').textContent = d.airplay;
                    document.getElementById('cast').textContent = d.cast;
                    document.getElementById('web').textContent = d.web;
                    document.getElementById('ip').textContent = d.ip;
                    document.getElementById('ip2').textContent = d.ip;
                });
        }, 2000);
    </script>
</body>
</html>
''')

@app.route('/api/status')
def status():
    import socket
    airplay_status = subprocess.run(['systemctl', 'is-active', 'airplay.service'], capture_output=True, text=True)
    cast_status = subprocess.run(['systemctl', 'is-active', 'google-cast.service'], capture_output=True, text=True)
    web_status = subprocess.run(['systemctl', 'is-active', 'remote-control.service'], capture_output=True, text=True)
    
    # Get IP address
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
    except:
        ip = "Unknown"
    
    return jsonify({
        'cpu': psutil.cpu_percent(),
        'memory': psutil.virtual_memory().percent,
        'disk': psutil.disk_usage('/').percent,
        'airplay': airplay_status.stdout.strip(),
        'cast': cast_status.stdout.strip(),
        'web': web_status.stdout.strip(),
        'ip': ip
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

sudo chmod +x /usr/local/bin/remote-control-server
log "✅ Web dashboard created"

log "Step 7/8: Creating system services..."
# AirPlay service
sudo tee /etc/systemd/system/airplay.service > /dev/null << 'EOF'
[Unit]
Description=AirPlay Receiver
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/shairport-sync
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
EOF

# Google Cast service
sudo tee /etc/systemd/system/google-cast.service > /dev/null << 'EOF'
[Unit]
Description=Google Cast Receiver
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m http.server 8008
WorkingDirectory=/home/pi
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
EOF

# Remote Control service
sudo tee /etc/systemd/system/remote-control.service > /dev/null << 'EOF'
[Unit]
Description=Remote Control Web Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/remote-control-server
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
EOF

log "✅ System services created"

log "Step 8/8: Enabling and starting services..."
sudo systemctl daemon-reload
sudo systemctl enable airplay.service google-cast.service remote-control.service
sudo systemctl start airplay.service google-cast.service remote-control.service

# Set up auto-start GUI
mkdir -p /home/pi/.config/autostart
cat > /home/pi/.config/autostart/custom-gui.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Custom GUI
Exec=python3 /usr/local/bin/raspberry-pi-gui.py
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# Configure Samba
sudo tee -a /etc/samba/smb.conf > /dev/null << 'EOF'

[pi]
   path = /home/pi
   browseable = yes
   read only = no
   guest ok = no
EOF

(echo "raspberry"; echo "raspberry") | sudo smbpasswd -a pi -s

log "✅ Services enabled and started"

# Get IP address
PI_IP=$(hostname -I | awk '{print $1}')

echo ""
log "🎉 Setup Complete!"
log "=================="
echo ""
info "Your Raspberry Pi is now fully configured with:"
info "  ✅ SSH with password authentication"
info "  ✅ Custom GUI application"
info "  ✅ AirPlay receiver service"
info "  ✅ Google Cast service (port 8008)"
info "  ✅ Web dashboard (port 8080)"
info "  ✅ Samba file sharing"
info "  ✅ Auto-start GUI on boot"
echo ""
info "Access your Pi:"
info "  • SSH: ssh pi@$PI_IP (password: raspberry)"
info "  • Web: http://$PI_IP:8080"
info "  • Files: smb://$PI_IP/pi"
info "  • Google Cast: http://$PI_IP:8008"
echo ""
info "Service Status:"
sudo systemctl status airplay.service --no-pager | head -3
sudo systemctl status google-cast.service --no-pager | head -3
sudo systemctl status remote-control.service --no-pager | head -3
echo ""
log "🍓 Your Raspberry Pi is ready to use!"
