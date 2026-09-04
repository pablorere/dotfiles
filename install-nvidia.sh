#!/bin/bash
# Install proprietary NVIDIA drivers on Void Linux
set -e

if [ "$(id -u)" != 0 ]; then
    echo "This script requires root privileges to install drivers."
    echo "Running with sudo..."
    exec sudo "$0" "$@"
fi

echo "==> Step 1: Installing void-repo-nonfree..."
xbps-install -y void-repo-nonfree
xbps-install -S

echo "==> Step 2: Installing linux-headers and proprietary nvidia packages..."
xbps-install -y linux-headers nvidia

echo "==> Step 3: Enabling modesetting for nvidia-drm..."
mkdir -p /etc/modprobe.d
echo "options nvidia-drm modeset=1" > /etc/modprobe.d/nvidia.conf

echo "==> Step 4: Blacklisting nouveau driver..."
cat << 'NOUVEAU' > /etc/modprobe.d/blacklist-nouveau.conf
blacklist nouveau
options nouveau modeset=0
NOUVEAU

echo "==> Step 5: Updating kernel initramfs (dracut)..."
xbps-reconfigure -f linux6.18 || dracut --regenerate-all --force

echo ""
echo "✅ NVIDIA proprietary drivers have been installed and configured!"
echo "➡️  Please reboot your computer (run 'sudo reboot') to start using the NVIDIA driver."
