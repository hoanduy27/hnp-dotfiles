#!/bin/bash
# Get the current mouse position and window geometry
eval $(xdotool getmouselocation --shell)
eval $(xdotool getwindowgeometry --shell $(bspc query -N -n focused))

# Resize based on mouse movement
bspc node -z right $((X - WIDTH)) 0
bspc node -z bottom 0 $((Y - HEIGHT))
