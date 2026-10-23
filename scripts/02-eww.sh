#!/usr/bin/env bash
# Step 02 — build & install eww (elkowar's wacky widgets) for X11.
# eww is not packaged in Debian, so we build it from source with cargo.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

BIN="$HOME/.local/bin/eww"
BUILD_DIR="${EWW_BUILD_DIR:-$HOME/.cache/eww-build}"

# Everything is pinned: rustup-init (sha256), the Rust toolchain, the eww commit and, via
# `cargo build --locked`, every crate in eww's Cargo.lock.
RUSTUP_VERSION=1.28.2
RUSTUP_INIT_SHA256=20a06e644b0d9bd2fbdbfd52d42540bdde820ea7df86e92e533c073da0cdd43c
RUST_TOOLCHAIN=1.91.0
EWW_COMMIT=48f5aa8b379adf29da0b0bb9ca04164f65d8bdaa

if have eww; then
    ok "eww already installed: $(command -v eww) ($(eww --version 2>/dev/null | head -1))"
    confirm "Rebuild anyway?" || exit 0
fi

# Ensure a Rust toolchain
if ! have cargo; then
    [ "$(uname -m)" = x86_64 ] || die "rustup-init download assumes x86_64 (got $(uname -m))"
    log "Installing Rust $RUST_TOOLCHAIN via rustup-init $RUSTUP_VERSION"
    rtmp="$(mktemp -d)"
    fetch_verified "https://static.rust-lang.org/rustup/archive/$RUSTUP_VERSION/x86_64-unknown-linux-gnu/rustup-init" "$RUSTUP_INIT_SHA256" "$rtmp/rustup-init"
    chmod +x "$rtmp/rustup-init"
    "$rtmp/rustup-init" -y --default-toolchain "$RUST_TOOLCHAIN"
    rm -rf "$rtmp"
    # shellcheck disable=SC1090
    source "$HOME/.cargo/env"
fi
export PATH="$HOME/.cargo/bin:$PATH"

log "Fetching eww source @ ${EWW_COMMIT:0:10} into $BUILD_DIR"
if [ ! -d "$BUILD_DIR/.git" ]; then
    rm -rf "$BUILD_DIR"
    git init -q "$BUILD_DIR"
    git -C "$BUILD_DIR" remote add origin https://github.com/elkowar/eww
fi
git -C "$BUILD_DIR" fetch -q --depth 1 origin "$EWW_COMMIT"
git -C "$BUILD_DIR" checkout -q FETCH_HEAD

log "Building eww (X11, release) — this can take 5–15 min"
# +toolchain only works with rustup's cargo wrappers (not a distro cargo)
toolchain=(); have rustup && toolchain=("+$RUST_TOOLCHAIN")
( cd "$BUILD_DIR" && cargo "${toolchain[@]}" build --locked --release --no-default-features --features x11 )

mkdir -p "$HOME/.local/bin"
install -m755 "$BUILD_DIR/target/release/eww" "$BIN"
ok "installed $BIN"

case ":$PATH:" in
    *":$HOME/.local/bin:"*) : ;;
    *) warn "add ~/.local/bin to PATH (e.g. in ~/.profile): export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

"$BIN" --version || die "eww did not run"
