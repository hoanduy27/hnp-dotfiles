#!/usr/bin/env bash
# Step 21 — Neovim helpers from the OS package manager (no downloads outside apt):
#   python3-pylsp  Python language server (pylsp + jedi): go-to-definition, references, hover, completion.
#                  Recommended packages (formatters/linters like autopep8, yapf, flake8) are skipped on purpose.
#   ripgrep        `rg`, used by the grep pickers, todo-comments and grug-far.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

missing=()
have pylsp || missing+=(python3-pylsp)
have rg    || missing+=(ripgrep)
if [ "${#missing[@]}" -eq 0 ]; then ok "pylsp and rg present"; exit 0; fi

log "Installing ${missing[*]} (sudo apt)"
sudo apt-get install -y --no-install-recommends "${missing[@]}"
have pylsp && ok "pylsp -> $(command -v pylsp)" || warn "pylsp not on PATH after install"
have rg && ok "rg -> $(command -v rg)" || warn "rg not on PATH after install"
