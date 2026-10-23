#!/usr/bin/env bash
# Step 22 — symlink ~/.config/nvim to the repo (backs up old state).
# Adapted from nvim_migration/scripts/03-link-config.sh.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

target="$HOME/.config/nvim"
src="$REPO_ROOT/config/nvim"

if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$src")" ]; then
    ok "$target already links to $src"
else
    log "Backing up existing Neovim config/data (if any)"
    for d in "$target" "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"; do
        if [ -e "$d" ] || [ -L "$d" ]; then
            mv "$d" "$d.bak-$(date +%Y%m%d-%H%M%S)"; ok "backed up $d"
        fi
    done
    mkdir -p "$HOME/.config"
    ln -s "$src" "$target"; ok "linked $target -> $src"
fi
