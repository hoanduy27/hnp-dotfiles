#!/usr/bin/env bash
# Short network/bluetooth readouts for eww.
# wifi -> JSON {icon,label,up}   bt -> JSON {label,on,connected}
# The wifi interface is auto-detected (never hardcoded).

# Detect the wireless interface name (e.g. wlan0, wlp3s0) with fallbacks.
wifi_iface() {
    local i
    # 1. NetworkManager
    if command -v nmcli >/dev/null 2>&1; then
        i=$(nmcli -t -f DEVICE,TYPE device 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}')
        [ -n "$i" ] && { echo "$i"; return; }
    fi
    # 2. sysfs: any net device exposing a wireless/ dir
    for d in /sys/class/net/*/wireless; do
        [ -e "$d" ] && { basename "$(dirname "$d")"; return; }
    done
    # 3. iw
    command -v iw >/dev/null 2>&1 && iw dev 2>/dev/null | awk '/Interface/{print $2; exit}'
}

wifi() {
    local iface ssid signal icon
    iface=$(wifi_iface)
    [ -z "$iface" ] && { echo '{"icon":"","label":"no wifi","up":false}'; return; }

    if command -v nmcli >/dev/null 2>&1; then
        local line
        line=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null | awk -F: '$1=="yes"{print; exit}')
        ssid=$(echo "$line" | cut -d: -f2)
        signal=$(echo "$line" | cut -d: -f3)
    fi
    # Fallback without NetworkManager
    [ -z "$ssid" ] && command -v iwgetid >/dev/null 2>&1 && ssid=$(iwgetid -r "$iface" 2>/dev/null)
    if [ -z "$signal" ] && [ -r /proc/net/wireless ]; then
        # link quality (col 3, out of ~70) -> rough %
        local q; q=$(awk -v i="$iface:" '$1==i{gsub(/\./,"",$3); print $3; exit}' /proc/net/wireless)
        [ -n "$q" ] && signal=$(( q * 100 / 70 ))
    fi

    if [ -n "$ssid" ]; then
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
    iface) wifi_iface;;   # handy for debugging: net.sh iface
    *) echo "usage: $0 <wifi|bt|iface>" >&2; exit 1;;
esac
