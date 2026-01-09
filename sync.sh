#!/bin/bash

# Dotfiles sync script
# Usage: ./sync.sh save    - Copy configs from ~/.config to this repo
#        ./sync.sh restore - Copy configs from this repo to ~/.config

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"

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

case "$1" in
    save)
        save
        ;;
    restore)
        restore
        ;;
    *)
        echo "Usage: $0 {save|restore}"
        echo "  save    - Copy configs from ~/.config to this repo"
        echo "  restore - Copy configs from this repo to ~/.config"
        exit 1
        ;;
esac
