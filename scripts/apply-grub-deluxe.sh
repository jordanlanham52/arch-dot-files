#!/usr/bin/env bash
# =============================================================================
#  SHEOL // apply-grub-deluxe.sh
#  Switch from the basic sheol GRUB theme to the deluxe variant (or apply for
#  the first time). Idempotent. Reversible by running with --revert.
# =============================================================================

set -euo pipefail

DOTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$HOME/.cache/sheol-grub-deluxe-backups/$(date +%Y%m%d-%H%M%S)"

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

[ "$EUID" -eq 0 ] && fail "run as your normal user — script will sudo when needed"
sudo -v || fail "need sudo access"

# ---- Revert mode ----------------------------------------------------------
if [ "${1:-}" = "--revert" ]; then
    step "reverting to basic sheol GRUB theme"
    if grep -q "sheol-deluxe" /etc/default/grub 2>/dev/null; then
        sudo sed -i 's|sheol-deluxe/theme.txt|sheol/theme.txt|' /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1
        ok "reverted — basic sheol theme active"
    else
        info "  not currently using deluxe theme, nothing to revert"
    fi
    exit 0
fi

# ---- Apply deluxe ---------------------------------------------------------

step "deploying sheol-deluxe GRUB theme"

SRC="$DOTS_DIR/pkgs/grub/usr/share/grub/themes/sheol-deluxe"
[ -d "$SRC" ] || fail "$SRC not found — make sure you pulled the latest dotfiles"

mkdir -p "$BACKUP_DIR"
sudo cp -a /etc/default/grub "$BACKUP_DIR/"
[ -d /usr/share/grub/themes/sheol-deluxe ] && sudo cp -a /usr/share/grub/themes/sheol-deluxe "$BACKUP_DIR/"
ok "backed up current config to $BACKUP_DIR"

sudo mkdir -p /usr/share/grub/themes/sheol-deluxe
sudo cp -r "$SRC"/. /usr/share/grub/themes/sheol-deluxe/
ok "deluxe theme files deployed to /usr/share/grub/themes/sheol-deluxe/"

# Switch GRUB_THEME
if grep -q "^GRUB_THEME=" /etc/default/grub; then
    sudo sed -i 's|^GRUB_THEME=.*|GRUB_THEME="/usr/share/grub/themes/sheol-deluxe/theme.txt"|' /etc/default/grub
    ok "GRUB_THEME updated"
else
    echo 'GRUB_THEME="/usr/share/grub/themes/sheol-deluxe/theme.txt"' | sudo tee -a /etc/default/grub >/dev/null
    ok "GRUB_THEME added"
fi

# Make sure GFX mode is set (theme requires graphical mode)
grep -q "^GRUB_GFXMODE=" /etc/default/grub || \
    echo 'GRUB_GFXMODE=auto' | sudo tee -a /etc/default/grub >/dev/null
grep -q "^GRUB_GFXPAYLOAD_LINUX=" /etc/default/grub || \
    echo 'GRUB_GFXPAYLOAD_LINUX=keep' | sudo tee -a /etc/default/grub >/dev/null

step "regenerating grub.cfg"
sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1 && \
    ok "grub.cfg regenerated" || \
    fail "grub-mkconfig failed — your config may be in a bad state, restore from $BACKUP_DIR"

echo
echo -e "${halo}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
echo -e "${halo}  sheol-deluxe GRUB theme applied${reset}"
echo -e "${halo}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
echo
echo -e "  ${gilt}♠${reset}  reboot to see the new menu"
echo -e "  ${gilt}♠${reset}  to revert: ${gilt}bash $0 --revert${reset}"
echo -e "  ${gilt}♠${reset}  backup at: ${linen}$BACKUP_DIR${reset}"
echo
