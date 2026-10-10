# hnp-dotfiles — bspwm + eww

A bspwm desktop with an **eww** status bar, ported from my polybar setup (teal
`#005550` theme, Tahoma + Ubuntu Nerd Font). Keybindings are **identical** to my
main machine (`config/sxhkd/sxhkdrc` is verbatim).

> Branch `dell-ins5570/debian13-bspwm-eww` targets **Debian 13 (Trixie)** on a
> **Dell Inspiron 5570**.

## Layout

The bar is three eww windows mirroring the old polybar bars:

| Window       | Position     | Modules |
|--------------|--------------|---------|
| `bar-left`   | top-left     | notifications · clock · settings · reload · wallpaper · workspaces · window title |
| `bar-right`  | top-right    | backlight · wifi · memory · cpu · filesystem · battery · power |
| `bar-bottom` | bottom-center| bluetooth · volume · cava · now-playing |

## Install (fresh machine)

```bash
git clone <your-remote> ~/github/hnp-dotfiles
cd ~/github/hnp-dotfiles
git checkout dell-ins5570/debian13-bspwm-eww
./install.sh
```

`install.sh` runs four steps (you can run them individually, e.g. `./install.sh 02`):

| Step | Script | What it does |
|------|--------|--------------|
| 00 | `scripts/00-packages.sh` | apt packages — **Xorg + xinit**, bspwm, picom, cava, playerctl, build deps… |
| 01 | `scripts/01-fonts.sh`    | install bundled Tahoma + Ubuntu Nerd fonts |
| 02 | `scripts/02-eww.sh`      | build eww from source (X11) via cargo → `~/.local/bin/eww` |
| 03 | `scripts/03-deploy.sh`   | symlink `config/*` into `~/.config` (backs up existing) |

**Optional onboarding step** (not run automatically — you're prompted for it at
the end of `./install.sh`, or run it explicitly):

| Step | Script | What it does |
|------|--------|--------------|
| 90 | `scripts/90-disable-internal-keyboard.sh` | **permanently** disable the built-in keyboard via GRUB `i8042.nokbd` |

```bash
./install.sh 90                         # disable forever (prompts, needs sudo)
bash scripts/90-disable-internal-keyboard.sh status
bash scripts/90-disable-internal-keyboard.sh enable   # undo
```
It edits `GRUB_CMDLINE_LINUX_DEFAULT` (with a timestamped backup) and runs
`update-grub`, so the internal keyboard is off on every boot while a USB
keyboard keeps working. Takes effect from kernel load — not the BIOS/boot-menu
stage (unplug the ribbon for that). This is the permanent counterpart to the
runtime `config/bspwm/toggle-internal-keyboard.sh`.

### Starting the GUI (from a pure-terminal install)

No display manager is installed by default. After the steps above, launch bspwm
straight from the TTY:

```bash
startx          # reads ~/.xinitrc -> exec bspwm (deployed by step 03)
```

Prefer a graphical login screen? `sudo apt install lightdm` and create a session
file at `/usr/share/xsessions/bspwm.desktop` pointing `Exec=bspwm`. (Given the
internal-keyboard spam, `startx` avoids the greeter entirely.)

If already inside bspwm, reload with `bspc wm -r`.

## Shell (zsh) & editor (nvim)

Added on branch `dell-ins5570/debian13-zsh-nvim` (off the bspwm/eww branch).

**zsh** — oh-my-zsh + starship, split so nothing secret is committed:

| File | Role |
|------|------|
| `config/zsh/zshrc` | portable main rc → symlinked to `~/.zshrc` |
| `config/zsh/aliases.zsh` · `functions.zsh` · `exports.zsh` | portable aliases, k8s/ffmpeg helpers, env |
| `config/zsh/local.zsh.example` | template for **machine-specific paths + secrets** |
| `config/starship.toml` | prompt |

> `~/.config/zsh/local.zsh` is **gitignored**. Step 10 seeds it from the example;
> put your CUDA/gcloud/nvm paths and any credentials (e.g. the `onats` alias)
> there. The committed tree contains **no secrets** (the NATS password is
> redacted in the example).

**nvim** — the LazyVim-based config is vendored from `../olli/nvim_migration`
(`config/nvim/`, `config/lazygit/`, `config/nvim-scripts/mason-install.lua`), so
this repo is self-contained. Install steps are adapted from that project.

Steps:

| Step | Script | What it does |
|------|--------|--------------|
| 10 | `scripts/10-zsh.sh` | zsh + oh-my-zsh + starship; symlink zshrc/zsh dir/starship; seed local.zsh; optional `chsh` |
| 20 | `scripts/20-neovim.sh` | latest stable Neovim → `~/.local/opt`, link `~/.local/bin/nvim` |
| 21 | `scripts/21-nvim-tools.sh` | fd · lazygit · delta · tree-sitter → `~/.local/bin` |
| 22 | `scripts/22-nvim-deploy.sh` | symlink `~/.config/nvim` + lazygit to repo (backs up old state) |
| 23 | `scripts/23-nvim-bootstrap.sh` | `Lazy! sync` + Mason LSP servers + `health-report.txt` |

```bash
./install.sh 10            # just zsh
./install.sh 20 21 22 23   # just neovim
exec zsh                   # pick up the new shell
```

## Repo layout

```
config/
  bspwm/    bspwmrc (launches eww instead of polybar) + helper scripts
  sxhkd/    sxhkdrc  (keybindings — unchanged)
  picom/    compositor
  dunst/    notifications
  eww/      eww.yuck, eww.scss, launch-eww.sh, scripts/ (module backends)
  fonts/    Tahoma + Ubuntu Nerd Font (.ttf)
scripts/    numbered install steps + lib.sh
install.sh  orchestrator
```

## eww module backends (`config/eww/scripts/`)

- `workspaces.sh` — bspwm desktops as JSON (via `bspc subscribe`)
- `window.sh` — focused window title (xtitle if present, else xprop polling)
- `sysinfo.sh` — cpu / mem / fs / battery / backlight / date
- `volume.sh`, `net.sh` — PulseAudio volume, wifi + bluetooth state
- `cava-eww.sh` — audio spectrum (self-contained cava, raw output)
- `nowplaying.sh` — playerctl now-playing stream
- reused from polybar: `bluetooth.sh`, `wifi.sh`, `notification.sh`,
  `powermenu.sh`, `popup-powermenu.sh`, `show-apps.sh`

## Dell Inspiron 5570 notes

- **Internal keyboard spam at boot:** add `i8042.nokbd` to
  `GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub`, then `sudo update-grub`.
  Use an external USB keyboard. (For a hardware-level fix, unplug the keyboard
  ribbon.)
- **Runtime toggle** (optional, no reboot): `config/bspwm/toggle-internal-keyboard.sh`
  disables/enables just the built-in keyboard while keeping a USB one working.
  ```bash
  ~/.config/bspwm/toggle-internal-keyboard.sh disable   # off (xinput, no root)
  ~/.config/bspwm/toggle-internal-keyboard.sh enable
  ~/.config/bspwm/toggle-internal-keyboard.sh status
  ~/.config/bspwm/toggle-internal-keyboard.sh           # toggle
  # kernel-level (survives X restart, needs sudo):
  ~/.config/bspwm/toggle-internal-keyboard.sh --kernel disable
  ```
  Auto-detects `AT Translated Set 2 keyboard`; override with
  `KBD_NAME="..."` if `xinput list` shows a different name. It's a standalone
  tool — bind it to a key yourself if you want (sxhkdrc is left unchanged).
- **Touchpad:** `bspwmrc` remaps a device named `SynPS/2 Synaptics TouchPad`.
  Run `xinput list` and update the name if yours differs.
- **Wi-Fi (QCA9377 / ath10k):** the `cal-pci`/`precal-pci` firmware warnings are
  harmless; the card works with `firmware-atheros` + `board-2.bin`.

## Not auto-installed (optional)

- `betterlockscreen` (super+x, ctrl+shift+Escape) — install from its GitHub repo.
- `xtitle` — nicer window-title source; build from `github.com/baskerville/xtitle`.
- `conky`, `plank`, `ibus` — referenced by bspwmrc; apt step installs them but
  configure to taste.

## Tweaking the bar

- Edit colors/fonts in `config/eww/eww.scss`, layout in `config/eww/eww.yuck`.
- Reload live: `eww reload` (or the  reload button on the left bar).
- Multi-monitor: duplicate the `defwindow` blocks with other `:monitor` indexes,
  or extend `launch-eww.sh`.
