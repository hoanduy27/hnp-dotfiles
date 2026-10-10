#!/usr/bin/env bash
# Step 03 — symlink configs from the repo into ~/.config.
# Existing real files/dirs are backed up with a timestamp suffix.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

CFG="$HOME/.config"

log "Deploying configs from $REPO_ROOT/config -> $CFG"
link "$REPO_ROOT/config/bspwm" "$CFG/bspwm"
link "$REPO_ROOT/config/sxhkd" "$CFG/sxhkd"
link "$REPO_ROOT/config/picom" "$CFG/picom"
link "$REPO_ROOT/config/dunst" "$CFG/dunst"
link "$REPO_ROOT/config/eww"   "$CFG/eww"

log "Making scripts executable"
chmod +x "$REPO_ROOT"/config/bspwm/*.sh \
         "$REPO_ROOT"/config/eww/*.sh \
         "$REPO_ROOT"/config/eww/scripts/*.sh 2>/dev/null || true
chmod +x "$REPO_ROOT"/config/bspwm/bspwmrc "$REPO_ROOT"/config/sxhkd/sxhkdrc 2>/dev/null || true

ok "deploy complete"
echo
warn "Hardware note (Dell Inspiron 5570):"
echo "  - bspwmrc remaps the touchpad by name 'SynPS/2 Synaptics TouchPad'."
echo "    If your touchpad differs, check: xinput list   and update bspwmrc."
echo "  - To disable the spammy internal keyboard at boot, add 'i8042.nokbd'"
echo "    to GRUB_CMDLINE_LINUX_DEFAULT in /etc/default/grub, then: sudo update-grub"
