#!/bin/bash

# Quick SSH Enable Script
# Run this on your Raspberry Pi to enable SSH and basic services

echo "🔧 Quick SSH and Service Setup"
echo "=============================="

# Enable SSH password authentication
echo "Enabling SSH password authentication..."
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh

echo "✅ SSH password authentication enabled!"

# Install basic packages
echo "Installing basic packages..."
sudo apt update
sudo apt install -y python3-pip python3-tk python3-psutil

# Install Python packages
echo "Installing Python packages..."
pip3 install flask flask-cors requests psutil

# Create simple web server
echo "Creating simple web dashboard..."
sudo mkdir -p /usr/local/bin
sudo tee /usr/local/bin/simple-dashboard.py > /dev/null << 'EOF'
#!/usr/bin/env python3
from flask import Flask, jsonify, render_template_string
import psutil
import subprocess
import socket

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
    </style>
</head>
<body>
    <h1>🍓 Raspberry Pi Dashboard</h1>
    <div class="card">
        <h2>System Status</h2>
        <p>CPU: <span id="cpu">Loading...</span></p>
        <p>Memory: <span id="memory">Loading...</span></p>
        <p>IP: <span id="ip">Loading...</span></p>
    </div>
    <script>
        setInterval(() => {
            fetch('/api/status')
                .then(r => r.json())
                .then(d => {
                    document.getElementById('cpu').textContent = d.cpu + '%';
                    document.getElementById('memory').textContent = d.memory + '%';
                    document.getElementById('ip').textContent = d.ip;
                });
        }, 2000);
    </script>
</body>
</html>
''')

@app.route('/api/status')
def status():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
    except:
        ip = 'Unknown'
    
    return jsonify({
        'cpu': psutil.cpu_percent(),
        'memory': psutil.virtual_memory().percent,
        'ip': ip
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

sudo chmod +x /usr/local/bin/simple-dashboard.py

# Start the web server
echo "Starting web dashboard..."
python3 /usr/local/bin/simple-dashboard.py &
WEB_PID=$!

# Get IP address
IP=$(hostname -I | awk '{print $1}')

echo ""
echo "✅ Setup Complete!"
echo "=================="
echo "SSH: ssh pi@$IP (password: raspberry)"
echo "Web: http://$IP:8080"
echo "Web server PID: $WEB_PID"
echo ""
echo "You can now SSH in and run the full setup!"
