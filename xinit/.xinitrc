#!/bin/sh

# Load Xresources if they exist
[ -f ~/.Xresources ] && xrdb -merge ~/.Xresources

# Start sxhkd in the background for hotkeys
sxhkd &

# Start the BSPWM window manager
exec bspwm
