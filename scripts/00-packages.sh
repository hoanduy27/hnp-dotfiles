#!/usr/bin/env bash
# Step 00 — install Debian 13 packages for the bspwm + eww setup.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

APT_PKGS=(
  # X server + session glue (needed on a pure-terminal install — no DE yet)
  xorg xinit x11-xserver-utils xserver-xorg-input-libinput
  # window manager core
  bspwm sxhkd picom rofi dunst feh
  # terminal + input + misc desktop bits
  kitty plank ibus xclip xdotool
  # web browser (forgotten during the Debian netinst tasksel step)
  firefox-esr
  # screenshots / lock helpers used by sxhkd
  scrot maim slop
  # bar module backends
  cava playerctl brightnessctl
  pulseaudio-utils pipewire pipewire-pulse wireplumber
  network-manager bluez
  # fonts available from apt
  fonts-noto-cjk
  # toolchain to build eww from source (X11)
  build-essential pkg-config
  libgtk-3-dev libdbusmenu-gtk3-dev libpango1.0-dev
  libgdk-pixbuf-2.0-dev libcairo2-dev libglib2.0-dev
  git curl
)

log "Updating apt and installing ${#APT_PKGS[@]} packages (sudo required)..."
sudo apt-get update
sudo apt-get install -y "${APT_PKGS[@]}"
ok "apt packages installed"

warn "Notes:"
echo "  - No display manager is installed. Start the GUI from the TTY with: startx"
echo "    (step 03 deploys ~/.xinitrc which execs bspwm). To get a graphical"
echo "    login screen instead, optionally: sudo apt install lightdm"
echo "  - conky is OPTIONAL now (buggy on the Inspiron) and not installed by default."
echo "    bspwmrc only starts it if present. To use it: sudo apt install conky-all"
echo "  - 'betterlockscreen' (used by super+x / ctrl+shift+Escape) is not in apt."
echo "    Install later from https://github.com/betterlockscreen/betterlockscreen if you want lock."
echo "  - 'xtitle' (optional, nicer window-title module) is not in apt; the eww"
echo "    window module falls back to xprop polling without it."
