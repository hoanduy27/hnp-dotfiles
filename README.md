# hnp-dotfiles — minimal work profile

Neovim for a company machine. **Plugins only**: no window manager or desktop setup, and nothing
that downloads or builds a program beyond pinned, hash-verified installs. Branch
`work/nvim-company-profile-minimal`.

## What's in it

- **Neovim** — LazyVim-based config in `config/nvim/` (plugins pinned by `lazy-lock.json`):
  no Mason/LSP servers, treesitter parser installs, runtime binary downloads (blink.cmp's matcher is installed by step 25 from a pinned hash), Claude/browser/mermaid plugins, or
  helper-tool downloads (fd/delta); lazygit is the one pinned, sha256-verified exception. The one language server is the OS-packaged Python one (`pylsp`).
- `config/lazygit/config.yml` — lazygit preferences (plain git diffs), linked by step 22.

## Install

```bash
git clone <your-remote> ~/github/hnp-dotfiles
cd ~/github/hnp-dotfiles
git checkout work/nvim-company-profile-minimal
./install.sh               # all steps, or e.g. ./install.sh 20 21 22 23 24 25
```

| Step | Script | What it does |
|------|--------|--------------|
| 20 | `scripts/20-neovim.sh` | pinned Neovim (sha256-verified) → `~/.local/opt`, link `~/.local/bin/nvim` |
| 21 | `scripts/21-nvim-apt.sh` | `apt install python3-pylsp ripgrep` (Python language server, no Mason; `rg` for grep pickers) |
| 22 | `scripts/22-lazygit.sh` | pinned lazygit (sha256-verified) → `~/.local/bin`; links its config (`<leader>gg` in nvim) |
| 23 | `scripts/23-nvim-deploy.sh` | symlink `~/.config/nvim` to repo (backs up old state) |
| 24 | `scripts/24-nvim-bootstrap.sh` | `Lazy! restore` (plugins at lockfile commits) + `health-report.txt` |
| 25 | `scripts/25-blink-cmp.sh` | blink.cmp's Rust fuzzy library, pinned release verified by sha256 (blink never downloads it itself) |

Prerequisites (from apt): `git curl`.

## Editing notes

- Formatting is basic: `=` (indent) and `gq` (reflow). No formatter tools are installed.
- Go-to-definition (`<F12>`, `gpd`) works for Python through `pylsp`; other languages have no server.
- To bump a pinned download, edit the version and sha256 at the top of the script that uses it
  (see the comment there). Plugin bumps go through `:Lazy update`, then review `lazy-lock.json`.
