#!/usr/bin/env python3
"""
Raspberry Pi Custom OS - GTK3 GUI Dashboard
A lightweight, native GUI dashboard for monitoring Raspberry Pi system stats
"""

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib, Gdk
import psutil
import subprocess
import os

class RaspberryPiGUI(Gtk.Window):
    def __init__(self):
        super().__init__(title="Raspberry Pi Custom OS")
        self.set_default_size(800, 600)
        self.set_border_width(20)
        
        # Make fullscreen
        self.fullscreen()
        
        # Set up the main layout
        main_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        main_vbox.set_halign(Gtk.Align.CENTER)
        main_vbox.set_valign(Gtk.Align.CENTER)
        self.add(main_vbox)
        
        # Title
        title = Gtk.Label()
        title.set_markup('<span size="30000" weight="bold" foreground="#e94560">🍓 Raspberry Pi Custom OS</span>')
        main_vbox.pack_start(title, False, False, 10)
        
        # System Status Card
        stats_frame = self.create_stats_frame()
        main_vbox.pack_start(stats_frame, False, False, 10)
        
        # Connection Info Card
        info_frame = self.create_info_frame()
        main_vbox.pack_start(info_frame, False, False, 10)
        
        # Control Buttons
        button_box = self.create_buttons()
        main_vbox.pack_start(button_box, False, False, 10)
        
        # Status bar at bottom
        self.status_label = Gtk.Label()
        self.status_label.set_markup('<span size="small" foreground="#888888">Ready</span>')
        main_vbox.pack_end(self.status_label, False, False, 5)
        
        # Apply custom styling
        self.apply_css()
        
        # Update stats every 2 seconds
        GLib.timeout_add_seconds(2, self.update_stats)
        self.update_stats()
    
    def create_stats_frame(self):
        """Create the system statistics frame"""
        frame = Gtk.Frame(label="System Status")
        frame.set_label_align(0.5, 0.5)
        
        grid = Gtk.Grid()
        grid.set_row_spacing(15)
        grid.set_column_spacing(20)
        grid.set_border_width(20)
        grid.set_halign(Gtk.Align.CENTER)
        
        # CPU
        cpu_icon = Gtk.Label()
        cpu_icon.set_markup('<span size="large">💻</span>')
        grid.attach(cpu_icon, 0, 0, 1, 1)
        
        self.cpu_label = Gtk.Label()
        self.cpu_label.set_markup('<span size="large">CPU: Loading...</span>')
        self.cpu_label.set_width_chars(20)
        grid.attach(self.cpu_label, 1, 0, 1, 1)
        
        # Memory
        mem_icon = Gtk.Label()
        mem_icon.set_markup('<span size="large">🧠</span>')
        grid.attach(mem_icon, 0, 1, 1, 1)
        
        self.mem_label = Gtk.Label()
        self.mem_label.set_markup('<span size="large">Memory: Loading...</span>')
        self.mem_label.set_width_chars(20)
        grid.attach(self.mem_label, 1, 1, 1, 1)
        
        # Disk
        disk_icon = Gtk.Label()
        disk_icon.set_markup('<span size="large">💾</span>')
        grid.attach(disk_icon, 2, 0, 1, 1)
        
        self.disk_label = Gtk.Label()
        self.disk_label.set_markup('<span size="large">Disk: Loading...</span>')
        self.disk_label.set_width_chars(20)
        grid.attach(self.disk_label, 3, 0, 1, 1)
        
        # Temperature
        temp_icon = Gtk.Label()
        temp_icon.set_markup('<span size="large">🌡️</span>')
        grid.attach(temp_icon, 2, 1, 1, 1)
        
        self.temp_label = Gtk.Label()
        self.temp_label.set_markup('<span size="large">Temp: Loading...</span>')
        self.temp_label.set_width_chars(20)
        grid.attach(self.temp_label, 3, 1, 1, 1)
        
        frame.add(grid)
        return frame
    
    def create_info_frame(self):
        """Create the connection information frame"""
        frame = Gtk.Frame(label="Connection Info")
        frame.set_label_align(0.5, 0.5)
        
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        vbox.set_border_width(20)
        
        # SSH
        ssh_label = Gtk.Label()
        ssh_label.set_markup('<span size="medium">🔐 SSH: <b>pi@raspberrypi-custom</b></span>')
        vbox.pack_start(ssh_label, False, False, 5)
        
        # Password
        pass_label = Gtk.Label()
        pass_label.set_markup('<span size="medium">🔑 Password: <b>raspberry</b></span>')
        vbox.pack_start(pass_label, False, False, 5)
        
        # Web Dashboard
        web_label = Gtk.Label()
        web_label.set_markup('<span size="medium">🌐 Web: <b>http://raspberrypi-custom:8080</b></span>')
        vbox.pack_start(web_label, False, False, 5)
        
        # IP Address
        self.ip_label = Gtk.Label()
        self.ip_label.set_markup('<span size="medium">📡 IP: <b>Loading...</b></span>')
        vbox.pack_start(self.ip_label, False, False, 5)
        
        frame.add(vbox)
        return frame
    
    def create_buttons(self):
        """Create control buttons"""
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        button_box.set_halign(Gtk.Align.CENTER)
        
        # Refresh button
        refresh_btn = Gtk.Button(label="🔄 Refresh")
        refresh_btn.connect("clicked", self.on_refresh_clicked)
        button_box.pack_start(refresh_btn, False, False, 0)
        
        # Terminal button
        terminal_btn = Gtk.Button(label="💻 Terminal")
        terminal_btn.connect("clicked", self.on_terminal_clicked)
        button_box.pack_start(terminal_btn, False, False, 0)
        
        # Browser button
        browser_btn = Gtk.Button(label="🌐 Web Dashboard")
        browser_btn.connect("clicked", self.on_browser_clicked)
        button_box.pack_start(browser_btn, False, False, 0)
        
        # Exit fullscreen button
        exit_fs_btn = Gtk.Button(label="🪟 Exit Fullscreen")
        exit_fs_btn.connect("clicked", self.on_exit_fullscreen_clicked)
        button_box.pack_start(exit_fs_btn, False, False, 0)
        
        return button_box
    
    def apply_css(self):
        """Apply custom CSS styling"""
        css = b"""
        window {
            background: #1a1a2e;
        }
        frame {
            background: #16213e;
            border: 2px solid #0f3460;
            border-radius: 12px;
            padding: 10px;
        }
        frame > label {
            color: #e94560;
            font-weight: bold;
        }
        label {
            color: #ffffff;
        }
        button {
            background: #0f3460;
            color: #ffffff;
            border: 1px solid #e94560;
            border-radius: 8px;
            padding: 10px 20px;
            font-weight: bold;
        }
        button:hover {
            background: #e94560;
            color: #ffffff;
        }
        """
        
        css_provider = Gtk.CssProvider()
        css_provider.load_from_data(css)
        screen = Gdk.Screen.get_default()
        style_context = Gtk.StyleContext()
        style_context.add_provider_for_screen(
            screen, 
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )
    
    def update_stats(self):
        """Update system statistics"""
        try:
            # CPU usage
            cpu = psutil.cpu_percent(interval=0.1)
            cpu_color = self.get_color_for_percentage(cpu)
            self.cpu_label.set_markup(
                f'<span size="large">CPU: <span foreground="{cpu_color}">{cpu:.1f}%</span></span>'
            )
            
            # Memory usage
            mem = psutil.virtual_memory().percent
            mem_color = self.get_color_for_percentage(mem)
            self.mem_label.set_markup(
                f'<span size="large">Memory: <span foreground="{mem_color}">{mem:.1f}%</span></span>'
            )
            
            # Disk usage
            disk = psutil.disk_usage('/').percent
            disk_color = self.get_color_for_percentage(disk)
            self.disk_label.set_markup(
                f'<span size="large">Disk: <span foreground="{disk_color}">{disk:.1f}%</span></span>'
            )
            
            # CPU Temperature
            temp = self.get_cpu_temp()
            temp_color = self.get_color_for_temp(temp)
            self.temp_label.set_markup(
                f'<span size="large">Temp: <span foreground="{temp_color}">{temp:.1f}°C</span></span>'
            )
            
            # IP Address
            ip = self.get_ip_address()
            self.ip_label.set_markup(f'<span size="medium">📡 IP: <b>{ip}</b></span>')
            
            # Update status
            self.status_label.set_markup(
                f'<span size="small" foreground="#888888">Last updated: {self.get_time()}</span>'
            )
            
        except Exception as e:
            print(f"Error updating stats: {e}")
        
        return True
    
    def get_cpu_temp(self):
        """Get CPU temperature"""
        try:
            with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
                temp = int(f.read()) / 1000
                return temp
        except:
            return 0.0
    
    def get_ip_address(self):
        """Get primary IP address"""
        try:
            result = subprocess.run(
                ['hostname', '-I'], 
                capture_output=True, 
                text=True
            )
            ip = result.stdout.strip().split()[0]
            return ip
        except:
            return "Unknown"
    
    def get_time(self):
        """Get current time"""
        from datetime import datetime
        return datetime.now().strftime("%H:%M:%S")
    
    def get_color_for_percentage(self, percentage):
        """Get color based on percentage (green -> yellow -> red)"""
        if percentage < 50:
            return "#4CAF50"  # Green
        elif percentage < 75:
            return "#FFC107"  # Yellow
        else:
            return "#F44336"  # Red
    
    def get_color_for_temp(self, temp):
        """Get color based on temperature"""
        if temp < 60:
            return "#4CAF50"  # Green
        elif temp < 75:
            return "#FFC107"  # Yellow
        else:
            return "#F44336"  # Red
    
    def on_refresh_clicked(self, widget):
        """Handle refresh button click"""
        self.update_stats()
        self.status_label.set_markup(
            '<span size="small" foreground="#4CAF50">Stats refreshed!</span>'
        )
    
    def on_terminal_clicked(self, widget):
        """Handle terminal button click"""
        try:
            subprocess.Popen(['lxterminal'])
        except:
            try:
                subprocess.Popen(['xterm'])
            except:
                self.status_label.set_markup(
                    '<span size="small" foreground="#F44336">Could not open terminal</span>'
                )
    
    def on_browser_clicked(self, widget):
        """Handle browser button click"""
        try:
            subprocess.Popen(['chromium-browser', 'http://localhost:8080'])
        except:
            try:
                subprocess.Popen(['firefox', 'http://localhost:8080'])
            except:
                self.status_label.set_markup(
                    '<span size="small" foreground="#F44336">Could not open browser</span>'
                )
    
    def on_exit_fullscreen_clicked(self, widget):
        """Handle exit fullscreen button click"""
        self.unfullscreen()

def main():
    """Main entry point"""
    win = RaspberryPiGUI()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()

if __name__ == '__main__':
    main()

