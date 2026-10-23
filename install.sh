#!/usr/bin/env bash
# One-shot installer: runs the numbered steps in order.
# Usage:
#   ./install.sh            # run all steps
#   ./install.sh 20 22      # run only selected steps
source "$(dirname "${BASH_SOURCE[0]}")/scripts/lib.sh"

STEPS=(10-zsh
       20-neovim 21-nvim-lsp 22-lazygit 23-nvim-deploy 24-nvim-bootstrap)

run_step() {
    local s="$1"
    local f="$REPO_ROOT/scripts/$s.sh"
    [ -f "$f" ] || die "no such step: $s"
    log "===== STEP $s ====="
    bash "$f"
}

resolve() {  # map "20" or "20-neovim" to a full step name from STEPS
    printf '%s\n' "${STEPS[@]}" | grep -E "^$1(-|$)" | head -1
}

cat <<'BANNER'
  hnp-dotfiles — minimal work profile (zsh + Neovim, plugins only)
  Steps: 10-zsh | 20..24 neovim
BANNER

if [ "$#" -gt 0 ]; then
    for s in "$@"; do
        match=$(resolve "$s")
        [ -n "$match" ] || die "unknown step '$s' (have: ${STEPS[*]})"
        run_step "$match"
    done
else
    confirm "Run ALL steps now?" || { warn "aborted"; exit 0; }
    for s in "${STEPS[@]}"; do run_step "$s"; done
fi

echo
ok "Done. Run 'exec zsh' to pick up the new shell."
