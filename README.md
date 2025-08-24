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

- `overlays/`: Contains all overlay files to be applied to the base OS
- `configs/`: Configuration files including WiFi credentials
- `scripts/`: Helper scripts for building and configuring the OS
- `firstrun.sh`: First-boot setup script
- `setup-from-github.sh`: Script to set up the system from this repository

## Installation Methods

### Method 1: Using a Pre-configured SD Card

If you already have a pre-configured SD card:

1. Insert the SD card into your Raspberry Pi 3B
2. Power on the Raspberry Pi
3. Wait for the first-boot process to complete (5-10 minutes)
4. After reboot, the system will auto-login and start the GUI

### Method 2: Setting Up on an Existing Raspberry Pi OS

If you have a Raspberry Pi already running Raspberry Pi OS:

1. Connect to the internet
2. Run the following commands:

```bash
# Download the setup script
curl -L -o setup.sh https://raw.githubusercontent.com/5u00n/my_rasp_OS/main/setup-from-github.sh

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
git clone https://github.com/5u00n/my_rasp_OS.git
cd my_rasp_OS
```

3. Run the SD card setup script:

```bash
sudo ./fix-sd-card.sh
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

## Troubleshooting

See `FINAL_INSTRUCTIONS.md` for detailed troubleshooting information.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
