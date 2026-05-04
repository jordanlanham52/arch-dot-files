#!/usr/bin/env bash
# =============================================================================
#  SHEOL // load-wallpaper.sh
#  Force-loads the wallpaper from your repo's assets/ folder, replacing
#  whatever placeholder is currently at ~/.config/hypr/wallpaper.png.
#  Tells swww to reload it live (no Hyprland restart needed).
# =============================================================================

set -uo pipefail

GILT='\033[38;2;160;130;64m'
HALO='\033[38;2;232;200;112m'
BONE='\033[38;2;184;174;160m'
LINEN='\033[38;2;107;100;112m'
SANCTUS='\033[38;2;90;26;26m'
RESET='\033[0m'

step() { echo -e "${HALO}  ▸${RESET} ${BONE}$1${RESET}"; }
ok()   { echo -e "${GILT}  ✓${RESET} ${BONE}$1${RESET}"; }
warn() { echo -e "${SANCTUS}  ✘${RESET} ${BONE}$1${RESET}"; }
info() { echo -e "${LINEN}    $1${RESET}"; }

echo
echo -e "${GILT}    ♠  wallpaper loader${RESET}"
echo

# Find the dotfiles repo
DOTS=""
for c in "$HOME/sheol-dots" "$HOME/arch-dot-files/sheol-dots" "$HOME/arch-dot-files" "$(pwd)"; do
    if [ -d "$c/assets" ] || [ -d "$c/sheol-dots/assets" ]; then
        if [ -d "$c/assets" ]; then
            DOTS="$c"
        else
            DOTS="$c/sheol-dots"
        fi
        break
    fi
done

[ -z "$DOTS" ] && { warn "no repo with assets/ found"; exit 1; }
step "found repo: $DOTS"

SOURCE="$DOTS/assets/wallpaper.png"
TARGET="$HOME/.config/hypr/wallpaper.png"

# Check the source
if [ ! -f "$SOURCE" ]; then
    warn "no wallpaper at $SOURCE"
    info "  drop your wallpaper there and re-run, or specify a path:"
    info "    bash load-wallpaper.sh /path/to/your/wallpaper.png"
    exit 1
fi

# If user passed a path argument, use that instead
if [ $# -ge 1 ] && [ -f "$1" ]; then
    SOURCE="$1"
    info "using user-specified: $SOURCE"
fi

# Show file info
SIZE=$(stat -c %s "$SOURCE" 2>/dev/null || stat -f %z "$SOURCE" 2>/dev/null || echo 0)
step "source: $SOURCE"
info "  size: $(numfmt --to=iec "$SIZE" 2>/dev/null || echo "$SIZE bytes")"

# Sanity check: is it actually an image?
if command -v file >/dev/null 2>&1; then
    FILETYPE=$(file -b "$SOURCE")
    info "  type: $FILETYPE"
    if ! echo "$FILETYPE" | grep -qiE "image|png|jpeg|jpg"; then
        warn "  doesn't look like an image — continuing anyway"
    fi
fi

# Warn if tiny
if [ "$SIZE" -lt 10000 ]; then
    warn "  file is suspiciously small ($SIZE bytes) — may still be the placeholder"
    echo
    read -r -p "  continue anyway? [y/N] " confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && exit 0
fi
echo

# Copy to ~/.config/hypr/wallpaper.png
step "copying to $TARGET"
mkdir -p "$(dirname "$TARGET")"
cp "$SOURCE" "$TARGET"
ok "copied"
echo

# Tell swww to reload it
if pgrep -x swww-daemon >/dev/null; then
    step "live-reloading via swww"
    if swww img "$TARGET" --transition-type none 2>&1; then
        ok "wallpaper loaded"
    else
        warn "swww reported issues — try restarting swww:"
        info "  pkill swww-daemon; swww-daemon & sleep 1; swww img $TARGET"
    fi
else
    warn "swww-daemon not running"
    info "  starting it"
    swww-daemon &
    sleep 1
    swww img "$TARGET" --transition-type none && ok "wallpaper loaded"
fi
echo

echo -e "${GILT}  ◆${RESET}  ${BONE}done${RESET}"
echo
info "if you don't see the wallpaper, the swww-daemon may have crashed."
info "fix: pkill swww-daemon && swww-daemon & sleep 1 && swww img $TARGET"
echo
