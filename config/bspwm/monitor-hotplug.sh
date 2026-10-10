#!/bin/bash

export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-/home/duy/.Xauthority}"

# Debounce: only one instance runs at a time; subsequent triggers within 2s are dropped
LOCKFILE="/tmp/monitor-hotplug.lock"
exec 9>"$LOCKFILE"
if ! flock -n 9; then
    exit 0
fi

# Bail out immediately if Xorg is not reachable
if ! timeout 5 xrandr --query &>/dev/null; then
    exit 0
fi

# Let DRM settle before querying (GPU add/remove events arrive before drivers are ready)
sleep 2

setup_monitors() {

	# Auto-detect connected monitors
	MONITORS=$(timeout 10 xrandr --query | grep " connected" | cut -d" " -f1)
	MONITOR_COUNT=$(echo "$MONITORS" | wc -l)
	
	# Collect all windows before reconfiguration
	all_windows=($(bspc query -N -n .window))

        declare -A window_info
	for  win in "${all_windows[@]}"; do
	    desktop=$(bspc query -D -n "$win" --names)
	    window_info[$win]=$desktop
	done

	if [ "$MONITOR_COUNT" -eq 3 ]; then 
	    ~/.screenlayout/display3.sh
	# Setup xrandr for extended displays (not mirrored)
	elif [ "$MONITOR_COUNT" -gt 1 ]; then
	    echo "Setting up $MONITOR_COUNT monitors for extended display..."
	    
	    # Get first monitor as primary
	    PRIMARY=$(echo "$MONITORS" | sed -n 1p)
	    timeout 10 xrandr --output "$PRIMARY" --auto --primary

	    # Extend additional monitors to the right
	    POSITION="$PRIMARY"
	    for monitor in $(echo "$MONITORS" | tail -n +2); do
	        timeout 10 xrandr --output "$monitor" --auto --left-of "$POSITION"
	        POSITION="$monitor"
	    done
	   
	    # Wait for xrandr to apply
	    sleep 1
	fi

	# Now configure bspwm desktops
	# Re-query monitors after xrandr setup using bspc
	# MONITORS=$(bspc query -M --names)
	# ACTUAL_COUNT=$(echo "$MONITORS" | wc -l)

	echo "Detected monitors: $MONITORS"
	echo "Monitor count: $MONITOR_COUNT"

	# Desktops are managed dynamically (see dynamic-desktops.sh): each
	# monitor just starts with a single desktop, and the daemon grows
	# or prunes them at runtime so there's always exactly one empty
	# trailing desktop, GNOME-style.
	DESK_NUM=1
	for monitor in $MONITORS; do
	    bspc monitor "$monitor" -d "$DESK_NUM"
	    echo "  $monitor: desktop $DESK_NUM"
	    DESK_NUM=$(($DESK_NUM + 1))
	done

	# Pinned desktops for fixed app rules (bspwmrc), recreated here since
	# the -d assignment above replaces each monitor's whole desktop list.
	FIRST_MON=$(echo "$MONITORS" | head -n 1)
	LAST_MON=$(echo "$MONITORS" | tail -n 1)
	bspc monitor "$FIRST_MON" -a web
	bspc monitor "$LAST_MON" -a gimp


        # Remove temporary desktops
	for monitor in "${monitors[@]}"; do
	   bspc desktop "$monitor:_temp_" -r 2>/dev/null
	done
    
        # Migrate windows back to their original desktops (or desktop 1 if doesn't exist)
        for win in "${all_windows[@]}"; do
            if bspc query -N -n "$win" &>/dev/null; then
                original_desktop="${window_info[$win]}"
            
            # Try to move to original desktop, fallback to first desktop if it doesn't exist
                if bspc query -D -d "$original_desktop" &>/dev/null; then
                    bspc node "$win" -d "$original_desktop"
                else
                    # Desktop doesn't exist anymore, move to first available
                    first_desktop=$(bspc query -D -m "${monitors[0]}" | head -n1)
                    bspc node "$win" -d "$first_desktop"
                fi
             fi
         done
}

setup_monitors

if command -v eww &> /dev/null; then
    ~/.config/eww/launch-eww.sh
fi
