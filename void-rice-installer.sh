#!/bin/bash
# Adapted for Void Linux
# Custom dotfiles installer for pablorere

set -e

CRE=$(tput setaf 1) CYE=$(tput setaf 3) CGR=$(tput setaf 2) CBL=$(tput setaf 4) BLD=$(tput bold) CNC=$(tput sgr0)

logo() { printf "\n${BLD}${CRE}[ ${CYE}%s ${CRE}]${CNC}\n\n" "$1"; }

if [ "$(id -u)" = 0 ]; then
    echo "Do not run this script as root! It will ask for sudo when needed."
    exit 1
fi

logo "Welcome $USER to the Void Linux Setup"
printf "${CGR}This script will install dependencies, configure services, and link your dotfiles using stow.${CNC}\n\n"

printf "Continue? [y/N]: "
read -r yn
case "$yn" in [Yy]*);; *) echo "Cancelled."; exit 0;; esac

# Keep sudo credentials alive in background
sudo -v
( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null ) &
SUDO_PID=$!
trap 'kill $SUDO_PID 2>/dev/null || true' EXIT

logo "Installing Void Dependencies"
# Full list of core window manager, desktop daemons, audio stack, helpers, and utilities
void_deps="python3 python3-pip pywal bat bspwm sxhkd stow eza feh fzf git curl tar ghostty alacritty kitty mpc mpd mpv neovim ncmpcpp nodejs picom polybar eww rofi jgmenu xclip xdotool xdo xrandr yazi zsh zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting xorg-minimal xorg-server xorg-fonts xorg-video-drivers xorg-input-drivers xf86-input-synaptics xinit xsetroot xset xprop xwininfo xrdb xkill dbus dbus-x11 elogind polkit xfce-polkit pipewire wireplumber pavucontrol pamixer playerctl dunst libnotify maim papirus-icon-theme brightnessctl bc jq xsettingsd webp-pixbuf-loader"

echo "Syncing repositories..."
sudo xbps-install -Suy || true

echo "Installing packages..."
if ! sudo xbps-install -y $void_deps; then
    echo "Bulk install finished with some errors, attempting individual package installs..."
    for pkg in $void_deps; do
        sudo xbps-install -y "$pkg" || echo "Warning: Failed to install $pkg, continuing..."
    done
fi

logo "Adding User to System Groups"
for grp in video audio input storage wheel; do
    sudo usermod -aG "$grp" "$USER" 2>/dev/null || true
done

logo "Installing Clipcat"
if ! command -v clipcatd >/dev/null 2>&1; then
    echo "Downloading and installing clipcat binary to ~/.local/bin..."
    mkdir -p "$HOME/.local/bin"
    curl -sL "https://github.com/xrelkd/clipcat/releases/download/v0.26.0/clipcat-0.26.0-x86_64-unknown-linux-musl.tar.gz" | tar -xz -C "$HOME/.local/bin" --strip-components=1 || echo "Warning: Failed to download clipcat"
    chmod +x "$HOME"/.local/bin/clipcat* 2>/dev/null || true
fi

logo "Configuring Void Linux Services & Machine ID"
echo "Generating D-Bus machine ID..."
sudo dbus-uuidgen --ensure 2>/dev/null || true
if [ -f /var/lib/dbus/machine-id ]; then
    sudo ln -sf /var/lib/dbus/machine-id /etc/machine-id 2>/dev/null || true
elif [ -f /etc/machine-id ]; then
    sudo ln -sf /etc/machine-id /var/lib/dbus/machine-id 2>/dev/null || true
fi

echo "Enabling dbus service in runit..."
if [ -d /etc/sv/dbus ] && [ ! -L /var/service/dbus ]; then
    sudo ln -s /etc/sv/dbus /var/service/ 2>/dev/null || true
fi

echo "Enabling elogind service in runit..."
if [ -d /etc/sv/elogind ] && [ ! -L /var/service/elogind ]; then
    sudo ln -s /etc/sv/elogind /var/service/ 2>/dev/null || true
fi

logo "Setting up User Directories"
mkdir -p "$HOME/Music" "$HOME/Downloads" "$HOME/Pictures" "$HOME/.local/bin"

logo "Downloading & Linking dotfiles"
repo_url="https://github.com/pablorere/dotfiles.git"
repo_dir="$HOME/.dotfiles"

if [ ! -d "$repo_dir" ]; then
    git clone "$repo_url" "$repo_dir"
else
    echo "Dotfiles repo already exists at $repo_dir, pulling latest..."
    cd "$repo_dir" && git pull || true
fi

cd "$repo_dir"

backup_folder="$HOME/.RiceBackup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_folder"

logo "Stowing packages"
for pkg_dir in */; do
    pkg=${pkg_dir%/} # Remove trailing slash
    
    if [[ "$pkg" == .* || "$pkg" == "scratch" || "$pkg" == "__pycache__" ]]; then
        continue
    fi
    
    echo "🔗 Linking $pkg..."
    
    cd "$repo_dir/$pkg" || continue
    
    # Find all actual files/symlinks (ignoring directories) in the stow package
    conflicts=()
    while IFS= read -r -d '' file; do
        rel_path="${file#./}"
        target_path="$HOME/$rel_path"
        
        if [[ -e "$target_path" || -L "$target_path" ]]; then
            if [[ -L "$target_path" ]]; then
                target_link=$(readlink "$target_path")
                if [[ "$target_link" == *".dotfiles/$pkg/$rel_path"* || "$target_link" == *"../"*".dotfiles/$pkg/$rel_path"* || "$target_link" == *"$repo_dir/$pkg"* ]]; then
                    continue
                fi
            fi
            conflicts+=("$rel_path")
        fi
    done < <(find . \( -type f -o -type l \) -print0)
    
    cd "$repo_dir" || exit 1

    if [[ ${#conflicts[@]} -eq 0 ]]; then
        stow --target="$HOME" -R "$pkg"
        echo "✅ Successfully linked $pkg."
    else
        echo "❌ Conflicts detected for $pkg:"
        for rel_path in "${conflicts[@]}"; do
            echo "   - ~/$rel_path"
        done

        while true; do
            echo -ne "Action for $pkg? [O]verwrite / [B]ackup / [A]dopt / [S]kip: "
            read action </dev/tty
            case "$action" in
                [Oo]* )
                    for rel_path in "${conflicts[@]}"; do
                        rm -rf "$HOME/$rel_path"
                        echo "   🗑️ Removed ~/$rel_path"
                    done
                    stow --target="$HOME" "$pkg"
                    echo "✅ Overwrote and linked $pkg."
                    break
                    ;;
                [Bb]* )
                    for rel_path in "${conflicts[@]}"; do
                        mv "$HOME/$rel_path" "$HOME/$rel_path.bak"
                        echo "   📦 Backed up ~/$rel_path to ~/$rel_path.bak"
                    done
                    stow --target="$HOME" "$pkg"
                    echo "✅ Backed up and linked $pkg."
                    break
                    ;;
                [Aa]* )
                    stow --target="$HOME" --adopt "$pkg"
                    echo "✅ Adopted system files into dotfiles repo for $pkg."
                    break
                    ;;
                [Ss]* )
                    echo "⏭️  Skipped linking $pkg."
                    break
                    ;;
                * )
                    echo "Invalid option. Please choose O, B, A, or S."
                    ;;
            esac
        done
    fi
done

logo "Setting up Pywalfox & auto-update wrapper"

if [ ! -d "$HOME/.pywalfox-env" ]; then
    echo "Creating virtual environment for pywalfox..."
    python3 -m venv "$HOME/.pywalfox-env"
    "$HOME/.pywalfox-env/bin/pip" install --upgrade pip pywalfox
    
    echo "Symlinking pywalfox to ~/.local/bin/pywalfox..."
    mkdir -p "$HOME/.local/bin"
    ln -sf "$HOME/.pywalfox-env/bin/pywalfox" "$HOME/.local/bin/pywalfox"
    
    echo "Installing pywalfox native messaging host for Firefox..."
    mkdir -p "$HOME/.mozilla/native-messaging-hosts"
    "$HOME/.local/bin/pywalfox" install || echo "Pywalfox install warning (safe to ignore if Firefox is not yet run)."
else
    echo "Pywalfox environment already exists."
fi

echo "Setting up pywal wrapper to auto-update Firefox and cache colors..."
cat << 'EOF' > "$HOME/.local/bin/wal"
#!/bin/bash
# Wrapper to save pywal colors to filename.pywallcolor and reuse them if available,
# and to update Pywalfox every time wal is called.

declare -a NEW_ARGS
IMG_PATH=""
IMG_INDEX=-1
i=0

WAL_BIN="/usr/bin/wal"
if [ ! -x "$WAL_BIN" ]; then
    WAL_BIN="$(which wal 2>/dev/null || echo "wal")"
fi

# Parse arguments to find -i and its value
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i)
            NEW_ARGS+=("-f") # Temporarily set to -f, might change back
            IMG_INDEX=$i
            shift
            if [[ $# -gt 0 ]]; then
                IMG_PATH="$1"
                # Keep a placeholder for the argument value
                NEW_ARGS+=("$IMG_PATH")
                ((i+=2))
                shift
            else
                ((i++))
            fi
            ;;
        *)
            NEW_ARGS+=("$1")
            ((i++))
            shift
            ;;
    esac
done

EXIT_STATUS=0

if [[ -n "$IMG_PATH" ]]; then
    # -i was provided
    if [[ -f "${IMG_PATH}.pywallcolor" ]]; then
        # Use the saved color scheme instead of generating a new one
        echo "Found saved color scheme for $IMG_PATH, using it instead of recalculating..."
        # Replace the placeholder with the .pywallcolor file path
        NEW_ARGS[$((IMG_INDEX+1))]="${IMG_PATH}.pywallcolor"
        
        "$WAL_BIN" "${NEW_ARGS[@]}"
        EXIT_STATUS=$?
    else
        # No saved color scheme, run normally and then save it
        echo "No saved color scheme found for $IMG_PATH, generating new one..."
        # Restore -i flag instead of -f
        NEW_ARGS[$IMG_INDEX]="-i"
        
        "$WAL_BIN" "${NEW_ARGS[@]}"
        EXIT_STATUS=$?
        
        if [[ $EXIT_STATUS -eq 0 && -f "$HOME/.cache/wal/colors.json" ]]; then
            echo "Saving color scheme to ${IMG_PATH}.pywallcolor..."
            cp "$HOME/.cache/wal/colors.json" "${IMG_PATH}.pywallcolor"
        fi
    fi
else
    # -i was not provided, just run normally
    "$WAL_BIN" "${NEW_ARGS[@]}"
    EXIT_STATUS=$?
fi

# Finally, update pywalfox if available
if [[ $EXIT_STATUS -eq 0 ]] && command -v pywalfox >/dev/null 2>&1; then
    pywalfox update
fi

exit $EXIT_STATUS
EOF
chmod +x "$HOME/.local/bin/wal"

# Change shell
if [ "$SHELL" != "/bin/zsh" ]; then
    logo "Changing default shell"
    echo "Changing shell to zsh..."
    chsh -s /bin/zsh || true
fi

logo "Installation Complete"
echo "Setup is fully configured! You can now start the environment with startx."
