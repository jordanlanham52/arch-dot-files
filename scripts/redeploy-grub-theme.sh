#!/usr/bin/env bash
# =============================================================================
#  SHEOL // redeploy-grub-theme.sh
#  Sync the latest sheol GRUB theme from the dotfiles repo to the running
#  system. Use this whenever theme.txt or assets change.
# =============================================================================

set -euo pipefail

DOTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$DOTS_DIR/pkgs/grub/usr/share/grub/themes/sheol"
DST="/usr/share/grub/themes/sheol"

gilt='\033[38;2;201;166;81m'
halo='\033[38;2;232;200;112m'
sanctus='\033[38;2;176;42;42m'
linen='\033[38;2;107;100;112m'
reset='\033[0m'

step() { echo -e "\n${gilt}♠${reset}  ${halo}$*${reset}"; }
ok()   { echo -e "  ${gilt}✓${reset} $*"; }
info() { echo -e "  ${linen}·${reset} $*"; }
fail() { echo -e "\n${sanctus}✘${reset} $*\n" >&2; exit 1; }

[ "$EUID" -eq 0 ] && fail "run as your normal user — script will sudo when needed"
sudo -v || fail "need sudo access"

[ -d "$SRC" ] || fail "$SRC not found — run 'git pull' first"
[ -f "$SRC/theme.txt" ] || fail "$SRC/theme.txt missing"

step "deploying sheol GRUB theme to system"

sudo rm -rf "$DST"
sudo mkdir -p "$DST"
sudo cp -r "$SRC"/. "$DST/"
ok "theme files copied to $DST"

# Make sure /etc/default/grub points to our theme
if grep -q "^GRUB_THEME=" /etc/default/grub 2>/dev/null; then
    sudo sed -i 's|^GRUB_THEME=.*|GRUB_THEME="/usr/share/grub/themes/sheol/theme.txt"|' /etc/default/grub
else
    echo 'GRUB_THEME="/usr/share/grub/themes/sheol/theme.txt"' | sudo tee -a /etc/default/grub >/dev/null
fi
ok "GRUB_THEME set in /etc/default/grub"

# Required for graphical theme rendering
grep -q "^GRUB_GFXMODE=" /etc/default/grub || \
    echo 'GRUB_GFXMODE=auto' | sudo tee -a /etc/default/grub >/dev/null
grep -q "^GRUB_GFXPAYLOAD_LINUX=" /etc/default/grub || \
    echo 'GRUB_GFXPAYLOAD_LINUX=keep' | sudo tee -a /etc/default/grub >/dev/null

step "regenerating grub.cfg"
sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1 && \
    ok "grub.cfg regenerated" || \
    fail "grub-mkconfig failed"

echo
echo -e "${halo}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
echo -e "${halo}  GRUB theme redeployed${reset}"
echo -e "${halo}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
echo
echo -e "  ${gilt}♠${reset}  reboot to see the result"
echo
echo -e "  if any image fails to load, run from GRUB shell (press ${gilt}c${reset} at menu):"
echo -e "    ${linen}set debug=themes${reset}"
echo -e "    ${linen}normal${reset}"
echo
