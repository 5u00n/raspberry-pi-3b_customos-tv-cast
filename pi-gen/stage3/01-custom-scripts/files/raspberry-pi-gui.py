#!/usr/bin/env python3
"""
Custom Raspberry Pi Qt GUI Dashboard
Professional interface with PyQt5
"""

import sys
from PyQt5.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QLabel, QFrame, QPushButton, QGridLayout)
from PyQt5.QtCore import Qt, QTimer
from PyQt5.QtGui import QFont, QPalette, QColor
import psutil
import socket
from datetime import datetime

class ServiceWidget(QFrame):
    def __init__(self, name, parent=None):
        super().__init__(parent)
        self.setFrameStyle(QFrame.StyledPanel | QFrame.Raised)
        self.setStyleSheet("""
            QFrame {
                background-color: #34495e;
                border-radius: 10px;
                padding: 10px;
            }
        """)
        
        layout = QHBoxLayout()
        
        # Status indicator
        self.indicator = QLabel("●")
        self.indicator.setStyleSheet("color: #27ae60; font-size: 20px;")
        layout.addWidget(self.indicator)
        
        # Service name
        name_label = QLabel(name)
        name_label.setStyleSheet("color: white; font-size: 14px;")
        layout.addWidget(name_label)
        
        layout.addStretch()
        
        # Status text
        self.status = QLabel("Running")
        self.status.setStyleSheet("color: #27ae60; font-size: 12px;")
        layout.addWidget(self.status)
        
        self.setLayout(layout)

class StatWidget(QFrame):
    def __init__(self, label, value, parent=None):
        super().__init__(parent)
        self.setFrameStyle(QFrame.StyledPanel | QFrame.Raised)
        self.setStyleSheet("""
            QFrame {
                background-color: #34495e;
                border-radius: 10px;
                padding: 15px;
            }
        """)
        
        layout = QVBoxLayout()
        
        # Label
        label_widget = QLabel(label)
        label_widget.setStyleSheet("color: #bdc3c7; font-size: 12px;")
        layout.addWidget(label_widget)
        
        # Value
        self.value_widget = QLabel(value)
        self.value_widget.setStyleSheet("color: white; font-size: 24px; font-weight: bold;")
        layout.addWidget(self.value_widget)
        
        self.setLayout(layout)
    
    def update_value(self, value):
        self.value_widget.setText(value)

class RaspberryPiDashboard(QMainWindow):
    def __init__(self):
        super().__init__()
        self.init_ui()
        
        # Setup update timer
        self.timer = QTimer()
        self.timer.timeout.connect(self.update_stats)
        self.timer.start(2000)  # Update every 2 seconds
    
    def init_ui(self):
        self.setWindowTitle("🍓 Raspberry Pi 3B Custom OS")
        self.setGeometry(0, 0, 1024, 600)
        
        # Set dark theme
        self.setStyleSheet("""
            QMainWindow {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:1,
                    stop:0 #667eea, stop:1 #764ba2);
            }
        """)
        
        # Central widget
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        # Main layout
        main_layout = QVBoxLayout()
        main_layout.setSpacing(20)
        main_layout.setContentsMargins(20, 20, 20, 20)
        
        # Header
        header = self.create_header()
        main_layout.addWidget(header)
        
        # Stats section
        stats_layout = QHBoxLayout()
        stats_layout.setSpacing(15)
        
        self.cpu_stat = StatWidget("CPU Usage", "0%")
        self.memory_stat = StatWidget("Memory", "0%")
        self.disk_stat = StatWidget("Disk", "0%")
        self.temp_stat = StatWidget("Temperature", "0°C")
        
        stats_layout.addWidget(self.cpu_stat)
        stats_layout.addWidget(self.memory_stat)
        stats_layout.addWidget(self.disk_stat)
        stats_layout.addWidget(self.temp_stat)
        
        main_layout.addLayout(stats_layout)
        
        # System info
        info_frame = self.create_info_section()
        main_layout.addWidget(info_frame)
        
        # Services section
        services_frame = self.create_services_section()
        main_layout.addWidget(services_frame)
        
        # Features section
        features_frame = self.create_features_section()
        main_layout.addWidget(features_frame)
        
        # Footer with exit button
        footer = QHBoxLayout()
        footer.addStretch()
        
        exit_btn = QPushButton("Exit (ESC)")
        exit_btn.setStyleSheet("""
            QPushButton {
                background-color: #e74c3c;
                color: white;
                border: none;
                padding: 10px 30px;
                font-size: 14px;
                border-radius: 5px;
            }
            QPushButton:hover {
                background-color: #c0392b;
            }
        """)
        exit_btn.clicked.connect(self.close)
        footer.addWidget(exit_btn)
        
        main_layout.addLayout(footer)
        
        central_widget.setLayout(main_layout)
        
        # Initial update
        self.update_stats()
    
    def create_header(self):
        header = QFrame()
        header.setStyleSheet("""
            QFrame {
                background-color: rgba(52, 73, 94, 0.8);
                border-radius: 15px;
                padding: 20px;
            }
        """)
        
        layout = QVBoxLayout()
        
        title = QLabel("🍓 Raspberry Pi 3B Custom OS Dashboard")
        title.setStyleSheet("color: white; font-size: 28px; font-weight: bold;")
        title.setAlignment(Qt.AlignCenter)
        layout.addWidget(title)
        
        subtitle = QLabel("Live System Monitoring & Control")
        subtitle.setStyleSheet("color: #ecf0f1; font-size: 14px;")
        subtitle.setAlignment(Qt.AlignCenter)
        layout.addWidget(subtitle)
        
        header.setLayout(layout)
        return header
    
    def create_info_section(self):
        frame = QFrame()
        frame.setStyleSheet("""
            QFrame {
                background-color: rgba(52, 73, 94, 0.8);
                border-radius: 10px;
                padding: 15px;
            }
        """)
        
        layout = QGridLayout()
        
        # Hostname
        layout.addWidget(QLabel("Hostname:"), 0, 0)
        self.hostname_label = QLabel(socket.gethostname())
        self.hostname_label.setStyleSheet("color: white; font-weight: bold;")
        layout.addWidget(self.hostname_label, 0, 1)
        
        # IP Address
        layout.addWidget(QLabel("IP Address:"), 0, 2)
        self.ip_label = QLabel(self.get_ip())
        self.ip_label.setStyleSheet("color: white; font-weight: bold;")
        layout.addWidget(self.ip_label, 0, 3)
        
        # Uptime
        layout.addWidget(QLabel("Uptime:"), 1, 0)
        self.uptime_label = QLabel(self.get_uptime())
        self.uptime_label.setStyleSheet("color: white; font-weight: bold;")
        layout.addWidget(self.uptime_label, 1, 1)
        
        # Time
        layout.addWidget(QLabel("Time:"), 1, 2)
        self.time_label = QLabel(datetime.now().strftime("%H:%M:%S"))
        self.time_label.setStyleSheet("color: white; font-weight: bold;")
        layout.addWidget(self.time_label, 1, 3)
        
        for i in range(4):
            label = layout.itemAtPosition(0, i).widget() if i < 2 else layout.itemAtPosition(1, i-2).widget()
            if label and isinstance(label, QLabel) and label.text().endswith(':'):
                label.setStyleSheet("color: #bdc3c7; font-size: 12px;")
        
        frame.setLayout(layout)
        return frame
    
    def create_services_section(self):
        frame = QFrame()
        frame.setStyleSheet("""
            QFrame {
                background-color: rgba(52, 73, 94, 0.8);
                border-radius: 10px;
                padding: 15px;
            }
        """)
        
        layout = QVBoxLayout()
        
        title = QLabel("Services Status")
        title.setStyleSheet("color: white; font-size: 16px; font-weight: bold;")
        layout.addWidget(title)
        
        services_layout = QGridLayout()
        services = [
            "AirPlay Receiver",
            "Google Cast",
            "WiFi Security Tools",
            "Remote Control Server",
            "File Server (Samba)",
            "GUI Dashboard"
        ]
        
        for i, service in enumerate(services):
            row = i // 2
            col = i % 2
            services_layout.addWidget(ServiceWidget(service), row, col)
        
        layout.addLayout(services_layout)
        frame.setLayout(layout)
        return frame
    
    def create_features_section(self):
        frame = QFrame()
        frame.setStyleSheet("""
            QFrame {
                background-color: rgba(52, 73, 94, 0.8);
                border-radius: 10px;
                padding: 15px;
            }
        """)
        
        layout = QVBoxLayout()
        
        title = QLabel("Custom Features")
        title.setStyleSheet("color: white; font-size: 16px; font-weight: bold;")
        layout.addWidget(title)
        
        features = [
            "✅ Auto-login and auto-start on boot",
            "✅ Wireless display (AirPlay & Google Cast)",
            "✅ Web dashboard accessible on port 8080",
            "✅ File sharing via Samba network",
            "✅ WiFi security and monitoring tools",
            "✅ SSH access enabled by default"
        ]
        
        features_layout = QGridLayout()
        for i, feature in enumerate(features):
            row = i // 2
            col = i % 2
            label = QLabel(feature)
            label.setStyleSheet("color: white; font-size: 12px;")
            features_layout.addWidget(label, row, col)
        
        layout.addLayout(features_layout)
        frame.setLayout(layout)
        return frame
    
    def get_ip(self):
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except:
            return "Not connected"
    
    def get_uptime(self):
        try:
            with open('/proc/uptime', 'r') as f:
                uptime_seconds = float(f.readline().split()[0])
                hours = int(uptime_seconds // 3600)
                minutes = int((uptime_seconds % 3600) // 60)
                return f"{hours}h {minutes}m"
        except:
            return "Unknown"
    
    def get_temperature(self):
        try:
            with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
                temp = float(f.read()) / 1000.0
                return f"{temp:.1f}°C"
        except:
            return "N/A"
    
    def update_stats(self):
        try:
            # Update CPU
            cpu = psutil.cpu_percent(interval=0.1)
            self.cpu_stat.update_value(f"{cpu:.1f}%")
            
            # Update Memory
            memory = psutil.virtual_memory().percent
            self.memory_stat.update_value(f"{memory:.1f}%")
            
            # Update Disk
            disk = psutil.disk_usage('/').percent
            self.disk_stat.update_value(f"{disk:.1f}%")
            
            # Update Temperature
            temp = self.get_temperature()
            self.temp_stat.update_value(temp)
            
            # Update time
            self.time_label.setText(datetime.now().strftime("%H:%M:%S"))
            
            # Update uptime
            self.uptime_label.setText(self.get_uptime())
        except Exception as e:
            print(f"Error updating stats: {e}")
    
    def keyPressEvent(self, event):
        if event.key() == Qt.Key_Escape:
            self.close()

def main():
    app = QApplication(sys.argv)
    app.setStyle('Fusion')  # Use Fusion style for better appearance
    
    # Set dark palette
    palette = QPalette()
    palette.setColor(QPalette.Window, QColor(53, 53, 53))
    palette.setColor(QPalette.WindowText, Qt.white)
    palette.setColor(QPalette.Base, QColor(25, 25, 25))
    palette.setColor(QPalette.AlternateBase, QColor(53, 53, 53))
    palette.setColor(QPalette.ToolTipBase, Qt.white)
    palette.setColor(QPalette.ToolTipText, Qt.white)
    palette.setColor(QPalette.Text, Qt.white)
    palette.setColor(QPalette.Button, QColor(53, 53, 53))
    palette.setColor(QPalette.ButtonText, Qt.white)
    palette.setColor(QPalette.BrightText, Qt.red)
    palette.setColor(QPalette.Link, QColor(42, 130, 218))
    palette.setColor(QPalette.Highlight, QColor(42, 130, 218))
    palette.setColor(QPalette.HighlightedText, Qt.black)
    app.setPalette(palette)
    
    window = RaspberryPiDashboard()
    window.showFullScreen()
    
    sys.exit(app.exec_())

if __name__ == '__main__':
    main()
