#!/bin/sh
# Revert script for void-rice-installer.sh
# This will restore your configuration from the most recent .RiceBackup

CRE=$(tput setaf 1) CYE=$(tput setaf 3) CGR=$(tput setaf 2) CBL=$(tput setaf 4) BLD=$(tput bold) CNC=$(tput sgr0)

echo "${BLD}${CYE}--- Void Rice Revert Tool ---${CNC}"

if [ ! -d "$HOME/.RiceBackup" ]; then
    echo "${CRE}No .RiceBackup directory found. Nothing to restore.${CNC}"
    exit 1
fi

# Find the most recent backup folder
LATEST_BACKUP=$(ls -td "$HOME/.RiceBackup"/*/ 2>/dev/null | head -n 1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "${CRE}No backups found inside .RiceBackup/.${CNC}"
    exit 1
fi

echo "Found latest backup at: ${CBL}$LATEST_BACKUP${CNC}"
printf "Do you want to restore this backup? This will overwrite current configs. [y/N]: "
read -r yn
case "$yn" in [Yy]*);; *) echo "Cancelled."; exit 0;; esac

echo "${CGR}Restoring configurations...${CNC}"

# Restore .config directories
for cfg in "$LATEST_BACKUP"/*; do
    name=$(basename "$cfg")
    
    # Check if it's a hidden file (like .zshrc, .icons, .gtkrc-2.0)
    if [ "$name" = ".zshrc" ] || [ "$name" = ".icons" ] || [ "$name" = ".gtkrc-2.0" ]; then
        echo "Restoring ~/$name"
        rm -rf "$HOME/$name"
        cp -R "$cfg" "$HOME/"
    else
        echo "Restoring ~/.config/$name"
        rm -rf "$HOME/.config/$name"
        cp -R "$cfg" "$HOME/.config/"
    fi
done

# If zsh was set as shell and we want to go back to bash, we can prompt:
if [ "$SHELL" = "/bin/zsh" ]; then
    printf "\n${CYE}Your shell is currently zsh. Do you want to revert to bash? [y/N]: ${CNC}"
    read -r shell_yn
    case "$shell_yn" in 
        [Yy]*) 
            chsh -s /bin/bash || true
            echo "Shell changed to bash. Please log out and back in to take effect."
            ;; 
    esac
fi

# Restore bspwm socket in case sxhkd needs it (the custom config had this)
if [ -f "$HOME/.config/bspwm/bspwmrc" ]; then
    # Ensure it's executable
    chmod +x "$HOME/.config/bspwm/bspwmrc"
fi

echo "\n${BLD}${CGR}Restore complete!${CNC}"
echo "You should restart your window manager or reboot for all changes to take effect."
echo "(You can restart bspwm right now with: Super + Shift + R)"
