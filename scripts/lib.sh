#!/usr/bin/env bash
# Shared helpers for the install scripts.
set -euo pipefail

# Repo root = parent of this scripts/ dir
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT

c_reset=$'\e[0m'; c_blue=$'\e[34m'; c_grn=$'\e[32m'; c_ylw=$'\e[33m'; c_red=$'\e[31m'
log()  { printf '%s==>%s %s\n' "$c_blue" "$c_reset" "$*"; }
ok()   { printf '%s  ok%s %s\n' "$c_grn" "$c_reset" "$*"; }
warn() { printf '%s warn%s %s\n' "$c_ylw" "$c_reset" "$*"; }
die()  { printf '%s err%s %s\n' "$c_red" "$c_reset" "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

confirm() {
    local prompt="${1:-Proceed?}"
    read -r -p "$prompt [y/N] " a
    [[ "$a" =~ ^[Yy]$ ]]
}

# Symlink src -> dest, backing up an existing non-symlink dest.
link() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    if [ -L "$dest" ]; then rm -f "$dest"
    elif [ -e "$dest" ]; then
        local bak="${dest}.bak-$(date +%Y%m%d-%H%M%S)"
        warn "backing up $dest -> $bak"
        mv "$dest" "$bak"
    fi
    ln -s "$src" "$dest"
    ok "linked $dest"
}
