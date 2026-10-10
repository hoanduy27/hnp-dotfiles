#!/usr/bin/env bash
# Step 20 — install latest stable Neovim into ~/.local (no sudo).
# Adapted from nvim_migration/scripts/00-upgrade-neovim.sh. VimTeX needs >= 0.12.4.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
BIN_DIR="$HOME/.local/bin"

[ "$(uname -m)" = x86_64 ] || die "this installer assumes x86_64 (got $(uname -m))"
opt_dir="$HOME/.local/opt"
tag="$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest | grep -oE '"tag_name": *"[^"]+"' | cut -d'"' -f4)"
[ -n "$tag" ] || die "could not resolve latest Neovim release"

current="$(nvim --version 2>/dev/null | head -1 | grep -oE 'v[0-9.]+' || true)"
if [ "$current" = "$tag" ]; then ok "Neovim $tag already active ($(command -v nvim))"; exit 0; fi

confirm "Install Neovim $tag (current: ${current:-none}) into $opt_dir?" || exit 0
dest="$opt_dir/nvim-$tag"
mkdir -p "$opt_dir" "$BIN_DIR"
if [ ! -x "$dest/bin/nvim" ]; then
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
    curl -fsSL "https://github.com/neovim/neovim/releases/download/$tag/nvim-linux-x86_64.tar.gz" | tar -xz -C "$tmp"
    mv "$tmp/nvim-linux-x86_64" "$dest"
fi
ln -sfn "$dest/bin/nvim" "$BIN_DIR/nvim"
hash -r
ok "$(nvim --version | head -1) -> $BIN_DIR/nvim"
[ "$(command -v nvim)" = "$BIN_DIR/nvim" ] || warn "another nvim is earlier on PATH: $(command -v nvim) (ensure ~/.local/bin is first)"
