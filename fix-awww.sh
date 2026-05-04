#!/usr/bin/env bash
# =============================================================================
#  SHEOL // fix-awww.sh
#  swww was renamed to awww upstream (Oct 2025). Updates all references
#  throughout the rice config + scripts, then loads the wallpaper.
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
echo -e "${GILT}    ♠  swww → awww migration${RESET}"
echo

# Verify awww exists
if ! command -v awww >/dev/null 2>&1; then
    warn "awww not found in PATH"
    info "  install with: sudo pacman -S awww"
    exit 1
fi
if ! command -v awww-daemon >/dev/null 2>&1; then
    warn "awww-daemon not found in PATH"
    info "  install with: sudo pacman -S awww"
    exit 1
fi

ok "awww + awww-daemon present"
echo

# Find the dotfiles repo
DOTS=""
for c in "$HOME/sheol-dots" "$HOME/arch-dot-files/sheol-dots" "$HOME/arch-dot-files" "$(pwd)"; do
    if [ -f "$c/pkgs/hypr/.config/hypr/hyprland.conf" ]; then
        DOTS="$c"; break
    fi
done

[ -z "$DOTS" ] && { warn "no repo found"; exit 1; }
step "found repo: $DOTS"
echo

# ---- Patch hyprland.conf ----------------------------------------------------
HYPR="$DOTS/pkgs/hypr/.config/hypr/hyprland.conf"
step "patching hyprland.conf"
cp "$HYPR" "$HYPR.bak.$(date +%s)"

# Replace swww-daemon → awww-daemon and swww img → awww img
# Order matters: swww-daemon first so it doesn't get partially replaced
sed -i \
    -e 's/\bswww-daemon\b/awww-daemon/g' \
    -e 's/\bswww img\b/awww img/g' \
    -e 's/\bswww\b/awww/g' \
    "$HYPR"

ok "hyprland.conf patched"
info "  changes:"
grep -E "^(exec-once|exec).*awww" "$HYPR" | sed 's/^/    /' || info "  (none found — may already be patched)"
echo

# ---- Patch load-wallpaper.sh if present -------------------------------------
LOADER="$DOTS/load-wallpaper.sh"
if [ -f "$LOADER" ]; then
    step "patching load-wallpaper.sh"
    cp "$LOADER" "$LOADER.bak.$(date +%s)"
    sed -i \
        -e 's/\bswww-daemon\b/awww-daemon/g' \
        -e 's/\bswww img\b/awww img/g' \
        -e 's/\bswww\b/awww/g' \
        "$LOADER"
    ok "load-wallpaper.sh patched"
fi

# ---- Patch install.sh if present --------------------------------------------
INSTALL="$DOTS/install.sh"
if [ -f "$INSTALL" ]; then
    step "patching install.sh"
    cp "$INSTALL" "$INSTALL.bak.$(date +%s)"
    sed -i \
        -e 's/\bswww-daemon\b/awww-daemon/g' \
        -e 's/\bswww img\b/awww img/g' \
        -e 's/\bswww\b/awww/g' \
        "$INSTALL"
    ok "install.sh patched"
fi
echo

# ---- Kill any old swww-daemon processes -------------------------------------
step "stopping any orphan daemons"
pkill -x swww-daemon 2>/dev/null && info "  killed swww-daemon" || true
pkill -x awww-daemon 2>/dev/null && info "  killed awww-daemon" || true
sleep 1
echo

# ---- Start awww-daemon and load wallpaper -----------------------------------
step "starting awww-daemon"
awww-daemon &
DAEMON_PID=$!
disown
sleep 2

# Verify it's running
if kill -0 "$DAEMON_PID" 2>/dev/null; then
    ok "awww-daemon running (pid $DAEMON_PID)"
else
    warn "awww-daemon failed to stay running"
    info "  try manually: awww-daemon &"
    info "  if it errors, check: awww-daemon 2>&1"
    exit 1
fi
echo

# ---- Load the wallpaper -----------------------------------------------------
WALLPAPER="$HOME/.config/hypr/wallpaper.png"
if [ ! -f "$WALLPAPER" ]; then
    warn "no wallpaper at $WALLPAPER"
    info "  run load-wallpaper.sh first to copy from assets/"
    exit 1
fi

step "loading wallpaper: $WALLPAPER"
if awww img "$WALLPAPER" --transition-type none 2>&1; then
    ok "wallpaper loaded"
else
    warn "awww img reported an issue"
    info "  diagnostics:"
    info "  - daemon status: $(pgrep -x awww-daemon >/dev/null && echo running || echo dead)"
    info "  - try: awww img $WALLPAPER 2>&1"
fi
echo

# ---- Reload Hyprland to pick up the new exec-once ---------------------------
if pgrep -x Hyprland >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    step "reloading Hyprland"
    hyprctl reload >/dev/null 2>&1 && ok "reloaded"
fi
echo

echo -e "${GILT}  ◆${RESET}  ${BONE}done${RESET}"
echo
info "the wallpaper should now be visible."
info ""
info "commit:"
info "  cd $DOTS && git add -A && git commit -m 'rename: swww → awww' && git push"
echo
