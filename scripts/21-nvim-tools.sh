#!/usr/bin/env bash
# Step 21 — CLI tools LazyVim relies on, into ~/.local/bin (no sudo).
# Adapted from nvim_migration/scripts/01-install-tools.sh.
#   fd (file picker), lazygit (<leader>gg), delta (lazygit diffs), tree-sitter (parsers)
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
BIN_DIR="$HOME/.local/bin"; mkdir -p "$BIN_DIR"
[ "$(uname -m)" = x86_64 ] || die "download URLs assume x86_64 (got $(uname -m))"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

gh_latest_asset() {
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
      | grep -oE '"browser_download_url": *"[^"]+"' | cut -d'"' -f4 | grep -E "$2" | head -n1
}

log "Checking base tools (install any missing with apt: ripgrep fzf build-essential unzip curl nodejs npm)"
for t in git rg fzf gcc make unzip curl node npm nvim; do
    have "$t" && ok "$t" || warn "$t missing"
done

if have fd; then ok "fd present"; else
    log "Installing fd"
    curl -fsSL "$(gh_latest_asset sharkdp/fd 'x86_64-unknown-linux-musl\.tar\.gz$')" | tar -xz -C "$tmp"
    install -m755 "$tmp"/fd-*/fd "$BIN_DIR/fd"; ok "fd -> $BIN_DIR/fd"
fi
if have lazygit; then ok "lazygit present"; else
    log "Installing lazygit"
    curl -fsSL "$(gh_latest_asset jesseduffield/lazygit '_[Ll]inux_x86_64\.tar\.gz$')" | tar -xz -C "$tmp" lazygit
    install -m755 "$tmp/lazygit" "$BIN_DIR/lazygit"; ok "lazygit -> $BIN_DIR/lazygit"
fi
if have delta; then ok "delta present"; else
    log "Installing delta"
    curl -fsSL "$(gh_latest_asset dandavison/delta 'x86_64-unknown-linux-musl\.tar\.gz$')" | tar -xz -C "$tmp"
    install -m755 "$tmp"/delta-*/delta "$BIN_DIR/delta"; ok "delta -> $BIN_DIR/delta"
fi
if have tree-sitter; then ok "tree-sitter present"; else
    log "Installing tree-sitter CLI (npm -g)"
    npm install -g tree-sitter-cli && ok "tree-sitter $(tree-sitter --version)" || warn "tree-sitter install failed"
fi
have xclip || have xsel || have wl-copy && ok "clipboard provider present" || warn "no clipboard tool: sudo apt install xclip"
