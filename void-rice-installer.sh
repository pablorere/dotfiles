#!/bin/bash
# Adapted for Void Linux
# Custom dotfiles installer for pablorere

CRE=$(tput setaf 1) CYE=$(tput setaf 3) CGR=$(tput setaf 2) CBL=$(tput setaf 4) BLD=$(tput bold) CNC=$(tput sgr0)

logo() { printf "\n${BLD}${CRE}[ ${CYE}%s ${CRE}]${CNC}\n\n" "$1"; }

if [ "$(id -u)" = 0 ]; then echo "Do not run as root!"; exit 1; fi

logo "Welcome $USER to the Void Linux Setup"
printf "${CGR}This script will install dependencies and link your dotfiles using stow.${CNC}\n\n"

printf "Continue? [y/N]: "
read -r yn
case "$yn" in [Yy]*);; *) echo "Cancelled."; exit 0;; esac

logo "Installing Void Dependencies"
# Selected by user + critical Xorg dependencies + recommended silent helpers
void_deps="python3 pywal bat bspwm clipcat eza feh fzf git ghostty mpc mpd mpv neovim ncmpcpp npm picom polybar rofi sxhkd stow xclip xdotool xrandr yazi zsh zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting xorg-minimal xorg-server xorg-fonts xorg-video-drivers xorg-input-drivers xinit xsetroot dunst maim pamixer playerctl papirus-icon-theme brightnessctl bc jq"

sudo xbps-install -Su y
for pkg in $void_deps; do
    sudo xbps-install -y "$pkg" || echo "Failed to install $pkg, continuing..."
done

logo "Downloading & Linking dotfiles"
repo_url="git@github.com:pablorere/dotfiles.git"
repo_dir="$HOME/.dotfiles"

if [ ! -d "$repo_dir" ]; then
    git clone "$repo_url" "$repo_dir"
else
    echo "Dotfiles repo already exists at $repo_dir, pulling latest..."
    cd "$repo_dir" && git pull || true
fi

cd "$repo_dir" || exit 1

backup_folder="$HOME/.RiceBackup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_folder"

logo "Stowing packages"
for pkg_dir in */; do
    pkg=${pkg_dir%/} # Remove trailing slash
    
    if [[ "$pkg" == ".git" || "$pkg" == "scratch" ]]; then
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
                if [[ "$target_link" == *".dotfiles/$pkg/$rel_path"* || "$target_link" == *"../"*".dotfiles/$pkg/$rel_path"* ]]; then
                    continue
                fi
            fi
            conflicts+=("$rel_path")
        fi
    done < <(find . \( -type f -o -type l \) -print0)
    
    cd "$repo_dir" || exit 1

    if [[ ${#conflicts[@]} -eq 0 ]]; then
        stow "$pkg"
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
                    stow "$pkg"
                    echo "✅ Overwrote and linked $pkg."
                    break
                    ;;
                [Bb]* )
                    for rel_path in "${conflicts[@]}"; do
                        mv "$HOME/$rel_path" "$HOME/$rel_path.bak"
                        echo "   📦 Backed up ~/$rel_path to ~/$rel_path.bak"
                    done
                    stow "$pkg"
                    echo "✅ Backed up and linked $pkg."
                    break
                    ;;
                [Aa]* )
                    stow --adopt "$pkg"
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
    "$HOME/.pywalfox-env/bin/pip" install pywalfox
    
    echo "Symlinking pywalfox to ~/.local/bin/pywalfox..."
    mkdir -p "$HOME/.local/bin"
    ln -sf "$HOME/.pywalfox-env/bin/pywalfox" "$HOME/.local/bin/pywalfox"
    
    echo "Installing pywalfox native messaging host for Firefox..."
    "$HOME/.local/bin/pywalfox" install
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
        
        /usr/bin/wal "${NEW_ARGS[@]}"
        EXIT_STATUS=$?
    else
        # No saved color scheme, run normally and then save it
        echo "No saved color scheme found for $IMG_PATH, generating new one..."
        # Restore -i flag instead of -f
        NEW_ARGS[$IMG_INDEX]="-i"
        
        /usr/bin/wal "${NEW_ARGS[@]}"
        EXIT_STATUS=$?
        
        if [[ $EXIT_STATUS -eq 0 && -f "$HOME/.cache/wal/colors.json" ]]; then
            echo "Saving color scheme to ${IMG_PATH}.pywallcolor..."
            cp "$HOME/.cache/wal/colors.json" "${IMG_PATH}.pywallcolor"
        fi
    fi
else
    # -i was not provided, just run normally
    /usr/bin/wal "${NEW_ARGS[@]}"
    EXIT_STATUS=$?
fi

# Finally, update pywalfox if successful
if [[ $EXIT_STATUS -eq 0 ]]; then
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
echo "You can now reboot into your new environment!"

