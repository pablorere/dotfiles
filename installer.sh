#!/bin/sh
# Installer for Void Linux to setup bspwm, polybar, rofi and copy user scripts.

set -e

echo "==========================================="
echo "   Void Linux BSPWM Environment Installer  "
echo "==========================================="

if [ "$(id -u)" = 0 ]; then
    echo "Please do not run this script as root. Run as your normal user."
    exit 1
fi

echo "Updating system and installing dependencies..."
# Update the system
sudo xbps-install -Su y

# Base Xorg and BSPWM components
PACKAGES="xorg-minimal xorg-fonts xorg-input-drivers xinit bspwm sxhkd"

# Status bar and App launcher
PACKAGES="$PACKAGES polybar rofi"

# Additional useful utilities (terminals, fonts, etc.)
PACKAGES="$PACKAGES alacritty feh picom dunst lxappearance fonts-roboto-ttf dejavu-fonts-ttf"

# Install everything
sudo xbps-install -Sy $PACKAGES

echo "==========================================="
echo "Setting up directories and copying configs..."
echo "==========================================="

# Ensure standard config directories exist
mkdir -p "$HOME/.config/bspwm"
mkdir -p "$HOME/.config/sxhkd"
mkdir -p "$HOME/.config/polybar"
mkdir -p "$HOME/.config/rofi"
mkdir -p "$HOME/.local/bin"

# If the user has a dotfiles folder in the current directory, copy them
if [ -d "./dotfiles" ]; then
    echo "Found dotfiles directory. Copying configurations..."
    cp -r ./dotfiles/bspwm/* "$HOME/.config/bspwm/" 2>/dev/null || true
    cp -r ./dotfiles/sxhkd/* "$HOME/.config/sxhkd/" 2>/dev/null || true
    cp -r ./dotfiles/polybar/* "$HOME/.config/polybar/" 2>/dev/null || true
    cp -r ./dotfiles/rofi/* "$HOME/.config/rofi/" 2>/dev/null || true
else
    echo "No local 'dotfiles' directory found. Creating default bspwm/sxhkd configs..."
    # Copy default examples if available
    if [ -f /usr/share/doc/bspwm/examples/bspwmrc ]; then
        install -Dm755 /usr/share/doc/bspwm/examples/bspwmrc "$HOME/.config/bspwm/bspwmrc"
    fi
    if [ -f /usr/share/doc/bspwm/examples/sxhkdrc ]; then
        install -Dm644 /usr/share/doc/bspwm/examples/sxhkdrc "$HOME/.config/sxhkd/sxhkdrc"
    fi
fi

echo "==========================================="
echo "Installing custom scripts..."
echo "==========================================="

# Assuming custom scripts are stored in a folder called 'scripts' in the current dir
if [ -d "./scripts" ]; then
    echo "Found custom scripts directory. Installing to ~/.local/bin..."
    cp -r ./scripts/* "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/"*
else
    echo "No 'scripts' directory found here to copy."
fi

# Ensure ~/.local/bin is in PATH for the user
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "Added ~/.local/bin to PATH in ~/.bashrc"
fi

# Create .xinitrc to launch bspwm
echo "==========================================="
echo "Configuring X init..."
echo "==========================================="
cat > "$HOME/.xinitrc" << 'EOF'
#!/bin/sh
# Load resources
xrdb -merge ~/.Xresources 2>/dev/null

# Start sxhkd
sxhkd &

# Start polybar (assuming default polybar config or script)
# polybar mybar &

exec bspwm
EOF

chmod +x "$HOME/.xinitrc"

echo "==========================================="
echo "Installation complete!"
echo "To start your new environment, log in to a tty and run: startx"
echo "Make sure your scripts and dotfiles are placed in 'scripts/' and 'dotfiles/' next to this installer to be copied automatically."
echo "==========================================="
