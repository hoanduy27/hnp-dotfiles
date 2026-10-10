#!/bin/bash
# GNOME-style dynamic desktops: keep exactly one empty trailing
# desktop per monitor. Desktops named in PINNED_DESKTOPS (used by
# fixed app rules, e.g. Gimp/Chromium in bspwmrc) are never touched.

export DISPLAY="${DISPLAY:-:0}"

PINNED_DESKTOPS=(gimp web)

is_pinned() {
    local name="$1"
    for p in "${PINNED_DESKTOPS[@]}"; do
        [ "$name" = "$p" ] && return 0
    done
    return 1
}

next_name() {
    local max
    max=$(bspc query -D --names | grep -E '^[0-9]+$' | sort -n | tail -1)
    echo $(( ${max:-0} + 1 ))
}

reconcile_monitor() {
    local mon="$1"
    local names free
    names=($(bspc query -D -m "$mon" --names))
    free=()

    for name in "${names[@]}"; do
        is_pinned "$name" && continue
        if [ -z "$(bspc query -N -d "$name" -n .window)" ]; then
            free+=("$name")
        fi
    done

    if [ ${#free[@]} -eq 0 ]; then
        bspc monitor "$mon" -a "$(next_name)"
    elif [ ${#free[@]} -gt 1 ]; then
        local keep="${free[-1]}"
        for f in "${free[@]}"; do
            [ "$f" = "$keep" ] || bspc desktop "$f" -r 2>/dev/null
        done
    fi
}

reconcile_all() {
    for mon in $(bspc query -M --names); do
        reconcile_monitor "$mon"
    done
}

reconcile_all

bspc subscribe node_add node_remove node_transfer desktop_add desktop_remove monitor_add |
while read -r _; do
    reconcile_all
done
