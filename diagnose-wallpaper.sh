#!/usr/bin/env bash
# =============================================================================
#  SHEOL // diagnose-wallpaper.sh
#  Run this from a terminal INSIDE Hyprland to diagnose and fix the wallpaper.
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
echo -e "${GILT}    ♠  wallpaper diagnostic${RESET}"
echo

# ---- Are we in a Wayland session? -------------------------------------------
step "checking session"
if [ -z "${WAYLAND_DISPLAY:-}" ]; then
    warn "WAYLAND_DISPLAY is not set"
    info "  you're not in a Hyprland session — open a terminal inside Hyprland"
    info "  and run this script from there"
    exit 1
fi
ok "WAYLAND_DISPLAY = $WAYLAND_DISPLAY"
echo

# ---- Does the wallpaper file exist? ----------------------------------------
WALLPAPER="$HOME/.config/hypr/wallpaper.png"
step "checking wallpaper file"
if [ ! -f "$WALLPAPER" ]; then
    warn "no file at $WALLPAPER"
    info "  copy your wallpaper there first"
    exit 1
fi

SIZE=$(stat -c %s "$WALLPAPER" 2>/dev/null)
info "  size: $SIZE bytes ($(numfmt --to=iec "$SIZE" 2>/dev/null || echo "$SIZE B"))"
if [ "$SIZE" -lt 10000 ]; then
    warn "  wallpaper file is too small — it's the placeholder, not your real artwork"
    info "  fix:"
    info "    cp ~/arch-dot-files/sheol-dots/assets/wallpaper.png $WALLPAPER"
    exit 1
fi
ok "wallpaper file looks valid"

if command -v file >/dev/null 2>&1; then
    info "  type: $(file -b "$WALLPAPER")"
fi
echo

# ---- Is awww-daemon running? -----------------------------------------------
step "checking awww-daemon"
if pgrep -x awww-daemon >/dev/null; then
    PID=$(pgrep -x awww-daemon)
    ok "awww-daemon running (pid $PID)"
else
    warn "awww-daemon not running — starting it now"
    awww-daemon > /tmp/awww-daemon.log 2>&1 &
    disown
    sleep 2
    if pgrep -x awww-daemon >/dev/null; then
        ok "awww-daemon started"
    else
        warn "awww-daemon failed to start"
        info "  log:"
        cat /tmp/awww-daemon.log | sed 's/^/    /'
        exit 1
    fi
fi
echo

# ---- Apply the wallpaper ---------------------------------------------------
step "applying wallpaper"
if awww img "$WALLPAPER" --transition-type none 2>&1; then
    ok "wallpaper applied"
else
    warn "awww img failed"
    info "  try: pkill awww-daemon && awww-daemon & sleep 2 && awww img $WALLPAPER"
    exit 1
fi
echo

# ---- Verify by querying awww ------------------------------------------------
step "verifying"
if awww query 2>/dev/null | grep -q "image:"; then
    info "  awww reports:"
    awww query | sed 's/^/    /'
fi
echo

echo -e "${GILT}  ◆${RESET}  ${BONE}done — look at your screen${RESET}"
echo
info "if you still see black, try:"
info "  pkill awww-daemon"
info "  awww-daemon &"
info "  sleep 2"
info "  awww img $WALLPAPER"
echo
