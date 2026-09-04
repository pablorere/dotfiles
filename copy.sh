#!/usr/bin/env bash
set -e

# ==============================================================================
# copy.sh - Copy dotfiles repository to Ventoy USB partition alongside ISO files
# ==============================================================================

# Automatically elevate to sudo if not root
if [ "$(id -u)" -ne 0 ]; then
    echo "[*] Requesting root privileges to mount USB..."
    exec sudo "$0" "$@"
fi

SRC_REPO="/home/void/.dotfiles"

if [ ! -d "$SRC_REPO" ]; then
    echo "[!] Error: Source repository $SRC_REPO does not exist."
    exit 1
fi

echo "[*] Locating Ventoy USB partition..."

# Detect Ventoy partition by filesystem label
VENTOY_DEV=$(lsblk -rno NAME,LABEL | awk '$2 == "Ventoy" {print "/dev/"$1; exit}')

# Fallback: check by blkid
if [ -z "$VENTOY_DEV" ]; then
    VENTOY_DEV=$(blkid -L Ventoy 2>/dev/null || true)
fi

# Fallback: check /dev/sdb1 specifically if labeled Ventoy
if [ -z "$VENTOY_DEV" ] && [ -b /dev/sdb1 ]; then
    VENTOY_DEV="/dev/sdb1"
fi

if [ -z "$VENTOY_DEV" ]; then
    echo "[!] Error: Could not find a partition with label 'Ventoy'."
    echo "    Please make sure your Ventoy USB drive is plugged in."
    lsblk
    exit 1
fi

echo "[+] Found Ventoy partition at: $VENTOY_DEV"

# Check if already mounted
MOUNT_POINT=$(findmnt -n -o TARGET "$VENTOY_DEV" 2>/dev/null || true)
ALREADY_MOUNTED=1

if [ -z "$MOUNT_POINT" ]; then
    ALREADY_MOUNTED=0
    MOUNT_POINT="/mnt/ventoy"
    mkdir -p "$MOUNT_POINT"
    echo "[*] Mounting $VENTOY_DEV to $MOUNT_POINT..."
    mount -o rw,uid=1000,gid=1000,umask=000 "$VENTOY_DEV" "$MOUNT_POINT"
else
    echo "[+] Partition is already mounted at: $MOUNT_POINT"
fi

# Find where the ISO files are located on the Ventoy partition
echo "[*] Searching for ISO files on Ventoy partition..."
FIRST_ISO=$(find "$MOUNT_POINT" -maxdepth 3 -type f -iname "*.iso" 2>/dev/null | head -n 1 || true)

if [ -n "$FIRST_ISO" ]; then
    ISO_DIR=$(dirname "$FIRST_ISO")
    echo "[+] Found ISO files in: $ISO_DIR"
    DEST_DIR="$ISO_DIR/dotfiles"
else
    echo "[*] No ISO files found in subdirectories. Placing dotfiles in the root of Ventoy..."
    DEST_DIR="$MOUNT_POINT/dotfiles"
fi

echo "[*] Destination repository: $DEST_DIR"

# Clean previous copy if it exists
if [ -d "$DEST_DIR" ]; then
    echo "[*] Removing previous copy at $DEST_DIR..."
    rm -rf "$DEST_DIR"
fi

# Clone repository preserving git history
echo "[*] Cloning dotfiles repository into $DEST_DIR..."
ORIGIN_URL=$(git -C "$SRC_REPO" remote get-url origin 2>/dev/null || echo "https://github.com/pablorere/dotfiles")
git clone -c core.symlinks=false "$SRC_REPO" "$DEST_DIR"

# Ensure origin remote is preserved
git -C "$DEST_DIR" remote set-url origin "$ORIGIN_URL"

# Copy any untracked or ignored changes just in case
rsync -rtv --exclude='.git' "$SRC_REPO/" "$DEST_DIR/" 2>/dev/null || true

# Fix permissions so regular user can read and modify
chown -R 1000:1000 "$DEST_DIR" 2>/dev/null || true

echo "[*] Flushing buffers to USB drive (syncing, please wait)..."
sync

echo ""
echo "========================================================="
echo "[✓] Successfully copied dotfiles repository to Ventoy USB!"
echo "    Location: $DEST_DIR"
echo "    Remote URL: $(git -C "$DEST_DIR" remote get-url origin 2>/dev/null)"
echo "    Branch: $(git -C "$DEST_DIR" branch --show-current 2>/dev/null)"
echo "========================================================="
echo ""
echo "Files on USB:"
ls -la "$DEST_DIR" | head -n 20

if [ "$ALREADY_MOUNTED" -eq 0 ]; then
    echo ""
    echo "[*] The USB is currently mounted at $MOUNT_POINT."
    echo "    When ready to safely unplug, you can unmount it with:"
    echo "    sudo umount $MOUNT_POINT"
fi
