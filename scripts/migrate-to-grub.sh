#!/usr/bin/env bash
# =============================================================================
#  SHEOL // migrate-to-grub.sh
#  Converts a systemd-boot install to GRUB so the GRUB theme can be applied.
#  Reversible — old systemd-boot config is preserved.
#
#  WARNING: messes with bootloader. Have your Arch install USB available
#  in case something goes wrong. Read the script before running.
# =============================================================================

set -euo pipefail

DOTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$HOME/.cache/sheol-bootloader-migrate/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

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

if ! [ -f /boot/loader/loader.conf ]; then
    fail "this doesn't look like a systemd-boot install — bailing"
fi

# Confirm
echo -e "${sanctus}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
echo -e "${sanctus}  WARNING — bootloader migration${reset}"
echo -e "${sanctus}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
echo
echo "  This will:"
echo "    1. Install GRUB to your ESP"
echo "    2. Copy systemd-boot kernel params into a GRUB config"
echo "    3. Run grub-install + grub-mkconfig"
echo "    4. Leave systemd-boot files in place (reversible)"
echo
echo "  Old systemd-boot config will be at: $BACKUP_DIR"
echo "  Have an Arch USB ready in case something breaks."
echo
read -p "  type YES to continue: " confirm
[ "$confirm" = "YES" ] || { echo "aborted"; exit 0; }

# ---- Detect ESP path -------------------------------------------------------
step "detecting ESP"

ESP_MOUNT=""
for candidate in /boot /boot/efi /efi; do
    if mountpoint -q "$candidate" 2>/dev/null && [ -d "$candidate/EFI" ]; then
        ESP_MOUNT="$candidate"
        info "  ESP mounted at: $ESP_MOUNT"
        break
    fi
done

[ -z "$ESP_MOUNT" ] && fail "couldn't find mounted ESP — abort"

# ---- Backup systemd-boot ---------------------------------------------------
step "backing up current bootloader"

sudo cp -a /boot/loader "$BACKUP_DIR/loader" 2>/dev/null || true
sudo cp -a "$ESP_MOUNT/EFI" "$BACKUP_DIR/EFI" 2>/dev/null || true
ok "backups at $BACKUP_DIR"

# ---- Install GRUB packages -------------------------------------------------
step "installing GRUB packages"
sudo pacman -S --noconfirm --needed grub efibootmgr os-prober
ok "grub + efibootmgr installed"

# ---- Extract kernel cmdline from systemd-boot ------------------------------
step "extracting kernel cmdline from systemd-boot"

DEFAULT_ENTRY=$(awk '/^default/ {print $2}' /boot/loader/loader.conf | head -1)
if [ -z "$DEFAULT_ENTRY" ]; then
    DEFAULT_ENTRY=$(ls /boot/loader/entries/ | grep -v fallback | head -1 | sed 's/\.conf$//')
fi

ENTRY_FILE="/boot/loader/entries/${DEFAULT_ENTRY}.conf"
[ -f "$ENTRY_FILE" ] || ENTRY_FILE=$(ls /boot/loader/entries/*.conf | head -1)

CMDLINE=$(grep "^options" "$ENTRY_FILE" | sed 's/^options //')
ok "extracted cmdline: $CMDLINE"

# ---- Detect root filesystem so we can include the right GRUB modules ------
step "detecting root filesystem and modules needed"

ROOT_DEV=$(findmnt -no SOURCE /)
ROOT_FSTYPE=$(findmnt -no FSTYPE /)
info "  root device: $ROOT_DEV ($ROOT_FSTYPE)"

# Build module list based on filesystem
GRUB_MODULES="part_gpt part_msdos fat"
case "$ROOT_FSTYPE" in
    ext2|ext3|ext4) GRUB_MODULES="$GRUB_MODULES ext2" ;;
    btrfs)          GRUB_MODULES="$GRUB_MODULES btrfs" ;;
    xfs)            GRUB_MODULES="$GRUB_MODULES xfs" ;;
    f2fs)           GRUB_MODULES="$GRUB_MODULES f2fs" ;;
    *)              warn "  unknown root fs '$ROOT_FSTYPE' — include modules manually" ;;
esac

# Detect LUKS
if [[ "$ROOT_DEV" == /dev/mapper/* ]] || cryptsetup status "$ROOT_DEV" &>/dev/null; then
    GRUB_MODULES="$GRUB_MODULES cryptodisk luks luks2 gcry_rijndael gcry_sha256 gcry_sha512"
    info "  LUKS detected — adding crypto modules"
    USING_LUKS=true
else
    USING_LUKS=false
fi

# LVM detection
if [[ "$ROOT_DEV" == /dev/mapper/* ]] && lvs &>/dev/null; then
    GRUB_MODULES="$GRUB_MODULES lvm"
    info "  LVM detected — adding lvm module"
fi

ok "modules: $GRUB_MODULES"

# ---- Install GRUB to ESP ---------------------------------------------------
step "installing GRUB to ESP"

sudo grub-install \
    --target=x86_64-efi \
    --efi-directory="$ESP_MOUNT" \
    --bootloader-id=GRUB \
    --modules="$GRUB_MODULES" \
    --recheck

ok "GRUB installed to ESP with $ROOT_FSTYPE support"

# ---- Configure /etc/default/grub -------------------------------------------
step "writing /etc/default/grub"

sudo tee /etc/default/grub >/dev/null << EOF
# Generated by sheol migrate-to-grub.sh

GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_TIMEOUT_STYLE=menu
GRUB_DISTRIBUTOR="Sheol Arch"
GRUB_CMDLINE_LINUX_DEFAULT="$CMDLINE"
GRUB_CMDLINE_LINUX=""
GRUB_PRELOAD_MODULES="$GRUB_MODULES"
GRUB_TERMINAL_INPUT=console
GRUB_GFXMODE=auto
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_DISABLE_RECOVERY=true
GRUB_DISABLE_OS_PROBER=false
GRUB_THEME="/usr/share/grub/themes/sheol/theme.txt"
$([ "$USING_LUKS" = "true" ] && echo "GRUB_ENABLE_CRYPTODISK=y")
EOF

ok "/etc/default/grub written"

# ---- Generate grub.cfg -----------------------------------------------------
step "generating grub.cfg"

sudo grub-mkconfig -o /boot/grub/grub.cfg
ok "grub.cfg generated"

# ---- Done ------------------------------------------------------------------

echo
echo -e "${halo}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
echo -e "${halo}  migration complete${reset}"
echo -e "${halo}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
echo
echo -e "  ${gilt}♠${reset}  next:"
echo -e "      ${gilt}bash scripts/boot-rice.sh${reset}"
echo -e "      ${linen}# this will install the sheol GRUB theme + Plymouth${reset}"
echo
echo -e "  ${gilt}♠${reset}  reboot when ready. If GRUB doesn't boot:"
echo -e "      ${linen}- boot from Arch USB${reset}"
echo -e "      ${linen}- arch-chroot into your install${reset}"
echo -e "      ${linen}- restore systemd-boot from $BACKUP_DIR${reset}"
echo
