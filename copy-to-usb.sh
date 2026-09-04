#!/bin/bash
# Helper script to copy the updated dotfiles and installer to USB drive

if [ "$(id -u)" != 0 ]; then
    echo "This script needs root permissions to mount and copy to USB."
    echo "Running with sudo..."
    exec sudo "$0" "$@"
fi

USB_DIR="/mnt/usb"
mkdir -p "$USB_DIR"

# Try to find a USB drive or partition with Ventoy label
DEVICE=$(blkid -L Ventoy)

if [ -z "$DEVICE" ]; then
    # Look for removable disk partitions
    echo "Ventoy label not found. Checking connected removable devices..."
    DEVICE=$(lsblk -rpo NAME,TRAN,RM,TYPE,MOUNTPOINT | awk '$2=="usb" && $4=="part" && $5=="" {print $1; exit}')
fi

if [ -z "$DEVICE" ]; then
    echo "❌ No USB drive detected. Please insert your USB drive and re-run this script."
    exit 1
fi

echo "Found USB device: $DEVICE"
mount "$DEVICE" "$USB_DIR" || { echo "❌ Failed to mount $DEVICE to $USB_DIR"; exit 1; }

echo "Copying updated installer, scripts and dotfiles to $USB_DIR..."
# Copy installer scripts
cp -v /home/void/.dotfiles/void-rice-installer.sh "$USB_DIR/" 2>/dev/null || true
cp -v /home/void/.dotfiles/void-rice-revert.sh "$USB_DIR/" 2>/dev/null || true
cp -v /home/void/.dotfiles/wifi-connect.sh "$USB_DIR/" 2>/dev/null || true
cp -v /home/void/.dotfiles/install-nvidia.sh "$USB_DIR/" 2>/dev/null || true
cp -v /home/void/.dotfiles/copy-to-usb.sh "$USB_DIR/" 2>/dev/null || true

# Update dotfiles directory / repository on USB
TARGET_DOTFILES=""
if [ -d "$USB_DIR/.dotfiles" ]; then
    TARGET_DOTFILES="$USB_DIR/.dotfiles"
elif [ -d "$USB_DIR/dotfiles" ]; then
    TARGET_DOTFILES="$USB_DIR/dotfiles"
else
    TARGET_DOTFILES="$USB_DIR/dotfiles"
    mkdir -p "$TARGET_DOTFILES"
fi

echo "Updating $TARGET_DOTFILES..."
if command -v rsync >/dev/null 2>&1; then
    rsync -av /home/void/.dotfiles/ "$TARGET_DOTFILES/"
else
    cp -a /home/void/.dotfiles/. "$TARGET_DOTFILES/"
fi

sync
echo "Unmounting $USB_DIR..."
umount "$USB_DIR"
echo "✅ USB update complete! It is now safe to unplug the drive."
