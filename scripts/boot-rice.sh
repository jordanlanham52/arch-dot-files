#!/usr/bin/env bash
# =============================================================================
#  SHEOL // boot-rice.sh
#  Installs Plymouth (boot splash) and optionally GRUB theme.
#  Idempotent. Reversible. Saves backups of every modified file.
# =============================================================================

set -euo pipefail

DOTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$HOME/.cache/sheol-boot-backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# ---- pretty ----------------------------------------------------------------
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

backup() {
    if [ -e "$1" ]; then
        local rel="${1#/}"
        rel="${rel//\//_}"
        sudo cp -a "$1" "$BACKUP_DIR/$rel"
        info "  backed up $1 → $BACKUP_DIR/$rel"
    fi
}

# ---- check root / sudo -----------------------------------------------------
if [ "$EUID" -eq 0 ]; then
    fail "run as your normal user — script will sudo when needed"
fi
sudo -v || fail "need sudo access"

# ---- Pre-flight ------------------------------------------------------------
[ -d "$DOTS_DIR/pkgs/plymouth" ] || fail "plymouth source not found at $DOTS_DIR/pkgs/plymouth"
[ -d "$DOTS_DIR/pkgs/grub"     ] || fail "grub source not found at $DOTS_DIR/pkgs/grub"

# ---- Detect bootloader -----------------------------------------------------
step "detecting bootloader"

BOOTLOADER=""
if [ -f /boot/loader/loader.conf ] || [ -d /boot/loader/entries ]; then
    BOOTLOADER="systemd-boot"
    info "  found: systemd-boot"
elif [ -f /boot/grub/grub.cfg ] || [ -f /etc/default/grub ]; then
    BOOTLOADER="grub"
    info "  found: GRUB"
else
    warn "  unknown bootloader — will install Plymouth only, skip GRUB theme"
fi

# ---- Install Plymouth ------------------------------------------------------
step "installing Plymouth + sheol theme"

if ! command -v plymouth >/dev/null 2>&1; then
    info "  installing plymouth package..."
    sudo pacman -S --noconfirm --needed plymouth
fi

# Copy theme files
sudo mkdir -p /usr/share/plymouth/themes/sheol
sudo cp -r "$DOTS_DIR/pkgs/plymouth/usr/share/plymouth/themes/sheol/." \
           /usr/share/plymouth/themes/sheol/
ok "sheol Plymouth theme deployed to /usr/share/plymouth/themes/sheol/"

# Set as default theme
sudo plymouth-set-default-theme sheol
ok "sheol set as default Plymouth theme"

# ---- Add plymouth hook to mkinitcpio --------------------------------------
step "wiring Plymouth into mkinitcpio"

backup /etc/mkinitcpio.conf

if grep -qE "^HOOKS=.*\bplymouth\b" /etc/mkinitcpio.conf; then
    ok "plymouth hook already present in mkinitcpio.conf"
else
    # Insert plymouth right after 'base udev' (or 'base systemd' for systemd-init)
    if grep -qE "^HOOKS=.*\bsystemd\b" /etc/mkinitcpio.conf; then
        # systemd hooks: base systemd autodetect ...  →  base systemd plymouth autodetect ...
        sudo sed -i -E 's/(^HOOKS=\([^)]*\bsystemd\b)/\1 plymouth/' /etc/mkinitcpio.conf
        ok "added 'plymouth' after 'systemd' in HOOKS"
    else
        # legacy hooks: base udev autodetect ...  →  base udev plymouth autodetect ...
        sudo sed -i -E 's/(^HOOKS=\([^)]*\budev\b)/\1 plymouth/' /etc/mkinitcpio.conf
        ok "added 'plymouth' after 'udev' in HOOKS"
    fi
fi

# Rebuild initramfs
info "  rebuilding initramfs (this takes ~30s)..."
sudo mkinitcpio -P >/dev/null 2>&1
ok "initramfs rebuilt with Plymouth"

# ---- Update kernel cmdline for silent boot --------------------------------
step "configuring silent boot"

KERNEL_PARAMS="quiet splash loglevel=3 rd.systemd.show_status=false rd.udev.log_level=3 vt.global_cursor_default=0"

case "$BOOTLOADER" in
    systemd-boot)
        # Add to each loader entry
        for entry in /boot/loader/entries/*.conf; do
            [ -f "$entry" ] || continue
            backup "$entry"
            if grep -q "^options" "$entry"; then
                # Append params if not already present
                for p in $KERNEL_PARAMS; do
                    if ! grep -q "$p" "$entry"; then
                        sudo sed -i "s|^options |options $p |" "$entry"
                    fi
                done
                ok "updated $(basename "$entry")"
            fi
        done
        ;;
    grub)
        backup /etc/default/grub
        # Update GRUB_CMDLINE_LINUX_DEFAULT
        if ! grep -q "quiet splash" /etc/default/grub; then
            sudo sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$KERNEL_PARAMS\"|" /etc/default/grub
            ok "updated /etc/default/grub kernel cmdline"
        else
            ok "kernel cmdline already silent"
        fi
        ;;
esac

# ---- GRUB theme (optional, only if GRUB is the bootloader) ----------------
if [ "$BOOTLOADER" = "grub" ]; then
    step "installing GRUB sheol theme"

    sudo mkdir -p /usr/share/grub/themes/sheol
    sudo cp -r "$DOTS_DIR/pkgs/grub/usr/share/grub/themes/sheol/." \
               /usr/share/grub/themes/sheol/
    ok "sheol GRUB theme deployed to /usr/share/grub/themes/sheol/"

    # Wire theme into /etc/default/grub
    if ! grep -q "^GRUB_THEME=" /etc/default/grub; then
        echo 'GRUB_THEME="/usr/share/grub/themes/sheol/theme.txt"' | sudo tee -a /etc/default/grub >/dev/null
        ok "GRUB_THEME line added"
    else
        sudo sed -i 's|^GRUB_THEME=.*|GRUB_THEME="/usr/share/grub/themes/sheol/theme.txt"|' /etc/default/grub
        ok "GRUB_THEME line updated"
    fi

    # Set GFX mode for theme to render properly
    if ! grep -q "^GRUB_GFXMODE=" /etc/default/grub; then
        echo 'GRUB_GFXMODE=auto' | sudo tee -a /etc/default/grub >/dev/null
    fi
    if ! grep -q "^GRUB_GFXPAYLOAD_LINUX=" /etc/default/grub; then
        echo 'GRUB_GFXPAYLOAD_LINUX=keep' | sudo tee -a /etc/default/grub >/dev/null
    fi

    info "  regenerating GRUB config..."
    sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1
    ok "GRUB config regenerated with sheol theme"
elif [ "$BOOTLOADER" = "systemd-boot" ]; then
    info "  GRUB theme skipped (bootloader is systemd-boot)"
    info "  to use GRUB instead: see migrate-to-grub.sh"
fi

# ---- Done ------------------------------------------------------------------
echo
echo -e "${halo}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
echo -e "${halo}  boot rice complete${reset}"
echo -e "${halo}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
echo
echo -e "  ${gilt}♠${reset}  reboot to see the new boot sequence"
echo -e "  ${gilt}♠${reset}  backups saved to: ${linen}$BACKUP_DIR${reset}"
echo
echo -e "  ${linen}to test plymouth without rebooting:${reset}"
echo -e "    ${gilt}sudo plymouthd ; sudo plymouth show-splash${reset}"
echo -e "    ${gilt}sudo plymouth quit${reset}   ${linen}# to exit${reset}"
echo
