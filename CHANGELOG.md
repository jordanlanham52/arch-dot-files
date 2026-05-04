# SHEOL // Changelog

## v6 — 2026-05-04

### Default bootloader switched to GRUB

`arch-installer.sh` now installs **GRUB with the sheol theme + Plymouth splash by default** instead of systemd-boot. The bootloader phase is fully LUKS-aware:

- **GRUB binary** built with `cryptodisk luks luks2 gcry_rijndael gcry_sha256 gcry_sha512` modules when LUKS is detected — fixes the "no cryptodisk module can handle this device" failure mode that bricked the previous migrate-to-grub workflow.
- **`GRUB_ENABLE_CRYPTODISK=y`** added to `/etc/default/grub` for LUKS systems so `grub-mkconfig` emits the right `cryptomount` calls.
- **`grub` and `efibootmgr`** added to the pacstrap package list.
- **Pre-clone of dotfiles repo into `/mnt/root/sheol-dots-temp`** so chroot has access to GRUB and Plymouth theme assets during install. Cleaned up after install.
- **Sheol GRUB theme deployed** to `/usr/share/grub/themes/sheol/` during chroot.
- **Sheol Plymouth theme deployed** to `/usr/share/plymouth/themes/sheol/` and set as default via `plymouth-set-default-theme`. Initramfs rebuilt to include theme.

Result: fresh installs now boot directly into the full sheol experience — themed GRUB menu, sheol Plymouth splash with LUKS unlock prompt, silent kernel boot — from the very first reboot. No `boot-rice.sh` or `migrate-to-grub.sh` needed for new installs.

### Fixed bugs in migration scripts

- **`scripts/migrate-to-grub.sh`** now passes `--modules="cryptodisk luks luks2 gcry_*"` to `grub-install` when LUKS is detected, and writes `GRUB_ENABLE_CRYPTODISK=y` to `/etc/default/grub`. Previous version produced a non-bootable system on LUKS hosts.
- **`scripts/repair-grub.sh`** added — auto-detects root filesystem and LUKS, runs corrected `grub-install` to recover from broken GRUB installs.

## v5 — 2026-05-04

### Boot sequence themed end-to-end

The rice now extends through the entire boot, not just the desktop session.

- **Plymouth splash** (`pkgs/plymouth/`) — script-mode theme with engraved spade fade-in, "MEMENTO LUDERE" subtitle, animated halo progress bar, themed LUKS password prompt with diamond bullets and "✦ enter the rite ✦" label.
- **GRUB theme** (`pkgs/grub/`) — engraved menu with dim spade watermark background (1920x1080), Cinzel Decorative menu entries, "select rite to enter" header, hairline-bordered menu items, gold progress bar for boot countdown.
- **`scripts/boot-rice.sh`** — idempotent installer that detects bootloader (systemd-boot or GRUB), copies Plymouth theme to `/usr/share/plymouth/themes/sheol/`, adds plymouth hook to mkinitcpio, sets silent kernel cmdline, rebuilds initramfs. If GRUB is detected, also installs the GRUB theme. Backups every file modified to `~/.cache/sheol-boot-backups/<timestamp>/`.
- **`scripts/migrate-to-grub.sh`** — for users who want the GRUB theme but currently have systemd-boot. Extracts existing kernel cmdline, installs GRUB to ESP, generates `/etc/default/grub`, regenerates `grub.cfg`. Leaves systemd-boot files in place for fallback.
- **`arch-installer.sh` updates** — fresh installs now include `plymouth` in pacstrap, add the plymouth hook to mkinitcpio HOOKS automatically (both LUKS and non-LUKS paths), and use the full silent-boot kernel cmdline (`quiet splash loglevel=3 rd.systemd.show_status=false rd.udev.log_level=3 vt.global_cursor_default=0`).

The result: power-on → firmware logo → bootloader → black-with-spade → Hyprland. No green-on-black kernel spam, no flash of plain text between phases.

## v4 — 2026-05-03

### App-wide themes added

The rice now extends beyond the compositor into every daily-driver app.

- **VS Code** — `Sheol Dark` color theme as a proper extension (`pkgs/vscode/.local/share/sheol-vscode-theme/`), comprehensive `settings.json` with workbench color overrides, custom keybindings, JetBrainsMono Nerd Font, integrated terminal theming, custom title format with the spade glyph. Auto-installed to `~/.vscode/extensions/` by `install.sh`.
- **wlogout** — Six engraved-card layout (lock, logout, suspend, hibernate, shutdown, reboot) replacing the default purple-on-grey blocks. Bound to `Super+M`. Hover state has the same halo-glow as the active workspace pulse.
- **Obsidian** — Full theme as a proper Obsidian theme folder (`pkgs/obsidian/.config/obsidian-theme/Sheol/`). Headings in Cinzel Decorative, body in Cormorant Garamond, code in JetBrainsMono Nerd Font. All callouts, tables, blockquotes, graph view, search results themed.
- **Firefox** — `userChrome.css` for the browser chrome (title bar, tabs, URL bar, toolbar, sidebar, menus, find bar). Auto-deployed to the default profile. Requires `toolkit.legacyUserProfileCustomizations.stylesheets = true` in `about:config`.
- **Discord (Vencord)** — Full Discord client theme as `sheol.theme.css`. Replaces the Discord blurple with gilt across server list, channels, chat, embeds, settings, modals. BetterDiscord-compatible variant included.
- **btop** — `sheol.theme` file that replaces btop's neon-green/yellow defaults with the gold gradient. CPU graph uses tarnish→gilt→halo.
- **yazi** — Complete `theme.toml` with palette across status bar, mode indicators, file-type colors (gold for executables, leaf for media, sanctus for archives), gold borders.
- **bat** — Custom `Sheol.tmTheme` (TextMate plist format) for the syntax highlighter. Cache automatically rebuilt during install.
- **tmux** — Themed `.tmux.conf` with status bar that matches waybar's aesthetic. Useful when SSH'd into home lab nodes.
- **lazygit** — `config.yml` with sheol palette across active border, selected lines, branch markers.

### Updates

- `install.sh` extended with post-stow theme installation:
  - VS Code extension copied to `~/.vscode/extensions/`
  - bat cache rebuilt
  - Firefox userChrome auto-deployed to default profile
  - Vencord theme dropped in `~/.config/Vencord/themes/`
  - Obsidian theme path printed for manual vault placement
  - Final verification expanded to check all theme files
- New packages added to install.sh package list: `wlogout`, `firefox`, `code`, `tmux`, `lazygit`
- New keybind: `Super+M` opens wlogout
- README updated with full "App themes" section documenting each theme and its activation

## v3 — 2026-05-03

### Fixes (from VM testing through fresh install)

- **Hyprland 0.55+ syntax migration** — windowrule and layerrule rewritten using current `match:` form. `windowrule = float, class:^(foo)$` → `windowrule = match:class ^(foo)$, float on`. Layerrules: `layerrule = blur, rofi` → `layerrule = blur on, match:namespace rofi`. All ~33 windowrules and 8 layerrules converted.
- **Renamed fields** — `idleinhibit` → `idle_inhibit`, `noblur` → `no_blur on`, `noborder` → `no_border on`, `ignorezero` → `ignore_alpha 1`. Empty bare flags now have explicit `on` values.
- **Gestures block removed** — `gestures { workspace_swipe = true ... }` replaced with single top-level `gesture = 3, horizontal, workspace` line (Hyprland 0.54+ syntax).
- **swww → awww rename** — wallpaper daemon was renamed/forked upstream Oct 2025. All `swww-daemon` and `swww img` references updated to `awww-daemon` and `awww img`. install.sh package list updated.
- **Default terminal: kitty** — Ghostty's GPU renderer crashes in QEMU virtio-gpu. Switched `$terminal` and `$fileManager` to kitty. Ghostty config retained for use on real hardware.
- **Single waybar** — bottom.jsonc removed, all modules consolidated into top.jsonc as one slim 32px bar. No more gap between two stacked surfaces.
- **Bar style overhaul** — translucent rgba background, hairline separators between every group, active-workspace pulse animation (4s halo cycle), proper module padding.
- **Window transparency via Hyprland** — `active_opacity = 0.85`, `inactive_opacity = 0.75`. Kitty kept at `background_opacity 1.0` (compositor handles it). Blur disabled to avoid haze; can be re-enabled in `decoration.blur.enabled`.
- **.zprofile no-loop launcher** — Hyprland output redirects to `/tmp/hyprland.log`, drops to shell on exit instead of re-prompting. Eliminates the infinite login loop when Hyprland exits early.
- **Resilient install.sh** — removed `set -e` so one failed package doesn't abort. Per-package install loop with failure tracking. Cinzel + Cormorant fonts pulled directly from Google Fonts GitHub mirror (avoids fonts.google.com rate-limiting and AUR package-name churn).
- **Density-shaded ASCII spade** for fastfetch — uses `#`/`=` two-tone shading to suggest engraved metal. Pure ASCII so it renders correctly in TTY framebuffer console (block-drawing chars from previous version were missing from terminus-font).
- **Locale fix** — install.sh now ensures `en_US.UTF-8` is uncommented in `/etc/locale.gen`, runs `locale-gen`, and writes `LANG=en_US.UTF-8` to `/etc/locale.conf`. Prevents the `setlocale failed` warnings on app launch.
- **Kitty as separate stow package** — moved `kitty.conf` out of the ghostty package directory into its own `pkgs/kitty/`.

### Removed

All transient `fix-*.sh`, `patch-*.sh`, `recover.sh`, `load-wallpaper.sh`, and `diagnose-*.sh` scripts have been deleted. Their corrections are now baked into the canonical config files.

## v2 — 2026-05-03

### Fixes (from external review)

- **Removed accidental literal directory** `pkgs/{hypr,waybar,...}/` left over from a failed bash brace expansion.
- **hyprlock frame** redesigned with absolute pixel sizing (1760×920 outer at 1080p) instead of percentage sizing — gives the deep ~80px inset shown in the mockup. Added scaling notes for 1440p/4K/ultrawide.
- **hyprlock stepped corners** added as composed L-shapes at each corner of the outer frame. Hyprlock's shape widget can't render true ziggurat geometry natively, so this approximates the Deco corner detail visible in the mockup.
- **polkit mismatch resolved**: install script now installs `hyprpolkitagent` (matching the autostart in `hyprland.conf`). Autostart line falls back to `polkit-gnome` if `hyprpolkitagent` isn't running.
- **Wallpaper fallback**: install script now generates a 1920×1080 abyss-black placeholder (`#050507`) if `assets/wallpaper.png` is missing, so first boot doesn't fail with a missing-file error from `swww`. Real wallpaper can be dropped in any time.
- **Neovim colorscheme** added (`pkgs/nvim/.config/nvim/colors/sheol.vim`) — was a visible gap in v1 since the mockups show neovim heavily. Full Treesitter + LSP semantic token coverage. Syntax mapped: keywords in gilt, strings in bone, numbers/types in leaf, comments in tarnish italic, errors in sanctus.

### Known limitations

- **Hyprlock stepped corners** are approximations using small L-shapes. For true pixel-perfect ziggurat steps, render the frame as a transparent PNG overlay in Inkscape and use it as a `background` instead of building from `shape` widgets.
- **Hyprlock sizing is 1080p-tuned**. Calibration table for 1440p/4K/ultrawide is at the bottom of `hyprlock.conf`.
- **Firefox / Discord / Spotify / Obsidian** themes are NOT included — these change too often upstream and are highly personal. README lists what theme to start from for each.
- **Real spade pip image** still required from user. The composition works without it (block is commented-able), but the lockscreen centerpiece is best when present.

## v1 — 2026-05-03

Initial build. Generated from the design conversation:
- Hyprland config with gradient gold borders and censer-paced animations
- Two-register Waybar (top.jsonc + bottom.jsonc) with Roman numeral workspaces
- Hyprlock altarpiece composition
- Rofi missal launcher
- Swaync reliquary notification cards
- Starship prompt with GUI + TTY variants
- Ghostty + Kitty terminal palettes (no cool tones)
- Fastfetch with ASCII spade bookplate
- TTY palette via setvtrgb + systemd service
- Roman clock helper (Python)
- Dual-mode .zprofile boot prompt
- Stow-ready package structure
- Install script for Arch Linux
