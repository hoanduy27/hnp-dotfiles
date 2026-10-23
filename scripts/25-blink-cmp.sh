#!/usr/bin/env bash
# Step 25 — blink.cmp's Rust fuzzy matcher (completion ranking), pinned and verified by sha256.
# blink.cmp would otherwise download this binary itself at runtime; the work profile turns that
# off (config/nvim/lua/plugins/work.lua) and installs the exact release here instead. The file
# is placed with no `version` marker, so blink uses it as a manually installed library and makes
# no network request.
# To bump: update the plugin in lazy-lock.json, then set BLINK_TAG to its tag, download
# x86_64-unknown-linux-gnu.so from that release once, check its hash against the release page
# (and the .sha256 asset), then paste it into BLINK_SHA256.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

BLINK_TAG=v1.10.2
BLINK_SHA256=1b09e702955be4e2565206d8649db674ccb77477495ed787868f451bf33cea2f

[ "$(uname -m)" = x86_64 ] || die "download URL assumes x86_64 (got $(uname -m))"
plugin="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/blink.cmp"
[ -d "$plugin/.git" ] || die "blink.cmp not installed — run 24-nvim-bootstrap.sh first"

# the library must match the plugin checkout, which lazy-lock.json pins
have_tag="$(git -C "$plugin" describe --tags --exact-match 2>/dev/null || true)"
[ "$have_tag" = "$BLINK_TAG" ] || die "blink.cmp is at '${have_tag:-no tag}', this script is pinned to $BLINK_TAG (update lazy-lock.json / BLINK_TAG)"

dest="$plugin/target/release"
if [ -f "$dest/libblink_cmp_fuzzy.so" ] && [ "$(sha256sum "$dest/libblink_cmp_fuzzy.so" | cut -d' ' -f1)" = "$BLINK_SHA256" ]; then
    ok "blink.cmp fuzzy library already installed and verified"; exit 0
fi

log "Installing blink.cmp fuzzy library $BLINK_TAG"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fetch_verified "https://github.com/saghen/blink.cmp/releases/download/$BLINK_TAG/x86_64-unknown-linux-gnu.so" "$BLINK_SHA256" "$tmp/lib.so"
mkdir -p "$dest"
rm -f "$dest/version"   # no version marker: blink treats the .so as manually placed and never downloads
install -m644 "$tmp/lib.so" "$dest/libblink_cmp_fuzzy.so"
ok "blink.cmp fuzzy library -> $dest/libblink_cmp_fuzzy.so"
