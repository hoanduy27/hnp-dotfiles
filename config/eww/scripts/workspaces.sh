#!/usr/bin/env bash
# Emit bspwm desktops for the focused monitor as a JSON array for eww.
# Each item: {name, focused, occupied, urgent}
# Re-emits on every bspwm event via `bspc subscribe`.

emit() {
    local monitor focused_desktop
    # Focused monitor id
    focused_desktop=$(bspc query -D -d focused --names 2>/dev/null)

    # Build JSON across all desktops of the focused monitor
    local out="[" first=1
    while IFS= read -r d; do
        [ -z "$d" ] && continue
        local name flags focused occupied urgent
        name=$(bspc query -D -d "$d" --names)
        flags=$(bspc query -T -d "$d" | tr -d '\n')
        focused=false; occupied=false; urgent=false
        [ "$name" = "$focused_desktop" ] && focused=true
        # occupied = has at least one node
        if [ -n "$(bspc query -N -d "$d" -n .window 2>/dev/null)" ]; then occupied=true; fi
        case "$(bspc query -T -d "$d")" in *'"urgent":true'*) urgent=true;; esac
        [ $first -eq 0 ] && out+=","
        out+="{\"name\":\"$name\",\"focused\":$focused,\"occupied\":$occupied,\"urgent\":$urgent}"
        first=0
    done < <(bspc query -D -m focused --names 2>/dev/null)
    out+="]"
    echo "$out"
}

emit
bspc subscribe desktop node_add node_remove node_transfer desktop_focus desktop_add desktop_remove 2>/dev/null | while read -r _; do
    emit
done
