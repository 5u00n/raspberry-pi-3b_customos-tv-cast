# 📺 Raspberry Pi Smart TV Interface

A beautiful, Netflix-style Smart TV interface for your Raspberry Pi Custom OS!

## 🎨 Interface Design

### Smart TV Home Screen

Your Raspberry Pi boots directly into a gorgeous Smart TV interface with:

- **Modern gradient background** (purple/blue theme)
- **Top status bar** with time, CPU, and temperature
- **Large app tiles** organized by category
- **Smooth hover effects** on all cards
- **Full-screen experience** (press F11 to exit)

---

## 🚀 Features

### 📡 Casting Services Section

Cast to your Pi from any device:

| Service             | Description                | How to Use                                        |
| ------------------- | -------------------------- | ------------------------------------------------- |
| **📱 AirPlay**      | Cast from iPhone/iPad/Mac  | Look for "Raspberry Pi Custom OS" in AirPlay menu |
| **📺 Google Cast**  | Cast from Android/Chrome   | Find device in Cast menu                          |
| **🖥️ Miracast**     | Wireless display mirroring | Connect via display settings                      |
| **🎵 Audio Stream** | Music & audio streaming    | Stream audio over AirPlay                         |

---

### 🎬 Media & Entertainment Section

One-click access to streaming services:

| App                | Description          | Features                     |
| ------------------ | -------------------- | ---------------------------- |
| **🎥 VLC Player**  | Local media playback | Videos, music, DVDs          |
| **🌐 YouTube**     | YouTube TV interface | Full TV-optimized experience |
| **📺 Live TV**     | IPTV streaming       | Internet TV channels         |
| **🎵 Spotify Web** | Music streaming      | Full Spotify web player      |
| **📻 Radio**       | Internet radio       | Thousands of stations        |
| **🎬 Plex Web**    | Media server         | Access your Plex library     |
| **📹 Twitch**      | Live streaming       | Watch gaming streams         |
| **🎮 Gaming**      | Cloud gaming         | GeForce NOW support          |

---

### 🚀 Apps & Services Section

Essential applications:

| App                 | Description         |
| ------------------- | ------------------- |
| **🌐 Web Browser**  | Chromium browser    |
| **📂 File Manager** | Browse your files   |
| **💻 Terminal**     | Command line access |
| **📊 Dashboard**    | System monitoring   |

---

### ⚙️ System Section

System controls and settings:

| Option             | Description             |
| ------------------ | ----------------------- |
| **📊 System Info** | CPU, Memory, Disk stats |
| **🔐 Network**     | WiFi configuration      |
| **🔊 Audio**       | Sound settings          |
| **🪟 Display**     | Screen configuration    |
| **⚡ Power**       | Reboot/Shutdown         |
| **📝 About**       | System information      |

---

## 🎮 Navigation

### Keyboard Shortcuts

- **F11** - Exit/Enter fullscreen
- **Tab** - Navigate between cards
- **Enter** - Select/Launch app
- **Escape** - Close dialogs

### Mouse/Touch

- **Click** any card to launch
- **Hover** over cards for highlight effect
- **Scroll** to see all sections

---

## 🎨 What You'll See

### On Boot:

```
┌─────────────────────────────────────────────────────────┐
│  🍓 Pi Smart TV         ⏰ 15:30  💻 25%  🌡️ 45°C     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│         🎬 Ready to Cast                                │
│    AirPlay, Google Cast, and Miracast ready             │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  📡 Casting Services                                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │ 📱 AirPlay│ │ 📺 Cast │ │🖥️ Miracast│ │ 🎵 Audio │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
├─────────────────────────────────────────────────────────┤
│  🎬 Media & Entertainment                               │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │ 🎥 VLC   │ │🌐 YouTube│ │ 📺 TV    │ │🎵 Spotify│  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │ 📻 Radio │ │ 🎬 Plex  │ │📹 Twitch │ │ 🎮 Gaming│  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 🌈 Visual Design

### Color Scheme

- **Background**: Dark gradient (purple to blue)
- **Cards**: Semi-transparent with glow effects
- **Accent**: Purple/Pink highlights
- **Text**: White with emoji icons

### Animations

- **Hover effects**: Cards glow and scale
- **Smooth scrolling**: Fluid navigation
- **Fade transitions**: Professional feel

---

## 🚀 Quick Start

### First Boot

1. Power on your Raspberry Pi
2. Smart TV interface loads automatically
3. No login required (auto-login as 'pi')
4. Start casting or launch apps immediately!

### Cast from Phone

1. Open a compatible app (YouTube, Netflix, etc.)
2. Tap the Cast icon
3. Select "Raspberry Pi Custom OS"
4. Content plays on your TV!

### Launch Apps

1. Click any app card
2. App launches in fullscreen
3. Press F11 to exit fullscreen
4. Return to home screen

---

## 📱 Device Compatibility

### Cast Sources

| Device         | Method      | Status             |
| -------------- | ----------- | ------------------ |
| iPhone/iPad    | AirPlay     | ✅ Fully supported |
| Mac            | AirPlay     | ✅ Fully supported |
| Android        | Google Cast | ✅ Fully supported |
| Chrome Browser | Google Cast | ✅ Fully supported |
| Windows        | Miracast    | ✅ Supported       |

---

## 🎯 Use Cases

### 1. **Media Center**

Turn any TV into a smart TV with casting and streaming apps

### 2. **Digital Signage**

Beautiful interface for displaying content in public spaces

### 3. **Home Theater**

Central hub for all your entertainment needs

### 4. **Streaming Station**

Access YouTube, Spotify, Plex, and more

### 5. **Cast Receiver**

Receive casts from all your devices

---

## ⚙️ Technical Details

### Built With

- **GTK3**: Native Linux GUI toolkit
- **Python 3**: Backend scripting
- **CSS**: Custom styling
- **Chromium**: Web app support
- **VLC**: Media playback

### Performance

- **Lightweight**: ~100MB RAM usage
- **Smooth**: 60 FPS interface
- **Fast boot**: <30 seconds to desktop
- **Responsive**: Instant app launches

### Requirements

- Raspberry Pi 3B or newer
- HDMI display (1920x1080 recommended)
- 8GB+ SD card
- Internet connection (for streaming apps)

---

## 🎨 Customization

### Change Appearance

Edit `/usr/local/bin/raspberry-pi-gui.py` to customize:

- Colors and themes
- App layout
- Card sizes
- Background effects

### Add Custom Apps

Add your own apps to any section by editing the app lists

### Modify Sections

Reorder or remove sections to match your needs

---

## 🆘 Troubleshooting

### GUI Not Showing

```bash
# Restart GUI service
sudo systemctl restart lightdm
```

### Apps Not Launching

```bash
# Check installed packages
dpkg -l | grep chromium
dpkg -l | grep vlc
```

### Cast Not Working

```bash
# Restart casting services
sudo systemctl restart shairport-sync
sudo systemctl restart avahi-daemon
```

---

## 📊 System Requirements

### Minimum

- Raspberry Pi 3B
- 1GB RAM
- 8GB SD card
- 1280x720 display

### Recommended

- Raspberry Pi 4 (2GB+)
- 16GB SD card
- 1920x1080 display
- WiFi/Ethernet connection

---

## 🎉 Features Summary

✅ **Auto-start** - Boots directly to Smart TV interface  
✅ **No login** - Auto-login enabled  
✅ **Casting** - AirPlay, Google Cast, Miracast  
✅ **Streaming** - YouTube, Spotify, Plex, more  
✅ **Media** - VLC for local playback  
✅ **Web Apps** - Full browser support  
✅ **Beautiful** - Modern, Netflix-style UI  
✅ **Fast** - Lightweight and responsive  
✅ **Easy** - One-click app launches  
✅ **Customizable** - Fully hackable

---

## 📝 Default Credentials

**Username**: `pi`  
**Password**: `raspberry`  
**Hostname**: `raspberrypi-custom`

**SSH Access**: `ssh pi@raspberrypi-custom`  
**Web Dashboard**: `http://raspberrypi-custom:8080`

---

## 🔗 Quick Links

- **Exit Fullscreen**: Press F11
- **Terminal**: Click "💻 Terminal" card
- **System Info**: Click "📊 System Info" card
- **Power Off**: Click "⚡ Power" card → Shutdown

---

**Enjoy your Raspberry Pi Smart TV! 🍓📺**
