#!/usr/bin/env python3
"""
Raspberry Pi Smart TV Interface
A beautiful Smart TV-style GUI for Raspberry Pi Custom OS
"""

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib, Gdk, GdkPixbuf
import psutil
import subprocess
import os
from datetime import datetime

class SmartTVApp(Gtk.Window):
    def __init__(self):
        super().__init__(title="Raspberry Pi Smart TV")
        self.set_default_size(1920, 1080)
        self.fullscreen()
        
        # Main container
        self.main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.add(self.main_box)
        
        # Top bar
        self.create_top_bar()
        
        # Content area (scrollable)
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.main_box.pack_start(scrolled, True, True, 0)
        
        # Content container
        self.content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=30)
        self.content_box.set_margin_left(60)
        self.content_box.set_margin_right(60)
        self.content_box.set_margin_top(30)
        self.content_box.set_margin_bottom(30)
        scrolled.add(self.content_box)
        
        # Add sections
        self.create_featured_section()
        self.create_casting_section()
        self.create_media_section()
        self.create_apps_section()
        self.create_system_section()
        
        # Apply styling
        self.apply_css()
        
        # Update stats
        GLib.timeout_add_seconds(5, self.update_status)
        self.update_status()
    
    def create_top_bar(self):
        """Create top navigation bar like Smart TV"""
        top_bar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        top_bar.set_spacing(20)
        top_bar.set_margin_start(40)
        top_bar.set_margin_end(40)
        top_bar.set_margin_top(20)
        top_bar.set_margin_bottom(20)
        
        # Logo/Title
        logo_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        logo = Gtk.Label()
        logo.set_markup('<span size="xx-large" weight="bold">🍓</span>')
        logo_box.pack_start(logo, False, False, 0)
        
        title = Gtk.Label()
        title.set_markup('<span size="x-large" weight="bold">Pi Smart TV</span>')
        logo_box.pack_start(title, False, False, 0)
        top_bar.pack_start(logo_box, False, False, 0)
        
        # Spacer
        top_bar.pack_start(Gtk.Box(), True, True, 0)
        
        # Status info
        self.status_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=15)
        
        # Time
        self.time_label = Gtk.Label()
        self.time_label.set_markup('<span size="large">⏰ 00:00</span>')
        self.status_box.pack_start(self.time_label, False, False, 0)
        
        # CPU
        self.cpu_indicator = Gtk.Label()
        self.cpu_indicator.set_markup('<span size="large">💻 0%</span>')
        self.status_box.pack_start(self.cpu_indicator, False, False, 0)
        
        # Temp
        self.temp_indicator = Gtk.Label()
        self.temp_indicator.set_markup('<span size="large">🌡️ 0°C</span>')
        self.status_box.pack_start(self.temp_indicator, False, False, 0)
        
        top_bar.pack_start(self.status_box, False, False, 0)
        
        self.main_box.pack_start(top_bar, False, False, 0)
    
    def create_featured_section(self):
        """Create featured/hero section"""
        section = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        
        title = Gtk.Label()
        title.set_markup('<span size="xx-large" weight="bold">Welcome to Your Smart TV</span>')
        title.set_xalign(0)
        section.pack_start(title, False, False, 0)
        
        subtitle = Gtk.Label()
        subtitle.set_markup('<span size="large">Cast, Stream, and Control Your Entertainment</span>')
        subtitle.set_xalign(0)
        section.pack_start(subtitle, False, False, 0)
        
        # Featured card
        featured_card = self.create_large_card(
            "🎬 Ready to Cast",
            "AirPlay, Google Cast, and Miracast ready",
            self.on_open_casting_info
        )
        section.pack_start(featured_card, False, False, 0)
        
        self.content_box.pack_start(section, False, False, 0)
    
    def create_casting_section(self):
        """Create casting services section"""
        section_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        
        title = Gtk.Label()
        title.set_markup('<span size="x-large" weight="bold">📡 Casting Services</span>')
        title.set_xalign(0)
        section_box.pack_start(title, False, False, 0)
        
        # Grid of casting apps
        grid = Gtk.FlowBox()
        grid.set_max_children_per_line(4)
        grid.set_row_spacing(20)
        grid.set_column_spacing(20)
        grid.set_selection_mode(Gtk.SelectionMode.NONE)
        
        casting_apps = [
            ("📱 AirPlay", "Cast from iPhone/iPad/Mac", self.on_airplay_info),
            ("📺 Google Cast", "Cast from Android/Chrome", self.on_cast_info),
            ("🖥️ Miracast", "Wireless Display", self.on_miracast_info),
            ("🎵 Audio Stream", "Stream Music & Audio", self.on_audio_info),
        ]
        
        for app_name, app_desc, callback in casting_apps:
            card = self.create_app_card(app_name, app_desc, callback)
            grid.add(card)
        
        section_box.pack_start(grid, False, False, 0)
        self.content_box.pack_start(section_box, False, False, 0)
    
    def create_media_section(self):
        """Create media apps section"""
        section_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        
        title = Gtk.Label()
        title.set_markup('<span size="x-large" weight="bold">🎬 Media & Entertainment</span>')
        title.set_xalign(0)
        section_box.pack_start(title, False, False, 0)
        
        grid = Gtk.FlowBox()
        grid.set_max_children_per_line(4)
        grid.set_row_spacing(20)
        grid.set_column_spacing(20)
        grid.set_selection_mode(Gtk.SelectionMode.NONE)
        
        media_apps = [
            ("🎥 VLC Player", "Play Videos & Music", self.on_launch_vlc),
            ("🌐 YouTube", "Browse YouTube", self.on_launch_youtube),
            ("📺 Live TV", "IPTV Streaming", self.on_launch_iptv),
            ("🎵 Spotify Web", "Music Streaming", self.on_launch_spotify),
            ("📻 Radio", "Internet Radio", self.on_launch_radio),
            ("🎬 Plex Web", "Media Server", self.on_launch_plex),
            ("📹 Twitch", "Live Streaming", self.on_launch_twitch),
            ("🎮 Gaming", "Cloud Gaming", self.on_launch_gaming),
        ]
        
        for app_name, app_desc, callback in media_apps:
            card = self.create_app_card(app_name, app_desc, callback)
            grid.add(card)
        
        section_box.pack_start(grid, False, False, 0)
        self.content_box.pack_start(section_box, False, False, 0)
    
    def create_apps_section(self):
        """Create apps & services section"""
        section_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        
        title = Gtk.Label()
        title.set_markup('<span size="x-large" weight="bold">🚀 Apps & Services</span>')
        title.set_xalign(0)
        section_box.pack_start(title, False, False, 0)
        
        grid = Gtk.FlowBox()
        grid.set_max_children_per_line(4)
        grid.set_row_spacing(20)
        grid.set_column_spacing(20)
        grid.set_selection_mode(Gtk.SelectionMode.NONE)
        
        apps = [
            ("🌐 Web Browser", "Browse the Internet", self.on_launch_browser),
            ("📂 File Manager", "Browse Files", self.on_launch_files),
            ("💻 Terminal", "Command Line", self.on_launch_terminal),
            ("📊 Dashboard", "System Monitor", self.on_launch_dashboard),
        ]
        
        for app_name, app_desc, callback in apps:
            card = self.create_app_card(app_name, app_desc, callback)
            grid.add(card)
        
        section_box.pack_start(grid, False, False, 0)
        self.content_box.pack_start(section_box, False, False, 0)
    
    def create_system_section(self):
        """Create system settings section"""
        section_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        
        title = Gtk.Label()
        title.set_markup('<span size="x-large" weight="bold">⚙️ System</span>')
        title.set_xalign(0)
        section_box.pack_start(title, False, False, 0)
        
        grid = Gtk.FlowBox()
        grid.set_max_children_per_line(4)
        grid.set_row_spacing(20)
        grid.set_column_spacing(20)
        grid.set_selection_mode(Gtk.SelectionMode.NONE)
        
        system_items = [
            ("📊 System Info", "View System Stats", self.on_system_info),
            ("🔐 Network", "WiFi & Connection", self.on_network_settings),
            ("🔊 Audio", "Sound Settings", self.on_audio_settings),
            ("🪟 Display", "Screen Settings", self.on_display_settings),
            ("⚡ Power", "Power Options", self.on_power_menu),
            ("📝 About", "System Information", self.on_about),
        ]
        
        for app_name, app_desc, callback in system_items:
            card = self.create_app_card(app_name, app_desc, callback)
            grid.add(card)
        
        section_box.pack_start(grid, False, False, 0)
        self.content_box.pack_start(section_box, False, False, 0)
    
    def create_large_card(self, title, subtitle, callback):
        """Create a large featured card"""
        event_box = Gtk.EventBox()
        event_box.connect("button-press-event", lambda w, e: callback())
        event_box.set_name("featured-card")
        
        card_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        card_box.set_margin_start(40)
        card_box.set_margin_end(40)
        card_box.set_margin_top(60)
        card_box.set_margin_bottom(60)
        
        title_label = Gtk.Label()
        title_label.set_markup(f'<span size="xx-large" weight="bold">{title}</span>')
        card_box.pack_start(title_label, False, False, 0)
        
        subtitle_label = Gtk.Label()
        subtitle_label.set_markup(f'<span size="large">{subtitle}</span>')
        card_box.pack_start(subtitle_label, False, False, 0)
        
        event_box.add(card_box)
        return event_box
    
    def create_app_card(self, title, subtitle, callback):
        """Create an app card tile"""
        event_box = Gtk.EventBox()
        event_box.connect("button-press-event", lambda w, e: callback())
        event_box.connect("enter-notify-event", self.on_card_hover)
        event_box.connect("leave-notify-event", self.on_card_leave)
        event_box.set_name("app-card")
        
        card_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        card_box.set_size_request(250, 150)
        card_box.set_margin_start(20)
        card_box.set_margin_end(20)
        card_box.set_margin_top(20)
        card_box.set_margin_bottom(20)
        
        # Icon/Title
        title_label = Gtk.Label()
        title_label.set_markup(f'<span size="x-large" weight="bold">{title}</span>')
        title_label.set_line_wrap(True)
        title_label.set_max_width_chars(20)
        card_box.pack_start(title_label, True, True, 0)
        
        # Subtitle
        subtitle_label = Gtk.Label()
        subtitle_label.set_markup(f'<span size="small">{subtitle}</span>')
        subtitle_label.set_line_wrap(True)
        subtitle_label.set_max_width_chars(25)
        card_box.pack_start(subtitle_label, False, False, 0)
        
        event_box.add(card_box)
        return event_box
    
    def on_card_hover(self, widget, event):
        """Handle card hover effect"""
        widget.set_name("app-card-hover")
    
    def on_card_leave(self, widget, event):
        """Handle card leave effect"""
        widget.set_name("app-card")
    
    def apply_css(self):
        """Apply Smart TV styling"""
        css = b"""
        window {
            background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
        }
        
        label {
            color: #ffffff;
        }
        
        #featured-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 20px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.5);
        }
        
        #app-card {
            background: rgba(255, 255, 255, 0.1);
            border: 2px solid rgba(255, 255, 255, 0.2);
            border-radius: 15px;
            transition: all 0.3s ease;
        }
        
        #app-card-hover {
            background: rgba(255, 255, 255, 0.2);
            border: 2px solid #667eea;
            border-radius: 15px;
            box-shadow: 0 5px 20px rgba(102, 126, 234, 0.5);
        }
        
        button {
            background: rgba(102, 126, 234, 0.8);
            color: #ffffff;
            border: none;
            border-radius: 10px;
            padding: 15px 30px;
            font-weight: bold;
            font-size: 16px;
        }
        
        button:hover {
            background: rgba(118, 75, 162, 0.9);
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
    
    def update_status(self):
        """Update status indicators"""
        try:
            # Time
            current_time = datetime.now().strftime("%H:%M")
            self.time_label.set_markup(f'<span size="large">⏰ {current_time}</span>')
            
            # CPU
            cpu = psutil.cpu_percent(interval=0.1)
            self.cpu_indicator.set_markup(f'<span size="large">💻 {cpu:.0f}%</span>')
            
            # Temperature
            try:
                with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
                    temp = int(f.read()) / 1000
                self.temp_indicator.set_markup(f'<span size="large">🌡️ {temp:.0f}°C</span>')
            except:
                pass
                
        except Exception as e:
            print(f"Error updating status: {e}")
        
        return True
    
    # Callback functions
    def on_open_casting_info(self):
        self.show_info_dialog("Casting Ready", 
            "Your Raspberry Pi is ready to receive casts!\n\n" +
            "📱 AirPlay: Look for 'Raspberry Pi Custom OS'\n" +
            "📺 Google Cast: Check your Cast devices\n" +
            "🖥️ Miracast: Connect via display settings")
    
    def on_airplay_info(self):
        self.show_info_dialog("AirPlay Receiver",
            "Cast from your iPhone, iPad, or Mac\n\n" +
            "Device name: Raspberry Pi Custom OS\n" +
            "Status: Active and ready")
    
    def on_cast_info(self):
        self.show_info_dialog("Google Cast",
            "Cast from Android devices or Chrome browser\n\n" +
            "Look for this device in your Cast menu")
    
    def on_miracast_info(self):
        self.show_info_dialog("Miracast",
            "Wireless display mirroring\n\n" +
            "Connect from Windows or Android display settings")
    
    def on_audio_info(self):
        self.show_info_dialog("Audio Streaming",
            "Stream music and audio to your Pi\n\n" +
            "Supports AirPlay audio and Bluetooth")
    
    def on_launch_vlc(self):
        subprocess.Popen(['vlc'])
    
    def on_launch_youtube(self):
        subprocess.Popen(['chromium-browser', '--app=https://www.youtube.com/tv'])
    
    def on_launch_iptv(self):
        subprocess.Popen(['vlc', 'http://'])
    
    def on_launch_spotify(self):
        subprocess.Popen(['chromium-browser', '--app=https://open.spotify.com'])
    
    def on_launch_radio(self):
        subprocess.Popen(['chromium-browser', '--app=https://radio.garden'])
    
    def on_launch_plex(self):
        subprocess.Popen(['chromium-browser', '--app=https://app.plex.tv'])
    
    def on_launch_twitch(self):
        subprocess.Popen(['chromium-browser', '--app=https://www.twitch.tv'])
    
    def on_launch_gaming(self):
        subprocess.Popen(['chromium-browser', '--app=https://play.geforcenow.com'])
    
    def on_launch_browser(self):
        subprocess.Popen(['chromium-browser'])
    
    def on_launch_files(self):
        subprocess.Popen(['pcmanfm'])
    
    def on_launch_terminal(self):
        subprocess.Popen(['lxterminal'])
    
    def on_launch_dashboard(self):
        subprocess.Popen(['chromium-browser', 'http://localhost:8080'])
    
    def on_system_info(self):
        cpu = psutil.cpu_percent()
        mem = psutil.virtual_memory().percent
        disk = psutil.disk_usage('/').percent
        
        self.show_info_dialog("System Information",
            f"CPU Usage: {cpu:.1f}%\n" +
            f"Memory Usage: {mem:.1f}%\n" +
            f"Disk Usage: {disk:.1f}%\n\n" +
            f"Hostname: raspberrypi-custom\n" +
            f"User: pi")
    
    def on_network_settings(self):
        subprocess.Popen(['lxterminal', '-e', 'nmtui'])
    
    def on_audio_settings(self):
        subprocess.Popen(['pavucontrol'])
    
    def on_display_settings(self):
        self.show_info_dialog("Display Settings",
            "Press F11 to exit fullscreen\n" +
            "Use system settings for more options")
    
    def on_power_menu(self):
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.QUESTION,
            buttons=Gtk.ButtonsType.NONE,
            text="Power Options"
        )
        dialog.format_secondary_text("Choose an action:")
        dialog.add_button("Restart", 1)
        dialog.add_button("Shutdown", 2)
        dialog.add_button("Cancel", Gtk.ResponseType.CANCEL)
        
        response = dialog.run()
        if response == 1:
            subprocess.run(['sudo', 'reboot'])
        elif response == 2:
            subprocess.run(['sudo', 'shutdown', '-h', 'now'])
        
        dialog.destroy()
    
    def on_about(self):
        self.show_info_dialog("About Raspberry Pi Smart TV",
            "🍓 Raspberry Pi Custom OS\n" +
            "Version 1.0\n\n" +
            "A beautiful Smart TV interface for your Raspberry Pi\n\n" +
            "Features:\n" +
            "• AirPlay, Google Cast, Miracast\n" +
            "• Media streaming and playback\n" +
            "• Web browsing and apps\n" +
            "• System monitoring\n\n" +
            "Default credentials:\n" +
            "User: pi | Password: raspberry")
    
    def show_info_dialog(self, title, message):
        """Show an information dialog"""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            text=title
        )
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()

def main():
    win = SmartTVApp()
    win.connect("destroy", Gtk.main_quit)
    win.connect("key-press-event", lambda w, e: w.unfullscreen() if e.keyval == Gdk.KEY_F11 else None)
    win.show_all()
    Gtk.main()

if __name__ == '__main__':
    main()

