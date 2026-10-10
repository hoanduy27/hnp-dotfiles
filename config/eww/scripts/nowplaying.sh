#!/usr/bin/env bash
# Stream now-playing text for eww deflisten via playerctl.
# Emits "<icon> Artist - Title" or "" when nothing plays.
fmt='{{status}}|{{artist}} - {{title}}'

render() {
    local line="$1" status rest icon
    status=${line%%|*}
    rest=${line#*|}
    case "$status" in
        Playing) icon="" ;;
        Paused)  icon="" ;;
        *) echo ""; return ;;
    esac
    # guard against " - " with empty fields
    rest=$(printf '%s' "$rest" | sed -e 's/^ - //' -e 's/ - $//')
    [ -z "$rest" ] && { echo ""; return; }
    echo "$icon  $rest"
}

if ! command -v playerctl >/dev/null 2>&1; then
    echo ""; exit 0
fi

# Initial state
render "$(playerctl metadata --format "$fmt" 2>/dev/null)"
# Follow changes
playerctl -F metadata --format "$fmt" 2>/dev/null | while IFS= read -r line; do
    render "$line"
done
