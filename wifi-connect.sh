#!/bin/bash
# Simple WiFi connector for Void Linux TTY

if [ "$(id -u)" != 0 ]; then
    echo "This script must be run as root (use sudo) to configure network interfaces."
    exit 1
fi

echo "Detecting wireless interfaces..."
WIFI_IFACE=$(ip link | awk -F: '$0 !~ "lo|vir|^[^0-9]"{print $2;getline}' | grep -e "^ wl" | tr -d ' ' | head -n 1)

if [ -z "$WIFI_IFACE" ]; then
    echo "No wireless interface found! Please check your drivers."
    exit 1
fi

echo "Found wireless interface: $WIFI_IFACE"

echo "Bringing interface up..."
ip link set "$WIFI_IFACE" up
sleep 2

echo "Available networks:"
iw dev "$WIFI_IFACE" scan | grep "SSID" | sed 's/^[ \t]*//'

echo -n "Enter the SSID (Network Name): "
read -r SSID

echo -n "Enter the Password: "
read -rs PASSWORD
echo

echo "Configuring wpa_supplicant..."
mkdir -p /etc/wpa_supplicant
wpa_passphrase "$SSID" "$PASSWORD" > /etc/wpa_supplicant/wpa_supplicant-$WIFI_IFACE.conf

# Kill any running wpa_supplicant on this interface
killall wpa_supplicant 2>/dev/null
sleep 1

echo "Connecting to $SSID..."
wpa_supplicant -B -i "$WIFI_IFACE" -c /etc/wpa_supplicant/wpa_supplicant-$WIFI_IFACE.conf

echo "Requesting IP address..."
dhcpcd -b "$WIFI_IFACE"

echo "Attempting to reach the internet..."
sleep 5
if ping -c 1 8.8.8.8 &> /dev/null; then
    echo "Successfully connected to the internet!"
else
    echo "Connection might have failed, or is taking longer than expected."
    echo "You can check status with: ip a"
fi
