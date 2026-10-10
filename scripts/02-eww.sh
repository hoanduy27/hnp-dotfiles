#!/usr/bin/env bash
# Step 02 — build & install eww (elkowar's wacky widgets) for X11.
# eww is not packaged in Debian, so we build it from source with cargo.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

BIN="$HOME/.local/bin/eww"
BUILD_DIR="${EWW_BUILD_DIR:-$HOME/.cache/eww-build}"

if have eww; then
    ok "eww already installed: $(command -v eww) ($(eww --version 2>/dev/null | head -1))"
    confirm "Rebuild anyway?" || exit 0
fi

# Ensure a Rust toolchain
if ! have cargo; then
    log "Installing Rust toolchain via rustup"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # shellcheck disable=SC1090
    source "$HOME/.cargo/env"
fi
export PATH="$HOME/.cargo/bin:$PATH"

log "Fetching eww source into $BUILD_DIR"
if [ -d "$BUILD_DIR/.git" ]; then
    git -C "$BUILD_DIR" pull --ff-only
else
    rm -rf "$BUILD_DIR"
    git clone --depth 1 https://github.com/elkowar/eww "$BUILD_DIR"
fi

log "Building eww (X11, release) — this can take 5–15 min"
( cd "$BUILD_DIR" && cargo build --release --no-default-features --features x11 )

mkdir -p "$HOME/.local/bin"
install -m755 "$BUILD_DIR/target/release/eww" "$BIN"
ok "installed $BIN"

case ":$PATH:" in
    *":$HOME/.local/bin:"*) : ;;
    *) warn "add ~/.local/bin to PATH (e.g. in ~/.profile): export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

"$BIN" --version || die "eww did not run"
