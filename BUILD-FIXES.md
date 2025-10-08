# Build Script Fixes - Issue Resolution

## 🐛 Issues Fixed

### 1. **Missing `xxd` Dependency** ✅

**Problem**: Build script was missing the `xxd` (hex dump utility) package

**Solution**: Added to package list:

```bash
xxd
vim-common    # xxd is part of vim-common package
```

**What it does**:

- `xxd` creates hex dumps of files
- Required by some pi-gen scripts for binary file processing
- Part of standard build tools

---

### 2. **"No Custom GUI Script Found" Error** ✅

**Problem**: GUI files weren't being copied from `overlays/` directory during build

**Root Cause**:

- Path resolution issue when entering `pi-gen/` subdirectory
- Build script couldn't find `../overlays/` correctly

**Solution**: Added proper path resolution:

```bash
# Determine the base directory (go up one level from pi-gen)
BASE_DIR="$(cd .. && pwd)"
log "Looking for GUI files in: $BASE_DIR/overlays/"

# Now properly finds files at:
# $BASE_DIR/overlays/usr/local/bin/raspberry-pi-smart-tv-gui.py
```

**What this fixes**:

- ✅ Correctly locates GUI files in repository
- ✅ Copies Smart TV interface to build
- ✅ Shows clear debug messages about file location
- ✅ Falls back to creating GUI if files not found

---

### 3. **Samba Configuration: "No Such File or Directory"** ✅

**Problem**: `/etc/samba/smb.conf` didn't exist when trying to append configuration

**Root Cause**:

- Samba package installed but config file not always created automatically
- Script tried to append to non-existent file

**Solution**: Added file existence check and creation:

```bash
# Configure Samba
mkdir -p /etc/samba

# Check if smb.conf exists, create basic one if not
if [ ! -f /etc/samba/smb.conf ]; then
  cat > /etc/samba/smb.conf << 'SMBCONF'
[global]
   workgroup = WORKGROUP
   server string = Raspberry Pi Custom OS
   security = user
   map to guest = Bad User
SMBCONF
fi

# Now safe to append pi share configuration
cat >> /etc/samba/smb.conf << 'SAMBA'
[pi]
   path = /home/pi
   ...
SAMBA
```

**Additional improvements**:

- ✅ Creates `/etc/samba` directory if missing
- ✅ Creates base config with sensible defaults
- ✅ Appends share configuration safely
- ✅ Sets proper permissions (create_mask, directory_mask)
- ✅ Enables both smbd and nmbd services
- ✅ Handles errors gracefully with `|| true`

---

## 📦 Complete Package List (Updated)

### Core Dependencies Now Include:

```bash
# Build essentials
pigz                  # Parallel gzip
coreutils             # Core utilities
quilt                 # Patch management
parted                # Partition editor
qemu-user-static      # ARM emulation
debootstrap           # Debian bootstrap
zerofree              # Zero unused filesystem blocks
zip/unzip             # Compression
dosfstools            # FAT filesystem tools
libarchive-tools      # bsdtar (archive tools)
libcap2-bin           # Capability tools
grep/rsync            # Search and sync
xz-utils              # XZ compression
file                  # File type detection
git/curl              # Version control & downloads
bc                    # Calculator
qemu-utils            # QEMU utilities
kpartx                # Partition mapping
arch-test             # Architecture testing
binfmt-support        # Binary format support
fdisk                 # Partition table editor
gpg/e2fsprogs         # Encryption & filesystem
whois                 # Domain lookup
xxd                   # ✅ NEW: Hex dump utility
vim-common            # ✅ NEW: Provides xxd
python3/python3-pip   # Python environment
```

### Optional (with fallbacks):

```bash
pixz or pxz           # Parallel XZ (faster compression)
```

---

## 🔍 Debug Information Added

The script now shows helpful debug messages:

```bash
[12:34:56] Looking for GUI files in: /path/to/raspberry-pi-3b_customos-tv-cast/overlays/
[12:34:56] ✓ Smart TV GUI script copied from repository

# Or if not found:
[12:34:56] ⚠ Custom GUI script not found at /path/to/raspberry-pi-3b_customos-tv-cast/overlays/usr/local/bin/
[12:34:56] ⚠ Will create Smart TV interface during build
```

---

## 🧪 Testing the Fixes

### Test 1: Check Dependencies

```bash
# Verify xxd is installed
which xxd
xxd -version

# Should show: /usr/bin/xxd
```

### Test 2: Check GUI Files

```bash
# Before running build, verify files exist
ls -la overlays/usr/local/bin/raspberry-pi-smart-tv-gui.py

# Should show the file
```

### Test 3: Check Samba Config (After Build)

```bash
# On the built Pi image
cat /etc/samba/smb.conf

# Should show:
# [global]
# ...
# [pi]
# path = /home/pi
# ...
```

---

## 🚀 Usage

### Run the Updated Build Script:

```bash
cd /path/to/raspberry-pi-3b_customos-tv-cast

# The script now handles all three issues automatically
./BUILD-DEBIAN-AMD64.sh
```

### Expected Output:

```
📦 Step 2/6: Installing build dependencies
   Installing required packages...
   [includes xxd, vim-common...]
   ✓ All dependencies installed successfully!

📥 Step 3/6: Setting up pi-gen build system
   ...

⚙️  Step 4/6: Configuring custom Raspberry Pi OS
   Creating custom GUI configuration...
   Looking for GUI files in: /path/to/repo/overlays/
   ✓ Smart TV GUI script copied from repository
   ...
```

---

## 📋 Summary of Changes

### BUILD-DEBIAN-AMD64.sh:

1. **Line 158-159**: Added `xxd` and `vim-common` packages
2. **Line 343-363**: Enhanced GUI file path resolution
3. **Line 562-594**: Fixed Samba configuration with safety checks

### Files Modified:

- ✅ `BUILD-DEBIAN-AMD64.sh` - Main build script with all fixes

### Files Created:

- ✅ `BUILD-FIXES.md` - This document
- ✅ `check-build-deps.sh` - Dependency verification script
- ✅ `DEBIAN-PACKAGES-GUIDE.md` - Complete package reference

---

## ✅ Verification Checklist

Before building, verify:

- [ ] Run `./check-build-deps.sh` - All dependencies installed
- [ ] Check `overlays/usr/local/bin/raspberry-pi-smart-tv-gui.py` exists
- [ ] Verify you're in the project root directory
- [ ] Have at least 20GB free disk space
- [ ] Running on Debian/Ubuntu AMD64 system

After building, verify:

- [ ] No "xxd: command not found" errors
- [ ] GUI script was copied successfully
- [ ] Samba configuration created properly
- [ ] Build completed without errors
- [ ] Image file created in `pi-gen/deploy/`

---

## 🎯 Quick Fix Commands

If you still encounter issues:

### Issue 1: xxd missing

```bash
sudo apt-get install xxd vim-common
```

### Issue 2: GUI not found

```bash
# Verify files exist before building
ls -la overlays/usr/local/bin/*.py

# If missing, ensure you're in the correct directory
pwd
# Should show: /path/to/raspberry-pi-3b_customos-tv-cast
```

### Issue 3: Samba errors

```bash
# The script now handles this automatically
# But if needed manually:
sudo apt-get install samba samba-common-bin
```

---

## 📝 Notes

1. **xxd**: Essential for hex operations in pi-gen scripts
2. **GUI Files**: Must exist in `overlays/` before building
3. **Samba**: Config now created safely even if package doesn't provide default

All three issues are now **automatically handled** by the build script! 🎉

---

## 🔗 Related Documentation

- `DEBIAN-PACKAGES-GUIDE.md` - Complete package reference
- `check-build-deps.sh` - Dependency verification tool
- `SMART-TV-FEATURES.md` - Smart TV interface documentation
- `GITHUB-BUILD-FIXES.md` - GitHub Actions fixes

---

**Updated**: All fixes applied and tested ✅
