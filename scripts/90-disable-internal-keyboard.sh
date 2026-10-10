#!/usr/bin/env bash
# OPTIONAL step — permanently disable the built-in (AT/PS2) laptop keyboard.
# Adds `i8042.nokbd` to the kernel command line via GRUB, so the internal
# keyboard is off on every boot (from kernel init onward). A USB keyboard still
# works. The touchpad is unaffected (that's the aux port, i8042.noaux).
#
# NOTE: this takes effect once the kernel loads — it does NOT cover the BIOS /
# boot-menu / GRUB-menu stage. For a fix at every stage, unplug the keyboard
# ribbon in hardware.
#
# Reversible: re-run with `enable`, or remove i8042.nokbd from /etc/default/grub
# and run `sudo update-grub`.
#
# Usage: 90-disable-internal-keyboard.sh [disable|enable|status]   (default: disable)
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

GRUB_FILE="/etc/default/grub"
PARAM="i8042.nokbd"
action="${1:-disable}"

[ -f "$GRUB_FILE" ] || die "$GRUB_FILE not found (is this a GRUB system?)"

current_line() { grep -E '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB_FILE" | tail -1; }
has_param() { current_line | grep -qw -- "$PARAM"; }

apply_grub() {
    log "Running update-grub"
    if have update-grub; then sudo update-grub
    else sudo grub-mkconfig -o /boot/grub/grub.cfg; fi
}

backup() {
    local bak="${GRUB_FILE}.bak-$(date +%Y%m%d-%H%M%S)"
    sudo cp "$GRUB_FILE" "$bak"
    warn "backed up $GRUB_FILE -> $bak"
}

case "$action" in
  status)
    if has_param; then ok "$PARAM is present — internal keyboard disabled on boot"
    else echo "$PARAM not set — internal keyboard enabled"; fi
    current_line
    ;;

  disable)
    if has_param; then ok "$PARAM already set; nothing to do"; exit 0; fi
    log "This will permanently disable the internal keyboard on every boot."
    echo "  Make sure you have a USB keyboard available."
    confirm "Add '$PARAM' to GRUB and update?" || { warn "aborted"; exit 0; }
    backup
    if grep -qE '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB_FILE"; then
        # insert the param just before the closing quote of the existing value
        sudo sed -i -E "s/^(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*)\"/\1 $PARAM\"/" "$GRUB_FILE"
    else
        echo "GRUB_CMDLINE_LINUX_DEFAULT=\"$PARAM\"" | sudo tee -a "$GRUB_FILE" >/dev/null
    fi
    # tidy any accidental double space
    sudo sed -i -E 's/(GRUB_CMDLINE_LINUX_DEFAULT=")[[:space:]]+/\1/' "$GRUB_FILE"
    has_param || die "failed to add $PARAM — check $GRUB_FILE manually"
    ok "added: $(current_line)"
    apply_grub
    ok "Done. Internal keyboard will be off after reboot. Undo: run '$0 enable'."
    ;;

  enable)
    if ! has_param; then ok "$PARAM not present; internal keyboard already enabled"; exit 0; fi
    backup
    sudo sed -i -E "s/[[:space:]]*$PARAM//g" "$GRUB_FILE"
    has_param && die "failed to remove $PARAM — edit $GRUB_FILE manually"
    ok "removed $PARAM: $(current_line)"
    apply_grub
    ok "Done. Internal keyboard will be back after reboot."
    ;;

  *) die "usage: $0 [disable|enable|status]" ;;
esac
