#!/bin/bash

# =========================================================================
#  Stow Link & Install Script
#  Automatically installs missing packages and manages stow symlinks
#  with interactive conflict resolution.
# =========================================================================

DOTFILES_DIR="$HOME/.dotfiles"

# Ensure we are in the dotfiles directory
cd "$DOTFILES_DIR" || {
    echo "❌ Error: Could not cd into $DOTFILES_DIR"
    exit 1
}

echo "🚀 Starting dotfiles installation and linking..."

# Iterate over all directories in .dotfiles
for pkg_dir in */; do
    pkg=${pkg_dir%/} # Remove trailing slash

    # Skip .git and any other non-stow directories you might have
    if [[ "$pkg" == ".git" || "$pkg" == "scratch" ]]; then
        continue
    fi

    echo "----------------------------------------"
    echo "📦 Package: $pkg"

    # ==========================================
    # 1. Package Installation Check
    # ==========================================
    # If the command doesn't exist, prompt the user to install it.
    if ! command -v "$pkg" >/dev/null 2>&1; then
        echo -ne "⚠️  Command '$pkg' not found in PATH. Install via xbps? [y/N]: "
        read install_choice </dev/tty
        if [[ "$install_choice" =~ ^[Yy]$ ]]; then
            sudo xbps-install -Sy "$pkg"
        fi
    fi

    # ==========================================
    # 2. Conflict Detection & Symlinking
    # ==========================================
    echo "🔗 Linking $pkg..."
    
    cd "$DOTFILES_DIR/$pkg" || continue
    
    # Find all actual files/symlinks (ignoring directories) in the stow package
    conflicts=()
    while IFS= read -r -d '' file; do
        # Remove leading './'
        rel_path="${file#./}"
        target_path="$HOME/$rel_path"
        
        # Check if the target exists on the system
        if [[ -e "$target_path" || -L "$target_path" ]]; then
            
            # If it's a symlink, check if it already points to our dotfiles repo
            if [[ -L "$target_path" ]]; then
                target_link=$(readlink "$target_path")
                if [[ "$target_link" == *".dotfiles/$pkg/$rel_path"* || "$target_link" == *"../"*".dotfiles/$pkg/$rel_path"* ]]; then
                    # It's already correctly linked by stow, skip it
                    continue
                fi
            fi
            
            # If it exists and isn't pointing to our dotfile, it's a conflict
            conflicts+=("$rel_path")
        fi
    done < <(find . \( -type f -o -type l \) -print0)
    
    # Go back to dotfiles root to run stow
    cd "$DOTFILES_DIR" || exit 1

    if [[ ${#conflicts[@]} -eq 0 ]]; then
        # No conflicts, safe to stow
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
                    echo "⚠️  (Check 'git status' to review changes pulled into the repo)"
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

echo "----------------------------------------"
echo "🎉 Dotfiles setup complete!"
