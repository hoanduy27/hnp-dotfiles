#!/usr/bin/env bash
# Step 10 — zsh: oh-my-zsh + starship, deploy modular config, set default shell.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

log "Installing zsh + helpers (sudo)"
sudo apt-get install -y zsh git curl fzf bat || warn "some apt installs failed"

# oh-my-zsh (unattended)
if [ -d "$HOME/.oh-my-zsh" ]; then
    ok "oh-my-zsh present"
else
    log "Installing oh-my-zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# starship
if have starship; then ok "starship present"; else
    log "Installing starship"
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
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
