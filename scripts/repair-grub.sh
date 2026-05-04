#!/usr/bin/env bash
# =============================================================================
#  SHEOL // repair-grub.sh
#  Re-runs grub-install with the correct filesystem modules.
#  Run from arch-chroot if your system won't boot, or from the live system
#  if you can boot but GRUB is broken.
# =============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "run with sudo or as root"
    exit 1
fi

echo ":: detecting root filesystem"
ROOT_DEV=$(findmnt -no SOURCE /)
ROOT_FSTYPE=$(findmnt -no FSTYPE /)
echo "   root: $ROOT_DEV ($ROOT_FSTYPE)"

echo ":: detecting ESP"
ESP_MOUNT=""
for candidate in /boot /boot/efi /efi; do
    if mountpoint -q "$candidate" 2>/dev/null && [ -d "$candidate/EFI" ]; then
        ESP_MOUNT="$candidate"
        break
    fi
done
[ -z "$ESP_MOUNT" ] && { echo "no ESP found — bailing"; exit 1; }
echo "   ESP: $ESP_MOUNT"

echo ":: building module list"
GRUB_MODULES="part_gpt part_msdos fat"
case "$ROOT_FSTYPE" in
    ext2|ext3|ext4) GRUB_MODULES="$GRUB_MODULES ext2" ;;
    btrfs)          GRUB_MODULES="$GRUB_MODULES btrfs" ;;
    xfs)            GRUB_MODULES="$GRUB_MODULES xfs" ;;
    f2fs)           GRUB_MODULES="$GRUB_MODULES f2fs" ;;
esac

if [[ "$ROOT_DEV" == /dev/mapper/* ]] || cryptsetup status "$ROOT_DEV" &>/dev/null; then
    GRUB_MODULES="$GRUB_MODULES cryptodisk luks luks2 gcry_rijndael gcry_sha256 gcry_sha512"
fi

if [[ "$ROOT_DEV" == /dev/mapper/* ]] && lvs &>/dev/null; then
    GRUB_MODULES="$GRUB_MODULES lvm"
fi

echo "   modules: $GRUB_MODULES"

echo ":: re-running grub-install"
grub-install \
    --target=x86_64-efi \
    --efi-directory="$ESP_MOUNT" \
    --bootloader-id=GRUB \
    --modules="$GRUB_MODULES" \
    --recheck

echo ":: regenerating grub.cfg"
grub-mkconfig -o /boot/grub/grub.cfg

echo ""
echo "✓ repaired. Reboot and GRUB should be able to read your root partition."
