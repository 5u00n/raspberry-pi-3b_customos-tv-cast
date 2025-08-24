# Raspberry Pi 3B Custom OS

A custom Raspberry Pi OS for Raspberry Pi 3B with auto-login, GUI, AirPlay, Google Cast, Miracast, remote control interface, and WiFi security tools.

## Features

- **Auto-login without password**
- **Graphical user interface** that starts automatically
- **Wireless display protocols**:
  - AirPlay (for Apple devices)
  - Google Cast (for Android/Chrome devices)
  - Miracast (for Windows/Android devices)
- **Remote control interface** accessible via WiFi
- **WiFi security tools** (wifite/aircrack) running in the background
- **File servers** for accessing captured data

## Repository Structure

### Core Files

- `install.sh`: One-line installer script for GitHub installation
- `setup-from-github.sh`: Main setup script that configures the system
- `firstrun.sh`: First-boot setup script that runs automatically
- `README.md`: This file with installation and usage instructions
- `PROJECT_STRUCTURE.md`: Detailed project organization and file reference guide

### Configuration

- `configs/`: Configuration files including WiFi credentials and system settings
- `overlays/`: System overlay files to be applied to the base OS
- `packages/`: Package lists and dependencies

### Scripts

- `scripts/build/`: Build and compilation scripts
  - Build system images, Docker containers, etc.
- `scripts/test/`: Testing and verification scripts
  - QEMU testing, hardware validation, etc.
- `scripts/setup/`: Setup and configuration scripts
  - SD card preparation, Git setup, etc.

### Documentation

- `docs/`: Comprehensive documentation and guides
  - Installation guides, troubleshooting, hardware testing, etc.

### Development

- `docker/`: Docker-related files for containerized builds
- `qemu/`: QEMU emulation files and kernels for testing
- `kernel/`: Kernel files and modules
- `build/`: Build artifacts and temporary files
- `output/`: Generated images and final outputs

## Quick Start - GitHub Installation

The fastest way to get started is using our one-line installer directly from GitHub:

### Prerequisites

- Raspberry Pi 3B with a fresh Raspberry Pi OS installation
- Internet connection (WiFi or Ethernet)
- Terminal access (either directly on Pi or via SSH)

### One-Line Installation

```bash
curl -L https://raw.githubusercontent.com/5u00n/raspberry-pi-3b_customos-tv-cast/main/install.sh | sudo bash
```

This command will:

1. Download the latest setup script from GitHub
2. Install all required packages
3. Configure your system with all features
4. Set up WiFi credentials (you'll be prompted)
5. Enable auto-login and GUI
6. Install AirPlay, Google Cast, and Miracast support
7. Set up background WiFi tools
8. Reboot your system when complete

### Alternative GitHub Installation

If you prefer to download and inspect the script first:

```bash
# Download the installer
curl -L -o install.sh https://raw.githubusercontent.com/5u00n/raspberry-pi-3b_customos-tv-cast/main/install.sh

# Review the script (optional but recommended)
cat install.sh

# Make it executable and run
chmod +x install.sh
sudo ./install.sh
```

### Manual GitHub Clone Method

For developers or advanced users who want to modify the configuration:

```bash
# Clone the repository
git clone https://github.com/5u00n/raspberry-pi-3b_customos-tv-cast.git

# Navigate to the directory
cd raspberry-pi-3b_customos-tv-cast

# Run the setup script
sudo ./setup-from-github.sh
```

## Installation Methods

### Method 1: Using a Pre-configured SD Card

If you already have a pre-configured SD card:

1. Insert the SD card into your Raspberry Pi 3B
2. Power on the Raspberry Pi
3. Wait for the first-boot process to complete (5-10 minutes)
4. After reboot, the system will auto-login and start the GUI

### Method 2: GitHub Installation (Recommended)

**This is the recommended method for most users.**

If you have a Raspberry Pi already running Raspberry Pi OS, you can use our GitHub installer:

1. Connect to the internet
2. Run the one-line installer:

```bash
curl -L https://raw.githubusercontent.com/5u00n/raspberry-pi-3b_customos-tv-cast/main/install.sh | sudo bash
```

**OR** use the manual download method:

```bash
# Download the setup script
curl -L -o setup.sh https://raw.githubusercontent.com/5u00n/raspberry-pi-3b_customos-tv-cast/main/setup-from-github.sh

# Make it executable
chmod +x setup.sh

# Run the script
sudo ./setup.sh
```

3. Follow the prompts to enter your WiFi credentials
4. When prompted, reboot your Raspberry Pi
5. Wait for the first-boot process to complete (5-10 minutes)
6. After reboot, the system will auto-login and start the GUI

### Method 3: Manual SD Card Setup

To manually set up an SD card:

1. Flash a fresh Raspberry Pi OS Lite image to an SD card
2. Clone this repository:

```bash
git clone https://github.com/5u00n/raspberry-pi-3b_customos-tv-cast.git
cd raspberry-pi-3b_customos-tv-cast
```

3. Run the SD card setup script:

```bash
sudo ./scripts/setup/fix-sd-card.sh
```

4. Follow the prompts to select your SD card
5. Insert the SD card into your Raspberry Pi 3B and boot

## WiFi Configuration

The system is pre-configured to connect to the following WiFi networks:

1. "connection" (Priority 1)
2. "Nomita" (Priority 2)

To change these networks:

1. Edit the `configs/wifi-credentials.txt` file
2. Run the setup script again

## What Happens After Installation

After running any of the installation methods above:

1. **First Boot**: The system will automatically configure itself (takes 5-10 minutes)
2. **Auto-Login**: System will log in automatically without password prompt
3. **GUI Launch**: Graphical interface starts automatically showing system status
4. **Services Start**: All wireless display services (AirPlay, Google Cast, Miracast) start automatically
5. **WiFi Connection**: Connects to your configured networks automatically
6. **Remote Access**: Web interface available at `http://<pi-ip-address>:8080`

## Accessing Your Raspberry Pi

### Local Access

- **Direct**: Connect monitor and keyboard - system auto-logs in
- **GUI**: Graphical interface shows system status and controls

### Remote Access

- **SSH**: `ssh pi@<raspberry-pi-ip>` (password: `raspberry`)
- **Web Interface**: `http://<raspberry-pi-ip>:8080`
- **File Access**: Samba shares available for captured WiFi data

### Using Wireless Display Features

- **From iPhone/iPad**: Use AirPlay to mirror screen
- **From Android**: Use Google Cast or Miracast
- **From Windows**: Use Miracast projection
- **From Chrome**: Cast tab or desktop

## Troubleshooting

See `docs/TROUBLESHOOTING_GUIDE.md` for detailed troubleshooting information.

## Documentation

- `docs/FINAL_INSTRUCTIONS.md`: Complete setup and usage instructions
- `docs/MACBOOK_TESTING_GUIDE.md`: Guide for testing on macOS with QEMU
- `docs/REAL_HARDWARE_GUIDE.md`: Guide for testing on actual Raspberry Pi hardware
- `docs/WIFI_SETUP_INSTRUCTIONS.md`: Detailed WiFi configuration instructions
- `docs/AUTO_LOGIN_GOOGLE_CAST_FEATURES.md`: Feature documentation
- `docs/GITHUB_SETUP_STEPS.md`: GitHub repository setup guide

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
