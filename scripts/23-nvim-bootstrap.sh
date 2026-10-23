#!/usr/bin/env bash
# Step 23 — install plugins headlessly (no Mason/LSP servers in the minimal work profile), write a health report.
# Adapted from nvim_migration/scripts/05-bootstrap-plugins.sh.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[ -e "$HOME/.config/nvim" ] || die "run 22-nvim-deploy.sh first"
have nvim || die "nvim not found — run 20-neovim.sh first"

log "Installing plugins (lazy.nvim restore, pinned by lazy-lock.json)"
nvim --headless "+Lazy! restore" +qa # restore = install at the lockfile commits (sync would update and rewrite the lockfile)
ok "plugins installed (lockfile: config/nvim/lazy-lock.json)"

report="$REPO_ROOT/health-report.txt"
log "Writing :checkhealth report -> $report"
nvim --headless "+checkhealth lazyvim" "+w! $report" +qa || true
grep -q ERROR "$report" && warn "checkhealth has errors: grep ERROR $report" || ok "no errors in checkhealth"
