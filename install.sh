#!/usr/bin/env bash
# One-shot installer: runs the numbered steps in order.
# Usage:
#   ./install.sh            # run all steps
#   ./install.sh 02 03      # run only selected steps
source "$(dirname "${BASH_SOURCE[0]}")/scripts/lib.sh"

STEPS=(00-packages 01-fonts 02-eww 03-deploy)

run_step() {
    local s="$1"
    local f="$REPO_ROOT/scripts/$s.sh"
    [ -f "$f" ] || die "no such step: $s"
    log "===== STEP $s ====="
    bash "$f"
}

cat <<'BANNER'
  hnp-dotfiles — bspwm + eww (Debian 13 / Dell Inspiron 5570)
  Steps: 00-packages  01-fonts  02-eww(build)  03-deploy(symlinks)
BANNER

if [ "$#" -gt 0 ]; then
    for s in "$@"; do
        # allow "02" or "02-eww"
        match=$(printf '%s\n' "${STEPS[@]}" | grep -E "^$s(-|$)" | head -1)
        [ -n "$match" ] || die "unknown step '$s' (have: ${STEPS[*]})"
        run_step "$match"
    done
else
    confirm "Run ALL steps now?" || { warn "aborted"; exit 0; }
    for s in "${STEPS[@]}"; do run_step "$s"; done
fi

echo
ok "Done. Log out and pick the 'bspwm' session, or reload: bspc wm -r"
echo "   Start/refresh the bar manually with: ~/.config/eww/launch-eww.sh"
