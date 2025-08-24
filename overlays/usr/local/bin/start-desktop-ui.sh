#!/bin/bash

# Desktop UI Startup Script for Raspberry Pi 3B
# This creates a TV-like interface showing all features

# Set display environment
export DISPLAY=:0
export XAUTHORITY=/home/pi/.Xauthority

# Wait for X server to be ready
sleep 5

# Kill any existing processes
pkill -f "chromium\|kiosk\|tv-interface" 2>/dev/null

# Create TV-like interface directory
mkdir -p /home/pi/tv-interface

# Create a simple TV interface HTML file
cat > /home/pi/tv-interface/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Raspberry Pi 3B - Smart TV Interface</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Arial', sans-serif;
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            color: white;
            overflow: hidden;
            height: 100vh;
        }

        .tv-container {
            display: flex;
            flex-direction: column;
            height: 100vh;
            padding: 20px;
        }

        .header {
            text-align: center;
            margin-bottom: 30px;
        }

        .header h1 {
            font-size: 3rem;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
        }

        .header p {
            font-size: 1.2rem;
            opacity: 0.9;
        }

        .features-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            flex: 1;
            overflow-y: auto;
        }

        .feature-card {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 15px;
            padding: 25px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s ease;
            border: 2px solid transparent;
            backdrop-filter: blur(10px);
        }

        .feature-card:hover {
            background: rgba(255, 255, 255, 0.2);
            transform: translateY(-5px);
            border-color: #00ff88;
            box-shadow: 0 10px 30px rgba(0, 255, 136, 0.3);
        }

        .feature-card.active {
            background: rgba(0, 255, 136, 0.2);
            border-color: #00ff88;
        }

        .feature-icon {
            font-size: 4rem;
            margin-bottom: 15px;
        }

        .feature-title {
            font-size: 1.5rem;
            margin-bottom: 10px;
            font-weight: bold;
        }

        .feature-description {
            font-size: 1rem;
            opacity: 0.8;
            line-height: 1.4;
        }

        .status-bar {
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            background: rgba(0, 0, 0, 0.8);
            padding: 15px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            backdrop-filter: blur(10px);
        }

        .status-item {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .status-dot {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            background: #00ff88;
        }

        .status-dot.inactive {
            background: #ff4444;
        }

        .network-info {
            position: fixed;
            top: 20px;
            right: 20px;
            background: rgba(0, 0, 0, 0.7);
            padding: 15px;
            border-radius: 10px;
            backdrop-filter: blur(10px);
        }

        .wifi-setup {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(0, 0, 0, 0.95);
            padding: 30px;
            border-radius: 15px;
            backdrop-filter: blur(20px);
            border: 2px solid #00ff88;
            display: none;
            z-index: 1000;
        }

        .wifi-setup.show {
            display: block;
        }

        .wifi-input {
            width: 100%;
            padding: 10px;
            margin: 10px 0;
            border: none;
            border-radius: 5px;
            background: rgba(255, 255, 255, 0.1);
            color: white;
        }

        .wifi-button {
            background: #00ff88;
            color: black;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            margin: 5px;
        }

        .wifi-button:hover {
            background: #00cc6a;
        }

        .close-button {
            position: absolute;
            top: 10px;
            right: 15px;
            background: none;
            border: none;
            color: white;
            font-size: 1.5rem;
            cursor: pointer;
        }

        @media (max-width: 768px) {
            .header h1 {
                font-size: 2rem;
            }
            
            .features-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="tv-container">
        <div class="header">
            <h1>🍓 Raspberry Pi 3B</h1>
            <p>Smart TV & Wireless Display Hub</p>
        </div>

        <div class="features-grid">
            <div class="feature-card" onclick="toggleService('airplay')" id="airplay-card">
                <div class="feature-icon">🎵</div>
                <div class="feature-title">AirPlay Receiver</div>
                <div class="feature-description">Stream from iPhone, iPad, or Mac. Always on and ready to receive.</div>
            </div>

            <div class="feature-card" onclick="toggleService('chromecast')" id="chromecast-card">
                <div class="feature-icon">📱</div>
                <div class="feature-title">Google Cast</div>
                <div class="feature-description">Cast from Android, Chrome, or any Cast-enabled app.</div>
            </div>

            <div class="feature-card" onclick="toggleService('miracast')" id="miracast-card">
                <div class="feature-icon">🔄</div>
                <div class="feature-title">Miracast</div>
                <div class="feature-description">Direct WiFi display from Windows, Android, or other devices.</div>
            </div>

            <div class="feature-card" onclick="openRemoteControl()">
                <div class="feature-icon">🎮</div>
                <div class="feature-title">Remote Control</div>
                <div class="feature-description">Control your Pi from any device via web interface.</div>
            </div>

            <div class="feature-card" onclick="toggleService('wifi_tools')" id="wifi-tools-card">
                <div class="feature-icon">🔒</div>
                <div class="feature-title">WiFi Security Tools</div>
                <div class="feature-description">Background WiFi scanning and security analysis.</div>
            </div>

            <div class="feature-card" onclick="openFileServer()">
                <div class="feature-icon">📁</div>
                <div class="feature-title">File Server</div>
                <div class="feature-description">Access captured data and files from any device.</div>
            </div>

            <div class="feature-card" onclick="showWifiSetup()">
                <div class="feature-icon">📶</div>
                <div class="feature-title">WiFi Setup</div>
                <div class="feature-description">Configure WiFi connection and network settings.</div>
            </div>

            <div class="feature-card" onclick="showSystemInfo()">
                <div class="feature-icon">⚙️</div>
                <div class="feature-title">System Info</div>
                <div class="feature-description">View system status, temperature, and performance.</div>
            </div>
        </div>
    </div>

    <div class="status-bar">
        <div class="status-item">
            <div class="status-dot" id="airplay-status"></div>
            <span>AirPlay</span>
        </div>
        <div class="status-item">
            <div class="status-dot" id="chromecast-status"></div>
            <span>Google Cast</span>
        </div>
        <div class="status-item">
            <div class="status-dot" id="wifi-tools-status"></div>
            <span>WiFi Tools</span>
        </div>
        <div class="status-item">
            <div class="status-dot" id="network-status"></div>
            <span>Network</span>
        </div>
    </div>

    <div class="network-info">
        <div>IP: <span id="ip-address">Checking...</span></div>
        <div>WiFi: <span id="wifi-status">Checking...</span></div>
    </div>

    <div class="wifi-setup" id="wifi-setup">
        <button class="close-button" onclick="hideWifiSetup()">&times;</button>
        <h3>WiFi Configuration</h3>
        <input type="text" class="wifi-input" id="ssid-input" placeholder="WiFi Network Name (SSID)">
        <input type="password" class="wifi-input" id="password-input" placeholder="WiFi Password">
        <button class="wifi-button" onclick="connectWifi()">Connect</button>
        <button class="wifi-button" onclick="scanNetworks()">Scan Networks</button>
        <div id="network-list" style="margin-top: 15px; max-height: 200px; overflow-y: auto;"></div>
    </div>

    <script>
        // Service status tracking
        let services = {
            airplay: false,
            chromecast: false,
            wifi_tools: false,
            network: false
        };

        // Initialize interface
        document.addEventListener('DOMContentLoaded', function() {
            updateStatus();
            setInterval(updateStatus, 5000);
        });

        // Update service status
        function updateStatus() {
            fetch('/api/status')
                .then(response => response.json())
                .then(data => {
                    if (data.services) {
                        services = data.services;
                        updateStatusDisplay();
                    }
                    if (data.network && data.network.ip_addresses) {
                        document.getElementById('ip-address').textContent = data.network.ip_addresses[0] || 'Not Connected';
                    }
                })
                .catch(error => {
                    console.error('Error updating status:', error);
                });
        }

        // Update status display
        function updateStatusDisplay() {
            document.getElementById('airplay-status').className = 
                'status-dot' + (services.airplay ? '' : ' inactive');
            document.getElementById('chromecast-status').className = 
                'status-dot' + (services.chromecast ? '' : ' inactive');
            document.getElementById('wifi-tools-status').className = 
                'status-dot' + (services.wifi_tools ? '' : ' inactive');
            document.getElementById('network-status').className = 
                'status-dot' + (services.network ? '' : ' inactive');

            // Update feature cards
            document.getElementById('airplay-card').className = 
                'feature-card' + (services.airplay ? ' active' : '');
            document.getElementById('chromecast-card').className = 
                'feature-card' + (services.chromecast ? ' active' : '');
            document.getElementById('wifi-tools-card').className = 
                'feature-card' + (services.wifi_tools ? ' active' : '');
        }

        // Toggle service
        function toggleService(serviceName) {
            fetch(`/api/service/${serviceName}/toggle`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    updateStatus();
                } else {
                    alert('Error toggling service: ' + data.error);
                }
            })
            .catch(error => {
                console.error('Error toggling service:', error);
            });
        }

        // Open remote control
        function openRemoteControl() {
            window.open('http://' + window.location.hostname + ':8080', '_blank');
        }

        // Open file server
        function openFileServer() {
            window.open('http://' + window.location.hostname + ':8080/files', '_blank');
        }

        // Show WiFi setup
        function showWifiSetup() {
            document.getElementById('wifi-setup').classList.add('show');
        }

        // Hide WiFi setup
        function hideWifiSetup() {
            document.getElementById('wifi-setup').classList.remove('show');
        }

        // Connect to WiFi
        function connectWifi() {
            const ssid = document.getElementById('ssid-input').value;
            const password = document.getElementById('password-input').value;
            
            if (!ssid || !password) {
                alert('Please enter both SSID and password');
                return;
            }

            fetch('/api/wifi/connect', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ ssid: ssid, password: password })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('WiFi connected successfully!');
                    hideWifiSetup();
                    updateStatus();
                } else {
                    alert('Error connecting to WiFi: ' + data.error);
                }
            })
            .catch(error => {
                console.error('Error connecting to WiFi:', error);
                alert('Error connecting to WiFi');
            });
        }

        // Scan WiFi networks
        function scanNetworks() {
            fetch('/api/network/scan')
                .then(response => response.json())
                .then(data => {
                    if (data.success && data.networks) {
                        displayNetworks(data.networks);
                    } else {
                        alert('Error scanning networks: ' + (data.error || 'Unknown error'));
                    }
                })
                .catch(error => {
                    console.error('Error scanning networks:', error);
                });
        }

        // Display networks
        function displayNetworks(networks) {
            const networkList = document.getElementById('network-list');
            let html = '<h4>Available Networks:</h4>';
            
            networks.forEach(network => {
                const encrypted = network.encrypted ? '🔒' : '🔓';
                html += `<div style="padding: 5px; border-bottom: 1px solid #333;">
                    ${encrypted} ${network.ssid} (Signal: ${network.signal || 'N/A'})
                </div>`;
            });
            
            networkList.innerHTML = html;
        }

        // Show system info
        function showSystemInfo() {
            fetch('/api/status')
                .then(response => response.json())
                .then(data => {
                    if (data.system) {
                        const info = data.system;
                        let message = 'System Information:\n';
                        message += `CPU Temperature: ${info.cpu_temp || 'N/A'}°C\n`;
                        message += `Memory Usage: ${Math.round((info.memory?.used || 0) / (info.memory?.total || 1) * 100)}%\n`;
                        message += `Disk Usage: ${Math.round((info.disk?.used || 0) / (info.disk?.total || 1) * 100)}%`;
                        alert(message);
                    }
                })
                .catch(error => {
                    console.error('Error getting system info:', error);
                });
        }

        // Keyboard shortcuts
        document.addEventListener('keydown', function(e) {
            switch(e.key) {
                case 'Escape':
                    hideWifiSetup();
                    break;
                case 'F11':
                    if (document.fullscreenElement) {
                        document.exitFullscreen();
                    } else {
                        document.documentElement.requestFullscreen();
                    }
                    break;
            }
        });
    </script>
</body>
</html>
EOF

# Start Chromium in kiosk mode to display the TV interface
chromium-browser --kiosk --disable-web-security --user-data-dir=/tmp/chromium-data file:///home/pi/tv-interface/index.html &

# Also start a simple HTTP server for the interface
cd /home/pi/tv-interface
python3 -m http.server 8081 &

# Keep the script running
while true; do
    sleep 10
    # Check if Chromium is still running
    if ! pgrep -f "chromium" > /dev/null; then
        echo "Chromium crashed, restarting..."
        chromium-browser --kiosk --disable-web-security --user-data-dir=/tmp/chromium-data file:///home/pi/tv-interface/index.html &
    fi
done
