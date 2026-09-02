#!/bin/sh

# Set environment variables and PATH
export PATH="$HOME/.local/bin:$HOME/.config/bspwm/bin:$PATH"
export XDG_CURRENT_DESKTOP='bspwm'
export _JAVA_AWT_WM_NONREPARENTING=1

# Load Xresources if they exist
[ -f ~/.Xresources ] && xrdb -merge ~/.Xresources

# Start sxhkd with explicit dotfiles configuration
sxhkd -c "$HOME/.config/bspwm/config/sxhkdrc" &

# Start the BSPWM window manager with dbus session if available and configured
if command -v dbus-launch >/dev/null 2>&1 && command -v dbus-daemon >/dev/null 2>&1 && [ -f /var/lib/dbus/machine-id -o -f /etc/machine-id ]; then
    exec dbus-launch --sh-syntax --exit-with-session bspwm
else
    exec bspwm
fi
