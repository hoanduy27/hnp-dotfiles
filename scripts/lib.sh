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

# Download url -> dest and refuse to continue unless its sha256 matches (pinned installs).
#   fetch_verified <url> <sha256> <dest>
fetch_verified() {
    local url="$1" want="$2" dest="$3" got
    curl -fsSL -o "$dest" "$url" || die "download failed: $url"
    got="$(sha256sum "$dest" | cut -d' ' -f1)"
    [ "$got" = "$want" ] || { rm -f "$dest"; die "sha256 mismatch for $url (want $want, got $got)"; }
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

# Download & install a Nerd Font from the nerd-fonts releases (no sudo).
#   install_nerd_font <ReleaseAssetName> <fc-list match>
#   e.g. install_nerd_font NerdFontsSymbolsOnly "Symbols Nerd Font"
install_nerd_font() {
    local asset="$1" match="$2"
    if fc-list 2>/dev/null | grep -qi "$match"; then ok "$match already installed"; return 0; fi
    local destdir="$HOME/.local/share/fonts/${asset}"
    local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${asset}.tar.xz"
    log "Installing $match (download $asset.tar.xz)"
    local tmp; tmp="$(mktemp -d)"
    if curl -fsSL "$url" | tar -xJ -C "$tmp" 2>/dev/null; then
        mkdir -p "$destdir"
        find "$tmp" \( -name '*.ttf' -o -name '*.otf' \) -exec cp {} "$destdir/" \;
        fc-cache -f "$destdir" >/dev/null 2>&1
        ok "$match -> $destdir"
    else
        warn "failed to download $asset from $url"
    fi
    rm -rf "$tmp"
}
