#!/usr/bin/env bash
# Enable/disable the built-in (AT/PS2) laptop keyboard at runtime.
# Handy on a laptop whose internal keyboard spams keys — use a USB keyboard
# and turn the internal one off. This does NOT touch the boot menu stage;
# for that, add `i8042.nokbd` to GRUB (see README).
#
# Usage:
#   toggle-internal-keyboard.sh [disable|enable|toggle|status]
#   (no arg = toggle)
#
# Two backends, tried in order:
#   1. xinput  — X11 only, no root, per-session (default; instant)
#   2. sysfs   — unbind the atkbd serio driver (needs sudo; use --kernel)
#
# Override the device name if auto-detect misses it:
#   KBD_NAME="AT Translated Set 2 keyboard" toggle-internal-keyboard.sh disable

set -u
KBD_NAME="${KBD_NAME:-AT Translated Set 2 keyboard}"
STATE_FILE="/tmp/internal-kbd.state"

notify() { command -v notify-send >/dev/null 2>&1 && notify-send -t 2000 "Internal keyboard" "$1"; echo "$1"; }

# ---------- xinput backend ----------
xinput_id() {
    command -v xinput >/dev/null 2>&1 || return 1
    xinput list --id-only "$KBD_NAME" 2>/dev/null | head -1
}
xinput_enabled() {
    local id="$1"
    # "Device Enabled" -> 1/0
    xinput list-props "$id" 2>/dev/null | awk -F: '/Device Enabled/{gsub(/[^01]/,"",$2); print $2; exit}'
}
xinput_set() {
    local id="$1" action="$2"
    xinput "$action" "$id"
}

# ---------- sysfs backend (kernel-level) ----------
atkbd_serio() {
    # Find the serio device bound to the atkbd driver
    for d in /sys/bus/serio/devices/serio*; do
        [ -e "$d/driver" ] || continue
        case "$(readlink -f "$d/driver")" in *atkbd*) basename "$d"; return 0;; esac
    done
    return 1
}
kernel_disable() {
    local s; s=$(atkbd_serio) || { echo "no atkbd serio device bound"; return 1; }
    echo -n "$s" | sudo tee /sys/bus/serio/drivers/atkbd/unbind >/dev/null && notify "disabled (kernel: $s)"
}
kernel_enable() {
    # Rebind any unbound serio that looks like a keyboard
    for d in /sys/bus/serio/devices/serio*; do
        local id; id=$(basename "$d")
        echo -n "$id" | sudo tee /sys/bus/serio/drivers/atkbd/bind >/dev/null 2>&1 && notify "enabled (kernel: $id)" && return 0
    done
    echo "could not rebind atkbd"; return 1
}

action="${1:-toggle}"
use_kernel=0
[ "$action" = "--kernel" ] && { use_kernel=1; action="${2:-toggle}"; }

if [ "$use_kernel" -eq 1 ]; then
    case "$action" in
        disable) kernel_disable ;;
        enable)  kernel_enable ;;
        status)  atkbd_serio >/dev/null && echo "atkbd: bound (enabled)" || echo "atkbd: unbound (disabled)" ;;
        toggle)  atkbd_serio >/dev/null && kernel_disable || kernel_enable ;;
        *) echo "usage: $0 --kernel [disable|enable|toggle|status]" >&2; exit 1 ;;
    esac
    exit $?
fi

# xinput path (default)
id=$(xinput_id) || { echo "xinput not available; try: $0 --kernel $action" >&2; exit 1; }
[ -n "${id:-}" ] || { echo "internal keyboard '$KBD_NAME' not found. Run: xinput list" >&2; exit 1; }

case "$action" in
    disable) xinput_set "$id" disable && notify "disabled (xinput id $id)" ;;
    enable)  xinput_set "$id" enable  && notify "enabled (xinput id $id)" ;;
    status)  [ "$(xinput_enabled "$id")" = "1" ] && echo "enabled (id $id)" || echo "disabled (id $id)" ;;
    toggle)
        if [ "$(xinput_enabled "$id")" = "1" ]; then xinput_set "$id" disable && notify "disabled (id $id)"
        else xinput_set "$id" enable && notify "enabled (id $id)"; fi ;;
    *) echo "usage: $0 [disable|enable|toggle|status] | --kernel [...]" >&2; exit 1 ;;
esac
