#!/usr/bin/env bash
# Step 21 — Python language server for Neovim, from the OS package manager (no downloads outside apt).
# python3-pylsp = pylsp + jedi: go-to-definition, references, hover, completion. Recommended
# packages (formatters/linters like autopep8, yapf, flake8) are skipped on purpose.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if have pylsp; then ok "pylsp present ($(command -v pylsp))"; exit 0; fi
log "Installing python3-pylsp (sudo apt)"
sudo apt-get install -y --no-install-recommends python3-pylsp
have pylsp && ok "pylsp -> $(command -v pylsp)" || warn "pylsp not on PATH after install"
