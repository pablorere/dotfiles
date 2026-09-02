#!/bin/sh
# Adapted for Void Linux
# Original Author: gh0stzk
# Adapted by: Antigravity

CRE=$(tput setaf 1) CYE=$(tput setaf 3) CGR=$(tput setaf 2) CBL=$(tput setaf 4) BLD=$(tput bold) CNC=$(tput sgr0)

logo() { printf "\n${BLD}${CRE}[ ${CYE}%s ${CRE}]${CNC}\n\n" "$1"; }

if [ "$(id -u)" = 0 ]; then echo "Do not run as root!"; exit 1; fi
if [ "$PWD" != "$HOME" ]; then echo "Run from HOME directory!"; exit 1; fi

logo "Welcome $USER to the Void Linux Adapter"
printf "${CGR}This script will safely install gh0stzk's dotfiles on your Void Linux system.${CNC}\n"
printf "${CRE}Note: Arch-specific repos and AUR packages have been removed. We will use XBPS.${CNC}\n\n"

printf "Continue? [y/N]: "
read -r yn
case "$yn" in [Yy]*);; *) echo "Cancelled."; exit 0;; esac

logo "Installing Void Dependencies"
# Translated Arch packages to Void packages (Fonts & Kitty removed, Ghostty kept)
void_deps="alacritty base-devel bat bc brightnessctl bspwm clipcat dunst eza feh fzf thunar tumbler gvfs firefox geany git imagemagick jq ghostty libwebp maim mpc mpd mpv neovim ncmpcpp npm pamixer pacman-contrib papirus-icon-theme picom playerctl polybar python3-gobject redshift rofi rust sxhkd xclip xdg-user-dirs xdo xdotool xorg-server xkill xprop xrandr xsetroot xwininfo xrdb yazi zsh zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting"

sudo xbps-install -Sy
for pkg in $void_deps; do
    sudo xbps-install -y "$pkg" || echo "Failed to install $pkg, continuing..."
done

logo "Downloading dotfiles"
repo_url="https://github.com/gh0stzk/dotfiles"
repo_dir="$HOME/.local/share/gh0stzk"
[ -d "$repo_dir" ] && mv -v "$repo_dir" "${repo_dir}_backup_$(date +%s)"
git clone --depth=1 "$repo_url" "$repo_dir"

logo "Backup and Install Configuration"
backup_folder="$HOME/.RiceBackup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_folder"

# Backup existing configs
for cfg in bspwm alacritty cava clipcat ghostty picom rofi eww sxhkd dunst jgmenu polybar geany gtk-3.0 ncmpcpp yazi zsh mpd mpv st zathura; do
    [ -d "$HOME/.config/$cfg" ] && mv "$HOME/.config/$cfg" "$backup_folder/"
done

for dir in "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share"; do mkdir -p "$dir"; done

# Copy config
for cfg in alacritty bspwm cava clipcat dunst geany ghostty gtk-3.0 jgmenu mpd mpv ncmpcpp yazi zsh st zathura; do
    cp -R "$HOME/.local/share/gh0stzk/config/$cfg" "$HOME/.config/" 2>/dev/null || true
done
cp -R "$HOME/.local/share/gh0stzk/misc/applications" "$HOME/.local/share/"
cp -R "$HOME/.local/share/gh0stzk/misc/asciiart" "$HOME/.local/share/"
cp -R "$HOME/.local/share/gh0stzk/misc/bin" "$HOME/.local/"
cp -R "$HOME/.local/share/gh0stzk/home/.icons" "$HOME/"
cp -R "$HOME/.local/share/gh0stzk/home/.zshrc" "$HOME/"
cp -R "$HOME/.local/share/gh0stzk/home/.gtkrc-2.0" "$HOME/"

# Change shell
if [ "$SHELL" != "/bin/zsh" ]; then
    echo "Changing shell to zsh..."
    chsh -s /bin/zsh || true
fi

logo "Installation Complete"
echo "You can now reboot into your new environment!"
