#!/usr/bin/env bash
# =============================================================================
#  SHEOL // redeploy-wallpaper.sh
#  Sync the latest wallpaper from the dotfiles repo to the running system
#  and tell awww to display it. No reboot needed — applies immediately.
# =============================================================================

set -euo pipefail

DOTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$DOTS_DIR/assets/wallpaper.png"
DST="$HOME/.config/hypr/wallpaper.png"

gilt='\033[38;2;201;166;81m'
halo='\033[38;2;232;200;112m'
sanctus='\033[38;2;176;42;42m'
linen='\033[38;2;107;100;112m'
reset='\033[0m'

step() { echo -e "\n${gilt}♠${reset}  ${halo}$*${reset}"; }
ok()   { echo -e "  ${gilt}✓${reset} $*"; }
info() { echo -e "  ${linen}·${reset} $*"; }
warn() { echo -e "  ${sanctus}!${reset} $*"; }
fail() { echo -e "\n${sanctus}✘${reset} $*\n" >&2; exit 1; }

[ -f "$SRC" ] || fail "$SRC not found — run 'git pull' first"

step "deploying wallpaper"
mkdir -p "$(dirname "$DST")"
cp "$SRC" "$DST"
ok "copied to $DST"

# Show its specs
if command -v file >/dev/null 2>&1; then
    info "  $(file -b "$DST" | sed 's/, components.*//')"
fi

# Try to apply immediately via awww (if running)
step "applying via awww"

if ! command -v awww >/dev/null 2>&1; then
    warn "awww not installed — wallpaper will load on next Hyprland session"
    exit 0
fi

# Make sure the daemon is up
if ! awww query >/dev/null 2>&1; then
    info "  awww-daemon not running — starting it"
    awww-daemon &>/dev/null &
    # Wait for it
    for i in {1..20}; do
        sleep 0.25
        awww query >/dev/null 2>&1 && break
    done
fi

if awww query >/dev/null 2>&1; then
    awww img "$DST" --resize fit --fill-color 050507 --transition-type none 2>&1 && \
        ok "wallpaper applied"
else
    warn "awww-daemon couldn't be reached — wallpaper saved but not displayed"
    info "  it'll appear on next Hyprland reload"
fi

echo
echo -e "  ${gilt}♠${reset}  to redeploy on next session: just relog or ${gilt}hyprctl reload${reset}"
echo
