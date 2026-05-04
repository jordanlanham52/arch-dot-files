#!/usr/bin/env bash
# =============================================================================
#  SHEOL // redeploy-plymouth-theme.sh
#  Sync the latest sheol Plymouth theme from the dotfiles repo to the running
#  system and rebuild initramfs so the new assets are picked up at next boot.
#  Idempotent. Run whenever ply-* assets or sheol.script change.
# =============================================================================

set -euo pipefail

DOTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$DOTS_DIR/pkgs/plymouth/usr/share/plymouth/themes/sheol"
DST="/usr/share/plymouth/themes/sheol"

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

# ---- Pre-flight ------------------------------------------------------------

[ "$EUID" -eq 0 ] && fail "run as your normal user — script will sudo when needed"
sudo -v || fail "need sudo access"

[ -d "$SRC" ] || fail "$SRC not found — run 'git pull' first"
[ -f "$SRC/sheol.plymouth" ] || fail "$SRC/sheol.plymouth missing"
[ -f "$SRC/sheol.script" ]   || fail "$SRC/sheol.script missing"

# Plymouth must be installed for this to work
if ! command -v plymouth-set-default-theme >/dev/null 2>&1; then
    fail "plymouth not installed — run 'sudo pacman -S plymouth' first"
fi

# Verify mkinitcpio has the plymouth hook (otherwise the theme is in the
# filesystem but won't be loaded into initramfs)
if ! grep -qE "^HOOKS=.*\bplymouth\b" /etc/mkinitcpio.conf; then
    warn "plymouth hook not in /etc/mkinitcpio.conf"
    info "  inserting plymouth hook now..."
    if grep -qE "^HOOKS=.*\bsystemd\b" /etc/mkinitcpio.conf; then
        sudo sed -i -E 's/(^HOOKS=\([^)]*\bsystemd\b)/\1 plymouth/' /etc/mkinitcpio.conf
    else
        sudo sed -i -E 's/(^HOOKS=\([^)]*\budev\b)/\1 plymouth/' /etc/mkinitcpio.conf
    fi
    ok "plymouth hook added to /etc/mkinitcpio.conf"
fi

# ---- Deploy theme files ----------------------------------------------------

step "deploying sheol Plymouth theme"

sudo rm -rf "$DST"
sudo mkdir -p "$DST"
sudo cp -r "$SRC"/. "$DST/"
ok "theme files copied to $DST"

# Show what's actually there
ASSET_COUNT=$(find "$DST" -type f | wc -l)
info "  $ASSET_COUNT files deployed"

# ---- Set as default theme --------------------------------------------------

step "setting sheol as default Plymouth theme"

sudo plymouth-set-default-theme sheol >/dev/null 2>&1 || \
    fail "plymouth-set-default-theme failed"

CURRENT=$(plymouth-set-default-theme 2>/dev/null || echo "unknown")
if [ "$CURRENT" = "sheol" ]; then
    ok "default theme: sheol"
else
    warn "expected 'sheol' but got '$CURRENT' — proceeding anyway"
fi

# ---- Rebuild initramfs (REQUIRED — theme is baked into initramfs) ---------

step "rebuilding initramfs (~30 seconds)"
info "  this is required — Plymouth themes load from initramfs, not from /usr"

if sudo mkinitcpio -P 2>&1 | grep -E "Image generation|error|fatal" | tail -10; then
    :
fi

# Sanity-check: confirm the new theme files are inside the new initramfs
INITRAMFS=/boot/initramfs-linux.img
if [ -f "$INITRAMFS" ]; then
    if lsinitcpio "$INITRAMFS" 2>/dev/null | grep -q "plymouth/themes/sheol/sheol.script"; then
        ok "verified: sheol.script present in $INITRAMFS"
    else
        warn "could not verify sheol.script inside initramfs — check 'sudo mkinitcpio -P' output for errors"
    fi
fi

# ---- Done ------------------------------------------------------------------

echo
echo -e "${halo}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
echo -e "${halo}  Plymouth theme redeployed${reset}"
echo -e "${halo}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
echo
echo -e "  ${gilt}♠${reset}  test without rebooting:"
echo -e "      ${gilt}sudo plymouthd${reset}"
echo -e "      ${gilt}sudo plymouth show-splash${reset}   ${linen}# wait a few seconds, take a look${reset}"
echo -e "      ${gilt}sudo plymouth quit${reset}          ${linen}# exit when done${reset}"
echo
echo -e "  ${gilt}♠${reset}  to test the LUKS prompt rendering:"
echo -e "      ${gilt}sudo plymouth ask-for-password --prompt='enter the rite'${reset}"
echo
echo -e "  ${gilt}♠${reset}  to see the real boot sequence: ${gilt}sudo reboot${reset}"
echo
