# SHEOL // Changelog

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
