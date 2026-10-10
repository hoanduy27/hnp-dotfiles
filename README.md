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
| 00 | `scripts/00-packages.sh` | apt packages (bspwm, picom, cava, playerctl, build deps…) |
| 01 | `scripts/01-fonts.sh`    | install bundled Tahoma + Ubuntu Nerd fonts |
| 02 | `scripts/02-eww.sh`      | build eww from source (X11) via cargo → `~/.local/bin/eww` |
| 03 | `scripts/03-deploy.sh`   | symlink `config/*` into `~/.config` (backs up existing) |

Then log out and choose the **bspwm** session (or `bspc wm -r` if already in it).

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
