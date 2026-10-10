#!/usr/bin/env bash
# Step 30 — install the rofi themes used by the .rasi files, plus the Nerd Fonts
# those themes reference. Theme files are vendored in the repo (config/rofi/themes),
# fonts are downloaded from the nerd-fonts releases. No sudo.
#
# rasi usage:
#   show-apps.rasi  -> @theme "simple-tokyonight"   (font: Iosevka Nerd Font)
#   powermenu.rasi  -> @theme "squared-everforest"  (font: FiraCode Nerd Font)
#   media-popup.rasi-> @theme "simple-tokyonight"
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# rofi searches ~/.local/share/rofi/themes for `@theme "name"`
THEME_DIR="$HOME/.local/share/rofi/themes"
SRC="$REPO_ROOT/config/rofi/themes"

log "Installing rofi themes -> $THEME_DIR"
mkdir -p "$THEME_DIR"
for t in simple-tokyonight squared-everforest; do
    if [ -f "$SRC/$t.rasi" ]; then
        cp "$SRC/$t.rasi" "$THEME_DIR/"
        ok "theme $t.rasi"
    else
        warn "missing vendored theme $SRC/$t.rasi"
    fi
done

# Fonts the themes ask for (and Symbols for icon glyphs)
install_nerd_font Iosevka  "Iosevka Nerd Font"
install_nerd_font FiraCode "FiraCode Nerd Font"
install_nerd_font NerdFontsSymbolsOnly "Symbols Nerd Font"

ok "rofi themes ready. Test:  rofi -show drun -theme ~/.config/eww/scripts/show-apps.rasi"
