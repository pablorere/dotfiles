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
void_deps="alacritty base-devel bat bc brightnessctl bspwm clipcat dunst eza feh fzf thunar tumbler gvfs firefox geany git imagemagick jq ghostty libwebp maim mpc mpd mpv neovim ncmpcpp npm pamixer pacman-contrib papirus-icon-theme picom playerctl polybar python3-gobject redshift rofi rust sxhkd stow xclip xdg-user-dirs xdo xdotool xorg-minimal xorg-fonts xorg-input-drivers xinit xkill xprop xrandr xsetroot xwininfo xrdb yazi zsh zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting"

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

# Change shell
if [ "$SHELL" != "/bin/zsh" ]; then
    logo "Changing default shell"
    echo "Changing shell to zsh..."
    chsh -s /bin/zsh || true
fi

logo "Installation Complete"
echo "You can now reboot into your new environment!"
