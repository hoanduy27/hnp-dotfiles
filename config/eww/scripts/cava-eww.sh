#!/usr/bin/env bash
# Self-contained cava spectrum for eww deflisten.
# Emits a line like "▁▂▃▄▅▆▇" that updates in real time.
bars="▁▂▃▄▅▆▇█"
n=7
cfg=$(mktemp /tmp/eww_cava.XXXXXX)
cleanup() { rm -f "$cfg"; }
trap cleanup EXIT

cat > "$cfg" <<EOF
[general]
bars = $n
framerate = 30
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
bar_delimiter = 59
EOF

# dict maps 0-7 to block chars
dict="s/;//g"
i=0
while [ $i -le 7 ]; do
    dict="$dict;s/\b$i\b/${bars:$i:1}/g"
    i=$((i+1))
done

cava -p "$cfg" | sed -u "$dict"
