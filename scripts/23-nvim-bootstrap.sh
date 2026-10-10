#!/usr/bin/env bash
# Step 23 — install plugins + LSP servers headlessly, write a health report.
# Adapted from nvim_migration/scripts/05-bootstrap-plugins.sh.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[ -e "$HOME/.config/nvim" ] || die "run 22-nvim-deploy.sh first"
have nvim || die "nvim not found — run 20-neovim.sh first"

log "Installing plugins (lazy.nvim sync)"
nvim --headless "+Lazy! sync" +qa
ok "plugins installed (lockfile: config/nvim/lazy-lock.json)"

MASON_PKGS=(
  basedpyright ruff debugpy
  gopls goimports gofumpt gomodifytags impl delve golangci-lint
  vtsls js-debug-adapter
  json-lsp yaml-language-server taplo
  dockerfile-language-server docker-compose-language-service hadolint helm-ls
  marksman markdownlint-cli2 markdown-toc
  texlab buf
  bash-language-server shfmt shellcheck
  lua-language-server stylua
)
log "Installing ${#MASON_PKGS[@]} Mason packages (LSP/formatters/debuggers)"
MASON_PKGS="${MASON_PKGS[*]}" nvim --headless "+Lazy! load mason.nvim" \
    "+luafile $REPO_ROOT/config/nvim-scripts/mason-install.lua" \
    || warn "some Mason installs failed; open nvim and run :Mason to retry"

report="$REPO_ROOT/health-report.txt"
log "Writing :checkhealth report -> $report"
nvim --headless "+checkhealth lazyvim" "+w! $report" +qa || true
grep -q ERROR "$report" && warn "checkhealth has errors: grep ERROR $report" || ok "no errors in checkhealth"
