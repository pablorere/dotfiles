#!/bin/bash
# Install Ly Display Manager on Void Linux (with Void Linux ASCII logo)
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(id -u)" != 0 ]; then
    echo "This script requires root privileges."
    echo "Running with sudo..."
    exec sudo "$0" "$@"
fi

echo "==> Installing Ly Display Manager dependencies..."
xbps-install -y pam-devel libxcb-devel

echo "==> Installing Ly binary and configuration..."
install -d /usr/bin
install -m 755 "$DIR/ly/bin/ly" /usr/bin/ly

mkdir -p /etc/ly/lang
install -m 644 "$DIR/ly/config.ini" /etc/ly/config.ini
install -m 755 "$DIR/ly/xsetup.sh" /etc/ly/xsetup.sh
install -m 755 "$DIR/ly/wsetup.sh" /etc/ly/wsetup.sh
install -m 644 "$DIR/ly/lang/"* /etc/ly/lang/

install -d /etc/pam.d
install -m 644 "$DIR/ly/pam.d/ly" /etc/pam.d/ly

echo "==> Configuring runit service for Ly..."
mkdir -p /etc/sv/ly
install -m 755 "$DIR/ly/service/run" /etc/sv/ly/run
install -m 755 "$DIR/ly/service/finish" /etc/sv/ly/finish

# Disable conflicting agetty-tty2 and enable ly
rm -f /var/service/agetty-tty2
ln -sf /etc/sv/ly /var/service/ly

echo "✅ Ly Display Manager installed and enabled successfully on tty2!"
