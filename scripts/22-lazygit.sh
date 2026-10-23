#!/usr/bin/env bash
# Step 22 — lazygit (<leader>gg inside Neovim), pinned release verified by sha256. Not in apt.
# To bump: change LAZYGIT_VERSION, download the tarball once, check its hash against the release's
# checksums.txt, then paste it into LAZYGIT_SHA256.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
BIN_DIR="$HOME/.local/bin"; mkdir -p "$BIN_DIR"

LAZYGIT_VERSION=0.65.1
LAZYGIT_SHA256=02beacbcda0fa342e50ae3480ba8147307353af3fb28e1d5f790e02329c201a6

[ "$(uname -m)" = x86_64 ] || die "download URL assumes x86_64 (got $(uname -m))"
if have lazygit; then ok "lazygit present ($(command -v lazygit))"; else
    log "Installing lazygit $LAZYGIT_VERSION"
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
    fetch_verified "https://github.com/jesseduffield/lazygit/releases/download/v$LAZYGIT_VERSION/lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz" "$LAZYGIT_SHA256" "$tmp/lazygit.tar.gz"
    tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
    install -m755 "$tmp/lazygit" "$BIN_DIR/lazygit"; ok "lazygit -> $BIN_DIR/lazygit"
fi

link "$REPO_ROOT/config/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"
