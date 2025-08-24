#!/usr/bin/env python3

# Raspberry Pi GUI Dashboard
import tkinter as tk
import socket
import os
import psutil
import threading
import time

class RaspberryPiDashboard:
    def __init__(self, root):
        self.root = root
        self.root.title("Raspberry Pi Dashboard")
        self.root.geometry("800x480")  # Standard Raspberry Pi display resolution
        self.root.attributes('-fullscreen', True)
        
        # Set background color
        self.root.configure(bg="#2c3e50")
        
        # Create main frame
        self.main_frame = tk.Frame(self.root, bg="#2c3e50")
        self.main_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=20)
        
        # Create header
        self.header = tk.Label(self.main_frame, text="Raspberry Pi 3B Dashboard", 
                              font=("Helvetica", 24, "bold"), bg="#2c3e50", fg="white")
        self.header.pack(pady=10)
        
        # Create status frame
        self.status_frame = tk.Frame(self.main_frame, bg="#34495e", bd=2, relief=tk.RAISED)
        self.status_frame.pack(fill=tk.X, pady=10)
        
        # Status labels
        self.hostname_label = tk.Label(self.status_frame, text=f"Hostname: {socket.gethostname()}", 
                                     font=("Helvetica", 12), bg="#34495e", fg="white")
        self.hostname_label.grid(row=0, column=0, sticky="w", padx=10, pady=5)
        
        self.ip_label = tk.Label(self.status_frame, text="IP: Checking...", 
                               font=("Helvetica", 12), bg="#34495e", fg="white")
        self.ip_label.grid(row=0, column=1, sticky="w", padx=10, pady=5)
        
        self.cpu_label = tk.Label(self.status_frame, text="CPU: Checking...", 
                                font=("Helvetica", 12), bg="#34495e", fg="white")
        self.cpu_label.grid(row=1, column=0, sticky="w", padx=10, pady=5)
        
        self.memory_label = tk.Label(self.status_frame, text="Memory: Checking...", 
                                   font=("Helvetica", 12), bg="#34495e", fg="white")
        self.memory_label.grid(row=1, column=1, sticky="w", padx=10, pady=5)
        
        # Create services frame
        self.services_frame = tk.LabelFrame(self.main_frame, text="Services", 
                                          font=("Helvetica", 14, "bold"), bg="#34495e", fg="white")
        self.services_frame.pack(fill=tk.X, pady=10)
        
        # Service status indicators
        self.services = {
            "AirPlay": {"status": "Unknown", "color": "gray"},
            "Google Cast": {"status": "Unknown", "color": "gray"},
            "Miracast": {"status": "Unknown", "color": "gray"},
            "Remote Control": {"status": "Unknown", "color": "gray"},
            "WiFi Tools": {"status": "Unknown", "color": "gray"}
        }
        
        row = 0
        col = 0
        for service, data in self.services.items():
            frame = tk.Frame(self.services_frame, bg="#34495e", padx=10, pady=5)
            frame.grid(row=row, column=col, sticky="w", padx=10, pady=5)
            
            indicator = tk.Canvas(frame, width=15, height=15, bg="#34495e", highlightthickness=0)
            indicator.create_oval(2, 2, 13, 13, fill=data["color"], outline="")
            indicator.pack(side=tk.LEFT, padx=5)
            
            label = tk.Label(frame, text=f"{service}: {data['status']}", 
                           font=("Helvetica", 12), bg="#34495e", fg="white")
            label.pack(side=tk.LEFT)
            
            data["indicator"] = indicator
            data["label"] = label
            
            col += 1
            if col > 2:
                col = 0
                row += 1
        
        # Create log frame
        self.log_frame = tk.LabelFrame(self.main_frame, text="System Log", 
                                     font=("Helvetica", 14, "bold"), bg="#34495e", fg="white")
        self.log_frame.pack(fill=tk.BOTH, expand=True, pady=10)
        
        self.log_text = tk.Text(self.log_frame, height=10, bg="#2c3e50", fg="white", 
                              font=("Courier", 10))
        self.log_text.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Add some initial log entries
        self.add_log("System starting up...")
        self.add_log("Initializing services...")
        
        # Start update thread
        self.update_thread = threading.Thread(target=self.update_data)
        self.update_thread.daemon = True
        self.update_thread.start()
        
        # Add exit button (for development)
        self.exit_button = tk.Button(self.main_frame, text="Exit", command=self.root.destroy, 
                                   bg="#e74c3c", fg="white", font=("Helvetica", 12))
        self.exit_button.pack(pady=10)
    
    def add_log(self, message):
        """Add a message to the log with timestamp"""
        timestamp = time.strftime("%H:%M:%S")
        self.log_text.insert(tk.END, f"[{timestamp}] {message}\n")
        self.log_text.see(tk.END)
    
    def update_service_status(self, service, status):
        """Update the status of a service"""
        if service in self.services:
            if status:
                self.services[service]["status"] = "Running"
                self.services[service]["color"] = "green"
            else:
                self.services[service]["status"] = "Stopped"
                self.services[service]["color"] = "red"
            
            self.services[service]["indicator"].create_oval(2, 2, 13, 13, 
                                                         fill=self.services[service]["color"], 
                                                         outline="")
            self.services[service]["label"].config(
                text=f"{service}: {self.services[service]['status']}")
    
    def get_ip_address(self):
        """Get the IP address of the primary interface"""
        try:
            # This is a simple way to get the IP, might not work in all cases
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except:
            return "Not connected"
    
    def update_data(self):
        """Update system data periodically"""
        while True:
            # Update IP
            ip = self.get_ip_address()
            self.ip_label.config(text=f"IP: {ip}")
            
            # Update CPU
            cpu_percent = psutil.cpu_percent()
            self.cpu_label.config(text=f"CPU: {cpu_percent}%")
            
            # Update memory
            memory = psutil.virtual_memory()
            memory_percent = memory.percent
            self.memory_label.config(text=f"Memory: {memory_percent}%")
            
            # Simulate checking services (in a real app, you would check actual service status)
            for service in self.services:
                # Simulate service status check - in a real app, check actual service status
                status = os.system(f"ps aux | grep -v grep | grep -q '{service.lower().replace(' ', '-')}'") == 0
                self.update_service_status(service, status)
                
                # For demo purposes, let's assume all services are running
                self.update_service_status(service, True)
            
            # Add occasional log messages
            if cpu_percent > 80:
                self.add_log(f"High CPU usage: {cpu_percent}%")
            
            time.sleep(2)  # Update every 2 seconds

if __name__ == "__main__":
    root = tk.Tk()
    app = RaspberryPiDashboard(root)
    root.mainloop()
