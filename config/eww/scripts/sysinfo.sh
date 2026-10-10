#!/usr/bin/env bash
# Lightweight system readouts for eww defpoll modules.
# Usage: sysinfo.sh <cpu|mem|fs|bat|backlight|date|window>

cpu() {
    # % busy over a 0.3s sample
    read -r _ a b c d e f g _ < /proc/stat
    local idle1=$((d+e)) total1=$((a+b+c+d+e+f+g))
    sleep 0.3
    read -r _ a b c d e f g _ < /proc/stat
    local idle2=$((d+e)) total2=$((a+b+c+d+e+f+g))
    local dt=$((total2-total1)) di=$((idle2-idle1))
    [ "$dt" -le 0 ] && { echo 0; return; }
    echo $(( (100*(dt-di))/dt ))
}

mem() {
    # used %
    local total avail
    total=$(awk '/MemTotal/{print $2}' /proc/meminfo)
    avail=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
    echo $(( (100*(total-avail))/total ))
}

fs() {
    # root usage %
    df -P / | awk 'NR==2{gsub("%","",$5); print $5}'
}

bat() {
    local cap status
    cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
    status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
    [ -z "$cap" ] && { echo '{"cap":0,"charging":false,"present":false}'; return; }
    local charging=false
    [ "$status" = "Charging" ] && charging=true
    echo "{\"cap\":$cap,\"charging\":$charging,\"present\":true}"
}

backlight() {
    local cur max dev
    dev=$(ls -d /sys/class/backlight/* 2>/dev/null | head -1)
    [ -z "$dev" ] && { echo 0; return; }
    cur=$(cat "$dev/brightness"); max=$(cat "$dev/max_brightness")
    [ "$max" -le 0 ] && { echo 0; return; }
    echo $(( (100*cur)/max ))
}

datef() { date '+%a %d/%m  %H:%M'; }

case "$1" in
    cpu) cpu;;
    mem) mem;;
    fs) fs;;
    bat) bat;;
    backlight) backlight;;
    date) datef;;
    *) echo "usage: $0 <cpu|mem|fs|bat|backlight|date>" >&2; exit 1;;
esac
