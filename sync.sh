#!/bin/bash

# Dotfiles sync script
# Usage: ./sync.sh save     - Save configs and package lists to this repo
#        ./sync.sh restore  - Restore configs from this repo to ~/.config
#        ./sync.sh install  - Install packages from saved lists (Arch Linux)

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"
PACKAGES_DIR="$DOTFILES_DIR/packages"

# Configs to track (relative to ~/.config)
CONFIGS=(
    # Neovim (excluding node_modules)
    "nvim/init.lua"
    "nvim/lazy-lock.json"
    # Hyprland ecosystem
    "hypr"
    "hyprpaper"
    "waybar"
    "wofi"
    # Terminal
    "kitty"
    # Git
    "git"
)

# Exclusions for rsync (patterns to skip)
EXCLUDES=(
    "node_modules"
    "__pycache__"
    ".cache"
)

build_excludes() {
    local excludes=""
    for pattern in "${EXCLUDES[@]}"; do
        excludes="$excludes --exclude=$pattern"
    done
    echo "$excludes"
}

save_packages() {
    echo "Saving package lists..."
    mkdir -p "$PACKAGES_DIR"

    if command -v pacman &> /dev/null; then
        pacman -Qqen > "$PACKAGES_DIR/pacman.txt"
        echo "  Saved $(wc -l < "$PACKAGES_DIR/pacman.txt") repo packages to packages/pacman.txt"

        pacman -Qqem > "$PACKAGES_DIR/aur.txt"
        echo "  Saved $(wc -l < "$PACKAGES_DIR/aur.txt") AUR packages to packages/aur.txt"
    else
        echo "  Warning: pacman not found, skipping package list export"
    fi
}

save() {
    echo "Saving configs to dotfiles repo..."
    local excludes=$(build_excludes)

    for config in "${CONFIGS[@]}"; do
        src="$CONFIG_DIR/$config"
        dest="$DOTFILES_DIR/config/$config"

        if [[ -e "$src" ]]; then
            mkdir -p "$(dirname "$dest")"
            if [[ -d "$src" ]]; then
                eval rsync -av --delete $excludes "$src/" "$dest/"
            else
                cp -v "$src" "$dest"
            fi
        else
            echo "Warning: $src does not exist, skipping"
        fi
    done

    echo ""
    save_packages
    echo ""
    echo "Done! Don't forget to commit your changes."
}

restore() {
    echo "Restoring configs from dotfiles repo..."

    for config in "${CONFIGS[@]}"; do
        src="$DOTFILES_DIR/config/$config"
        dest="$CONFIG_DIR/$config"

        if [[ -e "$src" ]]; then
            mkdir -p "$(dirname "$dest")"
            if [[ -d "$src" ]]; then
                rsync -av "$src/" "$dest/"
            else
                cp -v "$src" "$dest"
            fi
        else
            echo "Warning: $src does not exist in repo, skipping"
        fi
    done
    echo ""
    echo "Done!"
}

install_packages() {
    echo "Installing packages from saved lists..."

    if ! command -v pacman &> /dev/null; then
        echo "Error: pacman not found. This command is for Arch Linux."
        exit 1
    fi

    if [[ -f "$PACKAGES_DIR/pacman.txt" ]]; then
        echo ""
        echo "Installing repo packages..."
        sudo pacman -S --needed - < "$PACKAGES_DIR/pacman.txt"
    else
        echo "Warning: packages/pacman.txt not found"
    fi

    if [[ -f "$PACKAGES_DIR/aur.txt" ]]; then
        if command -v yay &> /dev/null; then
            echo ""
            echo "Installing AUR packages with yay..."
            yay -S --needed - < "$PACKAGES_DIR/aur.txt"
        else
            echo ""
            echo "Warning: yay not found. Install yay first, then run:"
            echo "  yay -S --needed - < packages/aur.txt"
        fi
    else
        echo "Warning: packages/aur.txt not found"
    fi

    echo ""
    echo "Done!"
}

case "$1" in
    save)
        save
        ;;
    restore)
        restore
        ;;
    install)
        install_packages
        ;;
    *)
        echo "Usage: $0 {save|restore|install}"
        echo "  save    - Save configs and package lists to this repo"
        echo "  restore - Restore configs from this repo to ~/.config"
        echo "  install - Install packages from saved lists (Arch Linux)"
        exit 1
        ;;
esac
