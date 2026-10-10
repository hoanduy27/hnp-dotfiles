#!/usr/bin/env bash
# Step 01 — install the bundled fonts (Tahoma, Ubuntu Nerd Font) to the user.
# Noto CJK comes from apt (fonts-noto-cjk) in step 00.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

DEST="$HOME/.local/share/fonts"
SRC="$REPO_ROOT/config/fonts"

log "Installing bundled fonts to $DEST"
mkdir -p "$DEST"
if compgen -G "$SRC/*.ttf" >/dev/null; then
    cp -v "$SRC"/*.ttf "$DEST"/
else
    warn "no bundled fonts found in $SRC"
fi

log "Rebuilding font cache"
fc-cache -f "$DEST" >/dev/null
ok "fonts installed; check: fc-list | grep -iE 'tahoma|ubuntu nerd|noto sans cjk jp'"
