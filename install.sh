#!/usr/bin/env bash
# One-shot installer: runs the numbered steps in order.
# Usage:
#   ./install.sh            # run all steps
#   ./install.sh 02 03      # run only selected steps
source "$(dirname "${BASH_SOURCE[0]}")/scripts/lib.sh"

STEPS=(00-packages 01-fonts 02-eww 03-deploy)
# Optional steps — never run in "all" mode automatically; offered interactively
# at the end, or runnable explicitly by name (e.g. ./install.sh 90).
OPTIONAL=(90-disable-internal-keyboard)

run_step() {
    local s="$1"
    local f="$REPO_ROOT/scripts/$s.sh"
    [ -f "$f" ] || die "no such step: $s"
    log "===== STEP $s ====="
    bash "$f"
}

resolve() {  # map "02" or "02-eww" to a full step name from STEPS+OPTIONAL
    printf '%s\n' "${STEPS[@]}" "${OPTIONAL[@]}" | grep -E "^$1(-|$)" | head -1
}

cat <<'BANNER'
  hnp-dotfiles — bspwm + eww (Debian 13 / Dell Inspiron 5570)
  Steps: 00-packages  01-fonts  02-eww(build)  03-deploy(symlinks)
  Optional: 90-disable-internal-keyboard (permanent, via GRUB i8042.nokbd)
BANNER

if [ "$#" -gt 0 ]; then
    for s in "$@"; do
        match=$(resolve "$s")
        [ -n "$match" ] || die "unknown step '$s' (have: ${STEPS[*]} ${OPTIONAL[*]})"
        run_step "$match"
    done
else
    confirm "Run ALL core steps now?" || { warn "aborted"; exit 0; }
    for s in "${STEPS[@]}"; do run_step "$s"; done
    # Offer optional steps individually
    for s in "${OPTIONAL[@]}"; do
        echo
        if confirm "Optional: run '$s'?"; then run_step "$s"; else warn "skipped $s"; fi
    done
fi

echo
ok "Done. Log out and pick the 'bspwm' session, or reload: bspc wm -r"
echo "   Start/refresh the bar manually with: ~/.config/eww/launch-eww.sh"
