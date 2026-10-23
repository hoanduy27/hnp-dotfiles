#!/usr/bin/env bash
# Step 21 — CLI tools LazyVim relies on, into ~/.local/bin (no sudo).
# Adapted from nvim_migration/scripts/01-install-tools.sh.
#   fd (file picker), lazygit (<leader>gg), delta (lazygit diffs), tree-sitter (parsers)
# Work profile: every download is pinned to a release and verified against a sha256 below.
# To bump one: change its version and URL, download it once, check the hash against the
# release page (lazygit also publishes checksums.txt), then paste the new hash here.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
BIN_DIR="$HOME/.local/bin"; mkdir -p "$BIN_DIR"
[ "$(uname -m)" = x86_64 ] || die "download URLs assume x86_64 (got $(uname -m))"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

FD_VERSION=v10.5.0
FD_SHA256=761c72dc8e120d85b22292063be8a796e2eeb20eb3e4f38b8fa2343ccf3514a7
LAZYGIT_VERSION=0.65.1
LAZYGIT_SHA256=02beacbcda0fa342e50ae3480ba8147307353af3fb28e1d5f790e02329c201a6
DELTA_VERSION=0.19.2
DELTA_SHA256=f1ea01ca7728ce3462debc359f39dfc7cbbc1a63224b71fefabf92042864aa1b
TREE_SITTER_VERSION=v0.27.0
TREE_SITTER_SHA256=20a1f39ec1c45f2211492dcb8881c802b643b554bb196869a29ac3778277fa77

log "Checking base tools (install any missing with apt: ripgrep fzf build-essential unzip curl nodejs npm)"
for t in git rg fzf gcc make unzip curl node npm nvim; do
    have "$t" && ok "$t" || warn "$t missing"
done

if have fd; then ok "fd present"; else
    log "Installing fd $FD_VERSION"
    asset="fd-$FD_VERSION-x86_64-unknown-linux-musl"
    fetch_verified "https://github.com/sharkdp/fd/releases/download/$FD_VERSION/$asset.tar.gz" "$FD_SHA256" "$tmp/fd.tar.gz"
    tar -xzf "$tmp/fd.tar.gz" -C "$tmp"
    install -m755 "$tmp/$asset/fd" "$BIN_DIR/fd"; ok "fd -> $BIN_DIR/fd"
fi
if have lazygit; then ok "lazygit present"; else
    log "Installing lazygit $LAZYGIT_VERSION"
    fetch_verified "https://github.com/jesseduffield/lazygit/releases/download/v$LAZYGIT_VERSION/lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz" "$LAZYGIT_SHA256" "$tmp/lazygit.tar.gz"
    tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
    install -m755 "$tmp/lazygit" "$BIN_DIR/lazygit"; ok "lazygit -> $BIN_DIR/lazygit"
fi
if have delta; then ok "delta present"; else
    log "Installing delta $DELTA_VERSION"
    asset="delta-$DELTA_VERSION-x86_64-unknown-linux-musl"
    fetch_verified "https://github.com/dandavison/delta/releases/download/$DELTA_VERSION/$asset.tar.gz" "$DELTA_SHA256" "$tmp/delta.tar.gz"
    tar -xzf "$tmp/delta.tar.gz" -C "$tmp"
    install -m755 "$tmp/$asset/delta" "$BIN_DIR/delta"; ok "delta -> $BIN_DIR/delta"
fi
if have tree-sitter; then ok "tree-sitter present"; else
    # prebuilt release binary instead of `npm install -g`, so it can be checksum-verified
    log "Installing tree-sitter CLI $TREE_SITTER_VERSION"
    fetch_verified "https://github.com/tree-sitter/tree-sitter/releases/download/$TREE_SITTER_VERSION/tree-sitter-linux-x64.gz" "$TREE_SITTER_SHA256" "$tmp/tree-sitter.gz"
    gunzip -c "$tmp/tree-sitter.gz" > "$tmp/tree-sitter"
    install -m755 "$tmp/tree-sitter" "$BIN_DIR/tree-sitter"; ok "tree-sitter -> $BIN_DIR/tree-sitter"
fi
have xclip || have xsel || have wl-copy && ok "clipboard provider present" || warn "no clipboard tool: sudo apt install xclip"
