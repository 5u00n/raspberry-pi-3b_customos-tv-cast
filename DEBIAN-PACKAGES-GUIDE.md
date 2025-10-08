# Debian/Ubuntu Packages Guide for Pi-Gen Build

## 📦 Required Packages & Alternatives

### Core Build Tools

| Package            | Purpose           | Alternative     | Install Command                         |
| ------------------ | ----------------- | --------------- | --------------------------------------- |
| `libarchive-tools` | Provides `bsdtar` | `tar`           | `sudo apt-get install libarchive-tools` |
| `xz-utils`         | XZ compression    | None (required) | `sudo apt-get install xz-utils`         |
| `pigz`             | Parallel gzip     | `gzip`          | `sudo apt-get install pigz`             |
| `pixz` or `pxz`    | Parallel XZ       | `xz-utils`      | `sudo apt-get install pixz`             |

---

## 🔍 Common Issues & Solutions

### Issue 1: `bsdtar: command not found`

**Cause**: `libarchive-tools` not installed

**Solutions**:

```bash
# Option 1: Install libarchive-tools (recommended)
sudo apt-get install libarchive-tools

# Option 2: Use regular tar (fallback)
# pi-gen will use tar if bsdtar is not available
```

**Verification**:

```bash
which bsdtar     # Should show: /usr/bin/bsdtar
bsdtar --version # Should show version info
```

---

### Issue 2: `pxz: command not found`

**Cause**: `pxz` or `pixz` not in your distribution's repositories

**Solutions**:

```bash
# Option 1: Try pixz (newer package name)
sudo apt-get install pixz

# Option 2: Try pxz (older package name)
sudo apt-get install pxz

# Option 3: Use xz-utils (slower but always works)
sudo apt-get install xz-utils
# pi-gen will automatically fall back to xz if pixz/pxz not available
```

**Verification**:

```bash
which pixz       # Should show: /usr/bin/pixz
# OR
which pxz        # Should show: /usr/bin/pxz
# OR
which xz         # Should show: /usr/bin/xz (always available)
```

---

### Issue 3: `qemu-arm-static: command not found`

**Cause**: QEMU user mode emulation not installed

**Solution**:

```bash
sudo apt-get install qemu-user-static binfmt-support
```

**Verification**:

```bash
which qemu-arm-static
ls -la /usr/bin/qemu-arm-static
```

---

## 🚀 Complete Installation Command

### For Debian 11/12 or Ubuntu 20.04+:

```bash
sudo apt-get update

sudo apt-get install -y \
    coreutils \
    quilt \
    parted \
    qemu-user-static \
    debootstrap \
    zerofree \
    zip \
    unzip \
    dosfstools \
    libarchive-tools \
    libcap2-bin \
    grep \
    rsync \
    xz-utils \
    file \
    git \
    curl \
    bc \
    qemu-utils \
    kpartx \
    arch-test \
    binfmt-support \
    fdisk \
    gpg \
    e2fsprogs \
    whois \
    pigz \
    python3 \
    python3-pip

# Optional: Install parallel compression tools
sudo apt-get install -y pixz || echo "pixz not available, using xz-utils"
```

---

## 📋 Package Categories

### Essential (Must Have):

- `qemu-user-static` - ARM emulation
- `debootstrap` - Bootstrap Debian systems
- `libarchive-tools` - Archive tools (bsdtar)
- `xz-utils` - XZ compression
- `pigz` - Parallel gzip

### Important (Recommended):

- `pixz` or `pxz` - Faster compression
- `binfmt-support` - Binary format support
- `kpartx` - Partition mapping

### Optional:

- `whois` - Domain lookup (rarely needed)
- `arch-test` - Architecture testing

---

## 🔧 Troubleshooting Commands

### Check What's Installed:

```bash
# Check all build dependencies
dpkg -l | grep -E "qemu-user-static|debootstrap|libarchive|xz-utils|pigz|pixz"

# Check specific tools
which bsdtar && echo "✅ bsdtar OK" || echo "❌ bsdtar missing"
which xz && echo "✅ xz OK" || echo "❌ xz missing"
which pigz && echo "✅ pigz OK" || echo "❌ pigz missing"
which pixz && echo "✅ pixz OK" || echo "⚠️ pixz missing (optional)"
which qemu-arm-static && echo "✅ qemu-arm-static OK" || echo "❌ qemu-arm-static missing"
```

### Find Package Names:

```bash
# Search for packages
apt-cache search bsdtar
apt-cache search pixz
apt-cache search qemu-user

# Show package info
apt-cache show libarchive-tools
apt-cache show pixz
```

### Install Missing Packages:

```bash
# Install single package
sudo apt-get install <package-name>

# Install with auto-yes
sudo apt-get install -y <package-name>

# Try alternative if first fails
sudo apt-get install pixz || sudo apt-get install pxz || echo "Using xz-utils"
```

---

## 🐧 Distribution-Specific Notes

### Debian 11 (Bullseye):

- ✅ All packages available
- ✅ `pixz` package available
- ✅ `libarchive-tools` includes bsdtar

### Debian 12 (Bookworm):

- ✅ All packages available
- ✅ Latest versions
- ✅ Best compatibility

### Ubuntu 20.04 LTS:

- ✅ All packages available
- ⚠️ `pixz` may be named `pxz`
- ✅ Full support

### Ubuntu 22.04 LTS:

- ✅ All packages available
- ✅ `pixz` package available
- ✅ Recommended version

### Ubuntu 24.04 LTS:

- ✅ All packages available
- ✅ Latest tools
- ✅ Best performance

---

## 🎯 Quick Start

### Minimal Install (Just to Test):

```bash
sudo apt-get update
sudo apt-get install -y \
    qemu-user-static \
    debootstrap \
    libarchive-tools \
    xz-utils \
    pigz
```

### Full Install (Recommended):

```bash
# Just run the build script - it installs everything!
./BUILD-DEBIAN-AMD64.sh
```

---

## 📊 Package Size Reference

| Package          | Installed Size | Download Size |
| ---------------- | -------------- | ------------- |
| libarchive-tools | ~1.5 MB        | ~500 KB       |
| xz-utils         | ~500 KB        | ~150 KB       |
| pigz             | ~100 KB        | ~30 KB        |
| pixz             | ~50 KB         | ~20 KB        |
| qemu-user-static | ~50 MB         | ~15 MB        |
| debootstrap      | ~300 KB        | ~100 KB       |

**Total**: ~55-60 MB download, ~150-200 MB installed

---

## ✅ Verification Script

Save this as `check-deps.sh`:

```bash
#!/bin/bash

echo "🔍 Checking pi-gen build dependencies..."
echo ""

MISSING=0

check_cmd() {
    if command -v $1 &> /dev/null; then
        echo "✅ $1 - OK"
    else
        echo "❌ $1 - MISSING"
        MISSING=$((MISSING + 1))
    fi
}

check_cmd bsdtar
check_cmd tar
check_cmd xz
check_cmd pigz
check_cmd qemu-arm-static
check_cmd debootstrap
check_cmd kpartx

echo ""
if [ $MISSING -eq 0 ]; then
    echo "✅ All critical tools found!"
else
    echo "⚠️  $MISSING tool(s) missing. Run: ./BUILD-DEBIAN-AMD64.sh"
fi
```

Run with:

```bash
chmod +x check-deps.sh
./check-deps.sh
```

---

## 🔗 Official Package Links

- **libarchive-tools**: https://packages.debian.org/libarchive-tools
- **pixz**: https://packages.debian.org/pixz
- **qemu-user-static**: https://packages.debian.org/qemu-user-static
- **debootstrap**: https://packages.debian.org/debootstrap

---

## 💡 Pro Tips

1. **Use pixz/pxz if available** - 4-8x faster than regular xz
2. **pigz is essential** - Much faster than regular gzip
3. **bsdtar > tar** - Better archive handling
4. **Keep system updated** - `sudo apt-get update && sudo apt-get upgrade`

---

**All these dependencies are automatically handled by `BUILD-DEBIAN-AMD64.sh`!** 🎉
