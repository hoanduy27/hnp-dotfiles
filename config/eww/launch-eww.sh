#!/usr/bin/env bash
# Start the eww daemon and open all bar windows (one set per monitor).
set -u
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
CFG="$HOME/.config/eww"

command -v eww >/dev/null 2>&1 || { echo "eww not found in PATH" >&2; exit 1; }

# (Re)start daemon
eww --config "$CFG" kill 2>/dev/null
eww --config "$CFG" daemon

# Open the three bars. eww :monitor is 0-indexed; extend here for multi-monitor.
for w in bar-left bar-right bar-bottom; do
    eww --config "$CFG" open --screen 0 "$w" 2>/dev/null \
        || eww --config "$CFG" open "$w"
done

echo "eww bars launched."
