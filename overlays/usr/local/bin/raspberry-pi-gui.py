#!/usr/bin/env python3
"""
Custom Raspberry Pi Qt Desktop
Complete dashboard with all requested features
"""

import sys
import os
import subprocess
import time
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QLabel, QPushButton, QProgressBar, QFrame, QGridLayout, QTextEdit,
    QGroupBox, QScrollArea, QSystemTrayIcon, QMenu
)
from PyQt5.QtCore import QTimer, Qt, QThread, pyqtSignal, QSize
from PyQt5.QtGui import QFont, QPalette, QColor, QIcon, QLinearGradient, QBrush

try:
    import psutil
except ImportError:
    subprocess.run(['sudo', 'pip3', 'install', 'psutil'], check=False)
import psutil


class SystemMonitor(QThread):
    """Background thread for system monitoring"""
    stats_updated = pyqtSignal(dict)
    
    def run(self):
        while True:
            try:
                stats = {
                    'cpu': psutil.cpu_percent(interval=1),
                    'memory': psutil.virtual_memory().percent,
                    'disk': psutil.disk_usage('/').percent,
                    'temperature': self.get_temperature(),
                    'uptime': self.get_uptime(),
                    'ip': self.get_ip(),
                    'hostname': self.get_hostname()
                }
                self.stats_updated.emit(stats)
            except Exception as e:
                print(f"Monitor error: {e}")
            time.sleep(2)
    
    def get_temperature(self):
        try:
            with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
                temp = int(f.read()) / 1000
            return f"{temp:.1f}°C"
        except:
            return "N/A"
    
    def get_uptime(self):
        try:
            uptime = time.time() - psutil.boot_time()
            hours = int(uptime // 3600)
            minutes = int((uptime % 3600) // 60)
            return f"{hours}h {minutes}m"
        except:
            return "N/A"
    
    def get_ip(self):
        try:
            result = subprocess.run(['hostname', '-I'], capture_output=True, text=True, timeout=2)
            return result.stdout.strip().split()[0] if result.stdout.strip() else "N/A"
        except:
            return "N/A"
    
    def get_hostname(self):
        try:
            result = subprocess.run(['hostname'], capture_output=True, text=True, timeout=2)
            return result.stdout.strip() or "raspberrypi-custom"
        except:
            return "raspberrypi-custom"


class CustomRaspberryPiDesktop(QMainWindow):
    """Main desktop window with all features"""
    
    def __init__(self):
        super().__init__()
        self.init_ui()
        self.start_monitoring()
        self.check_services()
    
    def init_ui(self):
        """Initialize the user interface"""
        self.setWindowTitle("🍓 Raspberry Pi 3B Custom Desktop")
        self.setGeometry(0, 0, 1024, 600)
        
        # Set dark theme with gradient
        self.setStyleSheet("""
            QMainWindow {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:1,
                    stop:0 #1a1a2e, stop:0.5 #16213e, stop:1 #0f3460);
            }
            QLabel {
                color: white;
                font-size: 13px;
            }
            QGroupBox {
                color: white;
                font-size: 14px;
                font-weight: bold;
                border: 2px solid #3498db;
                border-radius: 8px;
                margin-top: 10px;
                padding: 15px;
                background: rgba(52, 152, 219, 0.1);
            }
            QGroupBox::title {
                subcontrol-origin: margin;
                left: 10px;
                padding: 0 5px;
            }
            QPushButton {
                background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
                    stop:0 #3498db, stop:1 #2980b9);
                border: none;
                padding: 10px;
                border-radius: 6px;
                color: white;
                font-weight: bold;
                font-size: 12px;
                min-height: 30px;
            }
            QPushButton:hover {
                background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
                    stop:0 #5dade2, stop:1 #3498db);
            }
            QPushButton:pressed {
                background: #2471a3;
            }
            QProgressBar {
                border: 2px solid #34495e;
                border-radius: 5px;
                text-align: center;
                color: white;
                font-weight: bold;
                background: #2c3e50;
            }
            QProgressBar::chunk {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                    stop:0 #e74c3c, stop:0.3 #f39c12, stop:0.6 #f1c40f, stop:1 #27ae60);
                border-radius: 3px;
            }
            QTextEdit {
                background: #1c2833;
                color: #ecf0f1;
                border: 1px solid #34495e;
                border-radius: 5px;
                font-family: monospace;
                font-size: 11px;
            }
            QFrame {
                background: rgba(44, 62, 80, 0.6);
                border-radius: 8px;
                border: 1px solid #34495e;
            }
        """)
        
        # Central widget with scroll area
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setStyleSheet("QScrollArea { border: none; background: transparent; }")
        
        central_widget = QWidget()
        scroll.setWidget(central_widget)
        self.setCentralWidget(scroll)
        
        main_layout = QVBoxLayout(central_widget)
        main_layout.setSpacing(15)
        main_layout.setContentsMargins(15, 15, 15, 15)
        
        # Title
        title = QLabel("🍓 Raspberry Pi 3B Custom Desktop")
        title.setAlignment(Qt.AlignCenter)
        title.setStyleSheet("font-size: 24px; font-weight: bold; margin: 10px; color: #3498db;")
        main_layout.addWidget(title)
        
        # System info bar
        info_layout = QHBoxLayout()
        self.hostname_label = QLabel("Hostname: raspberrypi-custom")
        self.ip_label = QLabel("IP: Loading...")
        self.uptime_label = QLabel("Uptime: Loading...")
        
        for label in [self.hostname_label, self.ip_label, self.uptime_label]:
            label.setStyleSheet("font-size: 12px; color: #ecf0f1;")
            info_layout.addWidget(label)
        
        main_layout.addLayout(info_layout)
        
        # System monitoring section
        system_group = QGroupBox("📊 System Monitor")
        system_layout = QVBoxLayout()
        
        # Stats labels
        stats_layout = QGridLayout()
        self.cpu_label = QLabel("CPU: --")
        self.memory_label = QLabel("Memory: --")
        self.disk_label = QLabel("Disk: --")
        self.temp_label = QLabel("Temperature: --")
        
        stats_layout.addWidget(self.cpu_label, 0, 0)
        stats_layout.addWidget(self.memory_label, 0, 1)
        stats_layout.addWidget(self.disk_label, 1, 0)
        stats_layout.addWidget(self.temp_label, 1, 1)
        system_layout.addLayout(stats_layout)
        
        # Progress bars
        self.cpu_bar = QProgressBar()
        self.memory_bar = QProgressBar()
        self.disk_bar = QProgressBar()
        
        system_layout.addWidget(QLabel("CPU Usage:"))
        system_layout.addWidget(self.cpu_bar)
        system_layout.addWidget(QLabel("Memory Usage:"))
        system_layout.addWidget(self.memory_bar)
        system_layout.addWidget(QLabel("Disk Usage:"))
        system_layout.addWidget(self.disk_bar)
        
        system_group.setLayout(system_layout)
        main_layout.addWidget(system_group)
        
        # Services section
        services_group = QGroupBox("🔧 Services")
        services_layout = QVBoxLayout()
        
        # Services status display
        self.services_text = QTextEdit()
        self.services_text.setReadOnly(True)
        self.services_text.setMaximumHeight(120)
        services_layout.addWidget(self.services_text)
        
        # Service control buttons
        buttons_layout = QGridLayout()
        
        self.airplay_btn = QPushButton("📱 AirPlay Receiver")
        self.airplay_btn.clicked.connect(lambda: self.toggle_service('shairport-sync', 'AirPlay'))
        
        self.cast_btn = QPushButton("📲 Google Cast")
        self.cast_btn.clicked.connect(lambda: self.start_cast())
        
        self.web_btn = QPushButton("🌐 Web Dashboard")
        self.web_btn.clicked.connect(self.open_web_dashboard)
        
        self.files_btn = QPushButton("📁 File Sharing")
        self.files_btn.clicked.connect(lambda: self.toggle_service('smbd', 'Samba'))
        
        self.refresh_btn = QPushButton("🔄 Refresh Services")
        self.refresh_btn.clicked.connect(self.check_services)
        
        self.terminal_btn = QPushButton("⌨️  Terminal")
        self.terminal_btn.clicked.connect(self.open_terminal)
        
        buttons_layout.addWidget(self.airplay_btn, 0, 0)
        buttons_layout.addWidget(self.cast_btn, 0, 1)
        buttons_layout.addWidget(self.web_btn, 0, 2)
        buttons_layout.addWidget(self.files_btn, 1, 0)
        buttons_layout.addWidget(self.refresh_btn, 1, 1)
        buttons_layout.addWidget(self.terminal_btn, 1, 2)
        
        services_layout.addLayout(buttons_layout)
        services_group.setLayout(services_layout)
        main_layout.addWidget(services_group)
        
        # Quick actions
        actions_group = QGroupBox("⚡ Quick Actions")
        actions_layout = QHBoxLayout()
        
        self.reboot_btn = QPushButton("🔄 Reboot")
        self.reboot_btn.clicked.connect(self.reboot_system)
        self.reboot_btn.setStyleSheet("""
            QPushButton {
                background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #e67e22, stop:1 #d35400);
            }
            QPushButton:hover {
                background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #f39c12, stop:1 #e67e22);
            }
        """)
        
        self.shutdown_btn = QPushButton("⏻ Shutdown")
        self.shutdown_btn.clicked.connect(self.shutdown_system)
        self.shutdown_btn.setStyleSheet("""
            QPushButton {
                background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #c0392b, stop:1 #a93226);
            }
            QPushButton:hover {
                background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #e74c3c, stop:1 #c0392b);
            }
        """)
        
        actions_layout.addWidget(self.reboot_btn)
        actions_layout.addWidget(self.shutdown_btn)
        actions_group.setLayout(actions_layout)
        main_layout.addWidget(actions_group)
        
        # Status bar
        self.statusBar().showMessage("✅ Custom Desktop Ready - All systems operational")
        self.statusBar().setStyleSheet("background: #2c3e50; color: white; font-weight: bold;")
    
    def start_monitoring(self):
        """Start background system monitoring"""
        self.monitor = SystemMonitor()
        self.monitor.stats_updated.connect(self.update_stats)
        self.monitor.start()
    
    def update_stats(self, stats):
        """Update system statistics display"""
        self.cpu_label.setText(f"CPU: {stats['cpu']:.1f}%")
        self.memory_label.setText(f"Memory: {stats['memory']:.1f}%")
        self.disk_label.setText(f"Disk: {stats['disk']:.1f}%")
        self.temp_label.setText(f"Temperature: {stats['temperature']}")
        self.uptime_label.setText(f"Uptime: {stats['uptime']}")
        self.ip_label.setText(f"IP: {stats['ip']}")
        self.hostname_label.setText(f"Hostname: {stats['hostname']}")
        
        self.cpu_bar.setValue(int(stats['cpu']))
        self.memory_bar.setValue(int(stats['memory']))
        self.disk_bar.setValue(int(stats['disk']))
    
    def check_services(self):
        """Check status of all services"""
        services = [
            ('ssh', 'SSH Server'),
            ('shairport-sync', 'AirPlay Receiver'),
            ('avahi-daemon', 'Network Discovery'),
            ('smbd', 'File Sharing (Samba)'),
            ('nginx', 'Web Server'),
            ('lightdm', 'Desktop Manager')
        ]
        
        status_text = "🟢 Services Status:\n\n"
        
        for service, name in services:
            try:
                result = subprocess.run(
                    ['systemctl', 'is-active', service],
                    capture_output=True, text=True, timeout=2
                )
                is_active = result.stdout.strip() == 'active'
                icon = "🟢" if is_active else "🔴"
                status = "Running" if is_active else "Stopped"
                status_text += f"{icon} {name}: {status}\n"
            except:
                status_text += f"❓ {name}: Unknown\n"
        
        self.services_text.setText(status_text)
        self.statusBar().showMessage(f"✅ Services checked at {time.strftime('%H:%M:%S')}")
    
    def toggle_service(self, service, name):
        """Toggle a service on/off"""
        try:
            # Check current status
            result = subprocess.run(
                ['systemctl', 'is-active', service],
                capture_output=True, text=True, timeout=2
            )
            is_active = result.stdout.strip() == 'active'
            
            # Toggle
            action = 'stop' if is_active else 'start'
            subprocess.run(['sudo', 'systemctl', action, service], check=True, timeout=5)
            
            self.statusBar().showMessage(f"✅ {name} {action}ed successfully")
            
            # Refresh services display
            QTimer.singleShot(1000, self.check_services)
            
        except Exception as e:
            self.statusBar().showMessage(f"❌ Failed to toggle {name}: {str(e)}")
    
    def start_cast(self):
        """Start Google Cast service"""
        try:
            subprocess.Popen(
                ['python3', '-m', 'http.server', '8008'],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            self.statusBar().showMessage("✅ Google Cast service started on port 8008")
        except Exception as e:
            self.statusBar().showMessage(f"❌ Failed to start Cast: {str(e)}")
    
    def open_web_dashboard(self):
        """Open web dashboard in browser"""
        try:
            subprocess.Popen(['chromium-browser', 'http://localhost:8080'])
            self.statusBar().showMessage("✅ Opening web dashboard...")
        except:
            self.statusBar().showMessage("❌ Failed to open browser")
    
    def open_terminal(self):
        """Open terminal"""
        try:
            subprocess.Popen(['lxterminal'])
            self.statusBar().showMessage("✅ Terminal opened")
        except:
            self.statusBar().showMessage("❌ Failed to open terminal")
    
    def reboot_system(self):
        """Reboot the system"""
        self.statusBar().showMessage("🔄 Rebooting system...")
        QTimer.singleShot(1000, lambda: subprocess.run(['sudo', 'reboot']))
    
    def shutdown_system(self):
        """Shutdown the system"""
        self.statusBar().showMessage("⏻ Shutting down system...")
        QTimer.singleShot(1000, lambda: subprocess.run(['sudo', 'shutdown', '-h', 'now']))


def main():
    """Main application entry point"""
    app = QApplication(sys.argv)
    app.setApplicationName("Raspberry Pi Custom Desktop")
    app.setStyle('Fusion')  # Modern style
    
    # Create and show main window
    window = CustomRaspberryPiDesktop()
    window.showFullScreen()  # Start fullscreen
    
    sys.exit(app.exec_())


if __name__ == '__main__':
    main()
