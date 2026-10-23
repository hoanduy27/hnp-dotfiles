#!/usr/bin/env bash
# Step 10 — zsh: oh-my-zsh + starship, deploy modular config, set default shell.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

log "Installing zsh + helpers (sudo)"
sudo apt-get install -y zsh git curl fzf bat || warn "some apt installs failed"

# oh-my-zsh, pinned to a commit (no curl | sh). To bump: pick a commit from
# https://github.com/ohmyzsh/ohmyzsh/commits/master and review it first.
OMZ_COMMIT=2100c630ba4bd67bb48802c3e7da893a4fdaa1a0
if [ -d "$HOME/.oh-my-zsh" ]; then
    ok "oh-my-zsh present"
else
    log "Installing oh-my-zsh @ ${OMZ_COMMIT:0:10}"
    git init -q "$HOME/.oh-my-zsh"
    git -C "$HOME/.oh-my-zsh" remote add origin https://github.com/ohmyzsh/ohmyzsh.git
    git -C "$HOME/.oh-my-zsh" fetch -q --depth 1 origin "$OMZ_COMMIT"
    git -C "$HOME/.oh-my-zsh" checkout -q FETCH_HEAD
fi

# starship, pinned release binary verified by sha256 (no curl | sh)
STARSHIP_VERSION=v1.25.1
STARSHIP_SHA256=c6ddd3ecb9c0071a2ad38d98cee748160066b7c4f197421268058f4a5d6f8504
if have starship; then ok "starship present"; else
    [ "$(uname -m)" = x86_64 ] || die "starship download assumes x86_64 (got $(uname -m))"
    log "Installing starship $STARSHIP_VERSION"
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
    fetch_verified "https://github.com/starship/starship/releases/download/$STARSHIP_VERSION/starship-x86_64-unknown-linux-musl.tar.gz" "$STARSHIP_SHA256" "$tmp/starship.tar.gz"
    tar -xzf "$tmp/starship.tar.gz" -C "$tmp" starship
    mkdir -p "$HOME/.local/bin"
    install -m755 "$tmp/starship" "$HOME/.local/bin/starship"; ok "starship -> $HOME/.local/bin/starship"
fi

# deploy config: ~/.config/zsh -> repo, ~/.zshrc -> repo zshrc, starship.toml
link "$REPO_ROOT/config/zsh"           "$HOME/.config/zsh"
link "$REPO_ROOT/config/zsh/zshrc"     "$HOME/.zshrc"
link "$REPO_ROOT/config/starship.toml" "$HOME/.config/starship.toml"

# seed local.zsh from example (kept out of git)
if [ ! -e "$HOME/.config/zsh/local.zsh" ]; then
    cp "$REPO_ROOT/config/zsh/local.zsh.example" "$HOME/.config/zsh/local.zsh"
    warn "created ~/.config/zsh/local.zsh from template — edit it for this machine's paths/secrets"
fi

# default shell
if [ "${SHELL:-}" != "$(command -v zsh)" ]; then
    if confirm "Set zsh as your default login shell?"; then
        chsh -s "$(command -v zsh)" && ok "default shell set to zsh (re-login to apply)"
    fi
fi
ok "zsh ready — start a new shell:  exec zsh"
