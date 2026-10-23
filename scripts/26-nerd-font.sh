#!/usr/bin/env bash
# Step 26 — Symbols Nerd Font, so Neovim's icons render. "Symbols Only" holds just the icon glyphs;
# fontconfig falls back to it for them, so it works with whatever font your terminal already uses.
# Pinned release, verified by sha256. To bump: change NERD_FONTS_VERSION, download the archive once,
# check its hash against the release page, then paste it into NERD_FONT_SHA256.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

NERD_FONTS_VERSION=v3.5.1
NERD_FONT_SHA256=01172f37db8543edb102e5cb5c64101c9f4686630804d49b419aa07b23a69996

if fc-list 2>/dev/null | grep -qi "Symbols Nerd Font"; then ok "Symbols Nerd Font already installed"; exit 0; fi

destdir="$HOME/.local/share/fonts/NerdFontsSymbolsOnly"
log "Installing Symbols Nerd Font $NERD_FONTS_VERSION"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fetch_verified "https://github.com/ryanoasis/nerd-fonts/releases/download/$NERD_FONTS_VERSION/NerdFontsSymbolsOnly.tar.xz" "$NERD_FONT_SHA256" "$tmp/font.tar.xz"
tar -xJf "$tmp/font.tar.xz" -C "$tmp"
mkdir -p "$destdir"
find "$tmp" \( -name '*.ttf' -o -name '*.otf' \) -exec cp {} "$destdir/" \;
fc-cache -f "$destdir" >/dev/null 2>&1
ok "Symbols Nerd Font -> $destdir"
warn "restart your terminal; if icons still show as boxes, set a Nerd Font as the terminal's font"
