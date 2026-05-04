# SHEOL // Changelog

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
