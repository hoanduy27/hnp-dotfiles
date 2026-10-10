#!/usr/bin/env bash
# Short network/bluetooth readouts for eww.
# wifi -> JSON {icon,label,up}   bt -> JSON {label,on,connected}

wifi() {
    local ssid signal icon up
    if command -v nmcli >/dev/null 2>&1; then
        local line
        line=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null | awk -F: '$1=="yes"{print; exit}')
        ssid=$(echo "$line" | cut -d: -f2)
        signal=$(echo "$line" | cut -d: -f3)
    fi
    if [ -n "$ssid" ]; then
        up=true
        if   [ "${signal:-0}" -ge 75 ]; then icon=""
        elif [ "${signal:-0}" -ge 50 ]; then icon=""
        elif [ "${signal:-0}" -ge 25 ]; then icon=""
        else icon=""; fi
        echo "{\"icon\":\"$icon\",\"label\":\"$ssid\",\"up\":true}"
    else
        echo "{\"icon\":\"\",\"label\":\"off\",\"up\":false}"
    fi
}

bt() {
    local on=false connected=false label="off"
    if command -v bluetoothctl >/dev/null 2>&1; then
        if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
            on=true; label="on"
            local dev
            dev=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-)
            if [ -n "$dev" ]; then connected=true; label="$dev"; fi
        fi
    fi
    echo "{\"on\":$on,\"connected\":$connected,\"label\":\"$label\"}"
}

case "$1" in
    wifi) wifi;;
    bt) bt;;
    *) echo "usage: $0 <wifi|bt>" >&2; exit 1;;
esac
