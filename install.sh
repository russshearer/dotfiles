#!/bin/bash
# dotfiles/install.sh — Bootstrap script for homelab VMs
# Usage: ./install.sh [--force]
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORCE=false

[[ "${1:-}" == "--force" ]] && FORCE=true

link_file() {
    local src="$1"
    local dst="$2"

    if [ -e "$dst" ] || [ -L "$dst" ]; then
        if [ "$FORCE" = true ]; then
            echo "  overwriting $dst"
            rm -rf "$dst"
        else
            echo "  skipping $dst (exists, use --force to overwrite)"
            return
        fi
    fi

    ln -sf "$src" "$dst"
    echo "  linked $src → $dst"
}

echo "=== Installing dotfiles from $DOTFILES_DIR ==="

# ----------------------------------------------------------
# Oh My Posh (install if not present)
# ----------------------------------------------------------
if command -v oh-my-posh &>/dev/null; then
    echo "  oh-my-posh already installed ($(oh-my-posh --version))"
else
    echo "  installing oh-my-posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s
    echo "  oh-my-posh installed"
fi

# ----------------------------------------------------------
# Symlink dotfiles
# ----------------------------------------------------------

# Shell
link_file "$DOTFILES_DIR/.bashrc"        "$HOME/.bashrc"
link_file "$DOTFILES_DIR/.bash_aliases"  "$HOME/.bash_aliases"

# Tools
link_file "$DOTFILES_DIR/.vimrc"     "$HOME/.vimrc"
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

# Update system script
mkdir -p "$HOME/.local/bin"
link_file "$DOTFILES_DIR/update-system.sh" "$HOME/update-system.sh"


echo ""
echo "Done! Restart your shell or run: source ~/.bashrc"
