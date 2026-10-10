#!/usr/bin/env bash
# Stream the focused window title for eww deflisten.
# Prefers xtitle (install: apt install xtitle); falls back to bspc + xprop.
trunc() { awk '{ if (length($0) > 60) print substr($0,1,57) "..."; else print }'; }

if command -v xtitle >/dev/null 2>&1; then
    xtitle -s -t 60
else
    # Fallback: poll via bspc focus history
    last=""
    while true; do
        id=$(bspc query -N -n focused.window 2>/dev/null)
        if [ -n "$id" ]; then
            t=$(xprop -id "$id" _NET_WM_NAME 2>/dev/null | sed -e 's/.*= "//' -e 's/"$//')
            [ -z "$t" ] && t=$(xprop -id "$id" WM_NAME 2>/dev/null | sed -e 's/.*= "//' -e 's/"$//')
        else
            t=""
        fi
        t=$(printf '%s' "$t" | trunc)
        [ "$t" != "$last" ] && { echo "$t"; last="$t"; }
        sleep 0.4
    done
fi
