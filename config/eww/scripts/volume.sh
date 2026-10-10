#!/usr/bin/env bash
# PulseAudio/PipeWire volume helper for eww.
# get  -> JSON {vol, muted}
# up/down/toggle -> change and print nothing
sink="@DEFAULT_SINK@"

case "$1" in
    up)   pactl set-sink-volume "$sink" +5% ;;
    down) pactl set-sink-volume "$sink" -5% ;;
    toggle) pactl set-sink-mute "$sink" toggle ;;
    get|*)
        vol=$(pactl get-sink-volume "$sink" 2>/dev/null | grep -oP '\d+(?=%)' | head -1)
        muted=$(pactl get-sink-mute "$sink" 2>/dev/null | grep -q yes && echo true || echo false)
        echo "{\"vol\":${vol:-0},\"muted\":${muted:-false}}"
        ;;
esac
