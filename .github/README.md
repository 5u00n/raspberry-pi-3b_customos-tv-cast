# GitHub Actions Workflows

This directory contains automated build workflows for the Custom Raspberry Pi OS project.

## Workflows

### 1. `build-image.yml` - Full OS Image Build

**Triggers:**

- Push to `main` branch
- Pull requests to `main` branch
- Manual dispatch (workflow_dispatch)

**What it does:**

- Builds a complete custom Raspberry Pi OS image using Docker and pi-gen
- Creates a custom stage3 with all your features:
  - Auto-login GUI
  - AirPlay receiver
  - Google Cast support
  - Web dashboard
  - File sharing (Samba)
  - WiFi security tools
- Uploads build artifacts for download
- Creates GitHub releases automatically on main branch pushes

**Build time:** ~30-60 minutes

### 2. `quick-build.yml` - Fast Validation

**Triggers:**

- Manual dispatch only
- Push to specific paths (overlays/, configs/, scripts/)

**What it does:**

- Validates build script syntax
- Tests Python code compilation
- Checks configuration files
- Creates build summary
- Fast feedback for development

**Build time:** ~2-5 minutes

## How to Use

### Automatic Builds

Every time you push to the `main` branch, the full build workflow will:

1. Build your custom OS image
2. Upload it as a build artifact
3. Create a GitHub release with the image

### Manual Builds

1. Go to the **Actions** tab in your GitHub repository
2. Select **"Build Custom Raspberry Pi OS Image"**
3. Click **"Run workflow"**
4. Wait for the build to complete
5. Download the image from the **Artifacts** section

### Quick Testing

For fast validation during development:

1. Go to **Actions** → **"Quick Build Test"**
2. Click **"Run workflow"**
3. Get instant feedback on script syntax and configuration

## Build Artifacts

After each successful build, you'll find:

- `RaspberryPi3B-CustomOS.img` - The bootable OS image
- `RaspberryPi3B-CustomOS.zip` - Compressed version
- Build logs and configuration files

## Releases

Automatic releases are created on the `main` branch with:

- Version tags (v1, v2, v3, etc.)
- Release notes describing features
- Downloadable image files
- Installation instructions

## Troubleshooting

### Build Fails

- Check the **Actions** tab for detailed logs
- Ensure all Python scripts have valid syntax
- Verify configuration files are properly formatted

### No Release Created

- Releases only happen on pushes to `main` branch
- Check that the build completed successfully
- Verify GitHub token permissions

### Slow Builds

- GitHub Actions has resource limits
- Large builds may take 60+ minutes
- Consider using the quick-build workflow for testing

## Customization

To modify the build process:

1. Edit `.github/workflows/build-image.yml`
2. Adjust the pi-gen configuration
3. Add or remove packages in the stage3 setup
4. Modify the custom scripts and services

## Features Included

Your automated builds include:

- ✅ **Auto-login** - No password required
- ✅ **Custom GUI** - Auto-starts on boot
- ✅ **AirPlay Receiver** - Cast from iPhone/iPad
- ✅ **Google Cast** - Cast from Android/Chrome
- ✅ **Web Dashboard** - Remote control on port 8080
- ✅ **File Sharing** - Samba shares
- ✅ **WiFi Security Tools** - Background monitoring
- ✅ **SSH Access** - Remote administration
- ✅ **Professional Interface** - Clean, modern UI

## Next Steps

1. Push your changes to trigger the first build
2. Monitor the build progress in the Actions tab
3. Download your custom OS image when complete
4. Flash to SD card and test on Raspberry Pi 3B
5. Enjoy your automated custom OS builds! 🍓
