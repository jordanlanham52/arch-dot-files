# SHEOL // Tarnished Reliquary

A custom Hyprland rice for Arch Linux. Fallen Art Deco aesthetic, Ace of Spades brand identity, dual-mode TTY-or-Hyprland boot.

```
    ♠  sheol://  memento ludere
    ─────────────────────────────
    a hyprland rice for the void
```

---

## What this is

A complete dotfiles repo, calibrated to a specific visual brief: **engraved gold ornament on near-black, the Ace of Spades as a sigil, no cool tones anywhere.** Reference images for the design target are in `docs/`.

The rice has these properties:

- **Hyprland** compositor with gradient gold borders, censer-paced animations, sharp 90° corners (zero rounding anywhere).
- **Slim single Waybar** — workspaces in Roman numerals, Roman clock with ◆ flanks, status modules and power button — all in one 32px bar with hairline separators.
- **Hyprlock altarpiece** with Latin liturgical date, Roman-numeral time, double Deco frame, IORDANUS LANHAM nameplate.
- **Rofi** styled as an opened missal.
- **Notifications** as small reliquaries — double-frame card, sharp corners, sanctus border for critical alerts.
- **Terminal palette with no cool tones** — ANSI blue and cyan are remapped to gold and gray, so every CLI tool inherits the aesthetic.
- **Starship prompt** with censer-bracket frames and a TTY fallback that strips Unicode for raw framebuffer compatibility.
- **Dual-mode boot** — defaults to TTY, prompts to launch Hyprland on TTY1, stays clean on TTY2-6.
- **TTY palette** — same Tarnished Reliquary palette applied to the framebuffer console via `setvtrgb`.

---

## Quick start

Two paths depending on where you're starting from.

### Path A — bare metal / blank disk (Arch live ISO)

For new installs. Goes from blank disk to fully riced Hyprland in one pass.

**Requirements:** UEFI firmware, internet (wired or `iwctl` for WiFi), ≥20GB target disk.

```bash
# Boot the Arch live ISO. At root@archiso prompt:
curl -sL https://raw.githubusercontent.com/jordanlanham52/arch-dot-files/main/arch-installer.sh -o /tmp/i.sh
bash /tmp/i.sh
```

The installer will:

1. **Pre-flight** — verify connectivity, sync time, refresh keyring/mirrors
2. **Disk** — let you pick a target, prompt for explicit `WIPE` confirmation, partition + format, optional LUKS encryption (recommended on real hardware)
3. **Base** — pacstrap the Arch base system
4. **Configure** — locale, timezone, hostname, user account, sudo
5. **Bootloader** — systemd-boot
6. **Network** — NetworkManager + dual-mode boot (multi-user.target by default; Hyprland on demand from TTY1)
7. **Hand-off** — at the reboot prompt, optionally enter your fork URL of this repo to auto-clone and run `install.sh` on first login

After reboot, log into TTY1 as your user — the rice install runs automatically (~15 min). Follow the prompts.

### Path B — existing Arch system

If you already have Arch installed and just want the rice on top:

```bash
git clone https://github.com/jordanlanham52/arch-dot-files ~/arch-dot-files
cd ~/arch-dot-files
bash install.sh
```

`install.sh` is idempotent — safe to re-run after edits or on partial failures. It tracks per-package failures and reports them at the end without aborting the rest of the install.

### After either path

Drop your wallpaper at `~/.config/hypr/wallpaper.png` (and optionally `~/.config/hypr/spade.png`). The installer copies whatever is in `assets/wallpaper.png` automatically; if missing, it generates a placeholder so first boot doesn't fail.

Reboot, log into TTY1, follow the `[Y/n] enter Hyprland (5s → tty)` prompt.

### Safety notes

- `arch-installer.sh` asks before wiping. **Twice.** It shows the disk layout and requires you to type `WIPE` literally to proceed. Read what it tells you.
- LUKS encryption is **opt-in** — recommend YES on real hardware, NO on throwaway VMs.
- `install.sh` does not touch system files except for `/etc/locale.gen`, `/etc/locale.conf`, `/etc/vconsole.conf`, and the optional `sheol-tty-palette.service`. It will prompt before each.
- AUR packages are installed via `paru` (auto-installed if missing). Failures there are non-fatal — they're decorative (cursor theme, screenshot tool, logout menu).

---

## Repo structure

```
arch-dot-files/
├── arch-installer.sh             # bare-metal: blank disk → riced system
├── install.sh                    # rice install for existing Arch
├── README.md                     # this file
├── CHANGELOG.md
├── assets/
│   ├── README.md                 # where to drop wallpaper.png + spade.png
│   ├── wallpaper.png             # (you provide)
│   └── spade.png                 # (you provide, optional)
├── pkgs/                         # stow packages — each subdir maps to $HOME
│   ├── hypr/.config/hypr/
│   │   ├── colors.conf           # the master palette — single source of truth
│   │   ├── hyprland.conf
│   │   ├── hyprlock.conf
│   │   └── hypridle.conf
│   ├── waybar/.config/waybar/
│   │   ├── top.jsonc             # top register
│   │   └── style.css
│   ├── rofi/.config/rofi/
│   │   ├── config.rasi
│   │   └── missal.rasi
│   ├── swaync/.config/swaync/
│   │   ├── config.json
│   │   └── style.css
│   ├── starship/.config/
│   │   ├── starship.toml         # GUI prompt
│   │   └── starship-tty.toml     # TTY fallback
│   ├── kitty/.config/kitty/kitty.conf  # primary terminal
│   ├── ghostty/.config/
│   │   ├── ghostty/config        # alternate terminal (real hardware)

│   ├── fastfetch/.config/fastfetch/
│   │   ├── config.jsonc
│   │   └── spade.txt             # ASCII bookplate
│   ├── nvim/.config/nvim/
│   │   ├── init.lua              # minimal entry point
│   │   └── colors/sheol.vim      # full colorscheme — palette-matched
│   └── zsh/
│       ├── .zprofile             # dual-mode boot prompt
│       └── .zshrc
├── scripts/
│   └── roman_clock.py            # Roman numeral time + Latin date helper
└── system/                       # /etc files (require root to install)
    ├── vconsole.conf
    ├── setvtrgb-palette.txt
    ├── sheol-tty-palette.service
    └── greetd-config.toml        # optional, for tuigreet users
```

---

## Manual install (if you don't trust scripts)

### 1. Packages

```bash
# Pacman
sudo pacman -S --needed hyprland hyprlock hypridle hyprpicker hyprpolkitagent \
    xdg-desktop-portal-hyprland \
    waybar rofi-wayland swaync awww \
    kitty zsh starship fastfetch \
    yazi neovim git stow eza bat ripgrep fd duf dust btop fzf \
    pipewire pipewire-pulse wireplumber pavucontrol \
    wl-clipboard cliphist grim slurp brightnessctl playerctl \
    ttf-jetbrains-mono-nerd terminus-font \
    qt5ct qt6ct kvantum nwg-look wlogout python \
    zsh-autosuggestions zsh-syntax-highlighting

# AUR (paru/yay)
paru -S hyprshot ttf-cinzel ttf-cormorant bibata-cursor-theme
```

### 2. Stow

```bash
cd ~/arch-dot-files/pkgs
for pkg in hypr waybar rofi swaync starship kitty ghostty fastfetch zsh nvim; do
    stow -t "$HOME" "$pkg"
done
```

### 3. Wallpaper + scripts

```bash
cp assets/wallpaper.png ~/.config/hypr/wallpaper.png
cp assets/spade.png     ~/.config/hypr/spade.png      # optional
mkdir -p ~/.config/hypr/scripts
cp scripts/roman_clock.py ~/.config/hypr/scripts/
chmod +x ~/.config/hypr/scripts/roman_clock.py
```

### 4. TTY palette (optional but recommended)

```bash
sudo mkdir -p /etc/sheol
sudo cp system/setvtrgb-palette.txt /etc/sheol/
sudo cp system/vconsole.conf /etc/vconsole.conf
sudo cp system/sheol-tty-palette.service /etc/systemd/system/
sudo systemctl enable --now sheol-tty-palette.service
```

### 5. Boot target

```bash
sudo systemctl set-default multi-user.target
chsh -s "$(which zsh)"
```

Reboot. You'll land on TTY1 with the Hyprland launch prompt.

---

## App themes

The rice extends beyond Hyprland into all your daily-driver apps. Every one is themed in the same gold-on-abyss palette.

### Automatically installed by `install.sh`

- **VS Code** — `Sheol Dark` color theme, custom `settings.json`, JetBrainsMono Nerd Font, custom title format (`♠ project · file`). Activate with Cmd+K Cmd+T → Sheol Dark.
- **btop** — `sheol.theme` replacing the neon defaults. Already pre-selected in `btop.conf`.
- **yazi** — full `theme.toml` with sheol palette, custom file-type colors, gold borders.
- **bat** — `Sheol.tmTheme` plus a config that uses it by default. Cache rebuilt during install.
- **tmux** — `.tmux.conf` with sheol-themed status bar matching waybar.
- **lazygit** — `config.yml` with the palette baked in.
- **wlogout** — six-button engraved-card layout. Bound to `Super+M`.

### Activated with one extra step

- **Firefox** — `userChrome.css` is copied to your profile automatically, but Firefox needs a flag toggled. Open `about:config`, search for `toolkit.legacyUserProfileCustomizations.stylesheets`, set to `true`, restart.
- **Discord (Vencord)** — theme file is placed in `~/.config/Vencord/themes/sheol.theme.css`. In Discord: User Settings → Vencord → Themes → enable `sheol`.
- **Obsidian** — theme placed at `pkgs/obsidian/.config/obsidian-theme/Sheol/`. Copy this folder into your vault: `cp -r pkgs/obsidian/.config/obsidian-theme/Sheol <vault>/.obsidian/themes/`. Then in Obsidian: Settings → Appearance → Theme: Sheol.

### Other already-themed components

- **Hyprland, hyprlock, waybar, rofi, swaync, kitty, foot, ghostty, fastfetch, neovim, starship** — themed via the regular dotfile stow.
- **TTY console** — sheol palette via `setvtrgb` and the bundled systemd service.

---



### Changing the palette

Every config sources one of three files derived from the same logical palette:

- `pkgs/hypr/.config/hypr/colors.conf` — Hyprland tokens (`$gilt`, `$tarnish`, etc.)
- `pkgs/waybar/.config/waybar/style.css` — `@define-color` block at top
- `pkgs/rofi/.config/rofi/missal.rasi` — top of file
- `pkgs/swaync/.config/swaync/style.css` — top of file
- `pkgs/kitty/.config/kitty/kitty.conf` — palette at bottom (primary terminal)
- `pkgs/ghostty/.config/ghostty/config` — palette block at bottom (alternate)
- `pkgs/starship/.config/starship.toml` — inline hex values

If you want to swap the palette, change all six. The token names (gilt, tarnish, halo, bone, etc.) are kept identical across files so a global find/replace works.

### Changing your nameplate

In `pkgs/hypr/.config/hypr/hyprlock.conf`, find:

```
text = <span foreground="#a08240">◆</span>  IORDANUS  LANHAM  <span foreground="#a08240">◆</span>
```

Change as desired. Latinized names suit the aesthetic.

### Changing workspace count

Default is 5 (I, II, III, IV, V). To change:

1. `pkgs/hypr/.config/hypr/hyprland.conf` — adjust the `workspace = N` lines and the `bind = $mod, N, workspace, N` keybinds.
2. `pkgs/waybar/.config/waybar/top.jsonc` — `persistent-workspaces` count.

### Time format

The Roman clock script (`scripts/roman_clock.py`) runs in three modes:

- `--time` — `HH : MM` Roman, used by hyprlock and Waybar
- `--date` — `FERIA II · III MAII MMXXVI`, used by hyprlock
- `--bar`  — compact form for narrow bars

If you prefer Arabic numerals in Waybar, edit `top.jsonc` and replace the `custom/clock` module's `exec` with `date '+%H:%M'`.

### Adding more apps to the rice

Apps not handled by this repo but worth theming to match:

- **Firefox** — install [ShyFox](https://github.com/Naezr/ShyFox) or fork [Cascade](https://github.com/cascadefox/cascade), override accents to gilt.
- **Discord** — [Vesktop](https://github.com/Vencord/Vesktop) + custom CSS using the palette.
- **Spotify** — [Spicetify](https://spicetify.app) with the [Sleek](https://github.com/spicetify/spicetify-themes/tree/master/Sleek) theme, recolored.
- **Obsidian** — custom CSS snippet. Tags in gilt, headers in halo, body in bone. Worth doing properly if you keep a serious vault.
- **VS Code / Cursor** — build a theme JSON from the palette.

Each of these takes 30–60 minutes to theme properly. They're not in this repo because they're highly personal and the upstream projects change frequently.

### Switching to Ghostty (alternate terminal)

Kitty is the default. To switch to Ghostty (works on real hardware; crashes in QEMU virtio-gpu):

```bash
# In hyprland.conf, change:
$terminal = ghostty

# Single bar config — already kitty by default in top.jsonc
```

---

## TTY-only mode

The dotfiles repo is designed for both Hyprland and pure-TTY use. On servers, Proxmox nodes, or any machine where you don't want Hyprland, only stow these packages:

```bash
cd ~/arch-dot-files/pkgs
stow -t "$HOME" zsh starship fastfetch
```

Plus the system-level TTY palette setup. You'll get the same shell, prompt, fastfetch, and console palette across every machine.

---

## Common issues

**Hyprland won't start.** Check `~/.local/share/hyprland/hyprland.log`. Most often this is a wallpaper issue — the path `~/.config/hypr/wallpaper.png` must exist or `awww img` will fail. Drop a placeholder if you don't have the wallpaper yet.

**Roman numerals don't render.** Make sure Python 3 is installed and `~/.config/hypr/scripts/roman_clock.py` is executable. Test from terminal: `~/.config/hypr/scripts/roman_clock.py --time`.

**Cinzel / Cormorant fonts not showing.** Install via AUR: `paru -S ttf-cinzel ttf-cormorant`. Or download from Google Fonts and place in `~/.local/share/fonts/`, then run `fc-cache -fv`.

**Bar shows wrong icons.** Make sure `ttf-jetbrains-mono-nerd` is installed and is your terminal's font.

**Hyprlock fails to lock.** Run `hyprlock` from a terminal to see the error. Most often the issue is a missing file referenced in `hyprlock.conf` — comment out the `image { }` block if you don't have `spade.png`.

**TTY palette doesn't apply on first boot.** Try `sudo systemctl restart sheol-tty-palette.service`. The service depends on `systemd-vconsole-setup.service` finishing first.

**Starship prompt is broken in TTY.** It should auto-detect via `$TERM == "linux"` and use the TTY config. If not, force it: `export STARSHIP_CONFIG=~/.config/starship-tty.toml` in your `.zprofile`.

---

## Design philosophy

If you're customizing this beyond cosmetic tweaks, hold these rules:

1. **Sharp corners always.** Zero rounding anywhere. The moment you round, it stops being Deco.
2. **Two accents max per surface.** Gold carries 90% of weight; halo gold appears on ~3 pixels at a time.
3. **No cool tones.** No blues, greens, cyans, purples — the whole world is gold-to-bone-to-black. Even the ANSI palette enforces this.
4. **Hairlines + bold mass.** Tarnish-thin lines beside heavy crypt-black blocks. No medium weights.
5. **Ornament at edges, void at centers.** Frames are dense; window contents stay calm.
6. **Stillness is a tool.** Slow animations, no bounce, no shake. Critical alerts use color, not motion.
7. **Light comes from the ornament itself.** Glows are gold, never white. Drop shadows are warm-black, not gray.

Break any of these and the rice slides into generic dark-mode territory. Hold them and it stays distinct.

---

## Credits

- Wallpaper generated via DALL-E with custom prompt iteration; final image is the user's intellectual property.
- Hyprland by [vaxerski](https://github.com/hyprwm/Hyprland).
- Catppuccin palette tokens were briefly considered before settling on the bespoke Tarnished Reliquary palette.
- Visual references: Klimt, Russian Orthodox iconography, 1925 De La Rue playing cards, Erté, *The Ninth Gate*, Aubrey Beardsley.

---

```
  ♠  memento ludere
  ───────────────────
```
