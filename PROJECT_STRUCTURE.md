# Project Structure

This document provides a detailed overview of the project organization and file purposes.

## Root Directory

```
raspberry-pi-3b_customos-tv-cast/
├── README.md                   # Main project documentation
├── PROJECT_SUMMARY.md          # Project overview and summary
├── PROJECT_STRUCTURE.md        # This file - project organization
├── install.sh                  # One-line GitHub installer
├── setup-from-github.sh        # Main setup script
├── firstrun.sh                 # First-boot configuration script
└── .gitignore                  # Git ignore patterns
```

## Configuration Files

```
configs/
├── config.txt                  # Boot configuration
├── firstrun.sh                 # First-run setup script
├── wifi-credentials.txt        # WiFi network credentials
└── wpa_supplicant.conf         # WiFi supplicant configuration
```

## System Overlays

```
overlays/
├── etc/                        # System configuration overlays
│   ├── rc.local               # Boot script
│   ├── lightdm/               # Display manager config
│   ├── network/               # Network configuration
│   └── systemd/system/        # Service definitions
├── home/pi/                   # User home directory overlays
├── usr/local/bin/             # Custom binaries and scripts
└── var/www/templates/         # Web interface templates
```

## Scripts Directory

### Build Scripts

```
scripts/build/
├── build-complete-image.sh     # Complete system image builder
├── build-manager.sh            # Build process manager
├── build-with-docker.sh        # Docker-based build system
├── create-test-image.sh        # Test image creator
└── docker-build.sh             # Docker container builder
```

### Test Scripts

```
scripts/test/
├── test-complete-build.sh      # Complete build testing
├── test-full-image.sh          # Full image testing
├── test-in-qemu.sh             # QEMU testing
├── test-qemu-improved.sh       # Enhanced QEMU testing
├── test-qemu.sh                # Basic QEMU testing
├── test-raspberry-pi-macos.sh  # macOS testing script
├── test-sd-in-qemu.sh          # SD card QEMU testing
├── backup-and-test.sh          # Backup and testing
├── verify-and-test-complete.sh # Complete verification
├── verify-build-complete.sh    # Build verification
└── verify-sd-card.sh           # SD card verification
```

### Setup Scripts

```
scripts/setup/
├── add-firstrun-to-sd.sh       # Add firstrun script to SD card
├── fix-sd-card.sh              # SD card preparation and fixing
├── git-setup.sh                # Git repository setup
└── check-git-files.sh          # Git file verification
```

### Legacy Scripts Directory

```
scripts/
├── build-macos.sh              # macOS build script
├── build.sh                    # General build script
├── flash-with-overlay.sh       # Flash with overlay application
├── flash.sh                    # Basic flashing script
├── prepare-sd-card.sh          # SD card preparation
├── setup.sh                    # General setup script
├── test-on-real-hardware.sh    # Real hardware testing
└── test.sh                     # General testing script
```

## Documentation

```
docs/
├── BUILD.md                    # Build instructions
├── INSTALLATION.md             # Installation guide
├── FINAL_INSTRUCTIONS.md       # Complete usage instructions
├── TROUBLESHOOTING_GUIDE.md    # Troubleshooting and fixes
├── MACBOOK_TESTING_GUIDE.md    # macOS testing guide
├── REAL_HARDWARE_GUIDE.md      # Hardware testing guide
├── WIFI_SETUP_INSTRUCTIONS.md  # WiFi configuration
├── AUTO_LOGIN_GOOGLE_CAST_FEATURES.md # Feature documentation
└── GITHUB_SETUP_STEPS.md       # GitHub setup guide
```

## Development Files

### Docker

```
docker/
└── Dockerfile                  # Container definition for builds
```

### QEMU Testing

```
qemu/
├── kernel-qemu-4.19.50-buster  # QEMU kernel
└── versatile-pb-buster.dtb     # Device tree blob
```

### Package Management

```
packages/
└── packages.txt                # List of required packages
```

### Kernel Files

```
kernel/
└── (kernel modules and files)
```

## Build and Output Directories

### Build Artifacts

```
build/
├── base-os.img                 # Base OS image
├── base-os.img.xz              # Compressed base image
├── build-macos.log             # macOS build log
├── build.log                   # General build log
├── prepare-sd-card.log         # SD card preparation log
├── Dockerfile                  # Build-specific Dockerfile
└── mnt/                        # Mount points
    ├── boot/                   # Boot partition mount
    └── rootfs/                 # Root filesystem mount
```

### Final Outputs

```
output/
├── customized-pi-os.img        # Final customized image
├── raspberry-pi-os-final.img   # Final Raspberry Pi OS
├── raspberry-pi-os-fixed.img   # Fixed version
├── raspberry-pi-os.img         # Base Raspberry Pi OS
├── sd_card_backup.img          # SD card backup
├── sd-card-backup.img          # Alternative backup
├── test-image.img              # Test image
├── overlay_test/               # Overlay testing files
└── qemu_temp/                  # QEMU temporary files
```

## Usage Guidelines

### For End Users

- Start with `README.md`
- Use `install.sh` for quick setup
- Refer to `docs/` for detailed guides

### For Developers

- Study `PROJECT_SUMMARY.md` for project overview
- Use `scripts/build/` for building images
- Use `scripts/test/` for testing
- Use `scripts/setup/` for environment setup

### For Contributors

- Check `docs/GITHUB_SETUP_STEPS.md` for repository setup
- Follow `docs/BUILD.md` for build instructions
- Use `docs/TROUBLESHOOTING_GUIDE.md` for common issues

## File Naming Conventions

- **Scripts**: Use kebab-case with descriptive names (e.g., `test-in-qemu.sh`)
- **Documentation**: Use UPPERCASE for major docs (e.g., `README.md`)
- **Configuration**: Use lowercase with hyphens (e.g., `wifi-credentials.txt`)
- **Images**: Use descriptive names with purpose (e.g., `raspberry-pi-os-final.img`)

This structure ensures easy navigation, clear purpose definition, and maintainable organization.
