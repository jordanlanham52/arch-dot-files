#!/usr/bin/env bash
# =============================================================================
#  SHEOL // arch-installer.sh
#  Run this from the Arch live ISO. Goes from blank disk to fully riced
#  Hyprland system in one pass.
#
#  Usage:
#    Boot the Arch ISO. Once at root@archiso prompt:
#
#      curl -sL https://YOUR-URL/arch-installer.sh -o /tmp/i.sh
#      bash /tmp/i.sh
#
#    (Or transfer it however else — see "Getting the script in" notes below.)
#
#  What it does:
#    Phase 1 — Pre-flight: connectivity, time, keyring, mirrors
#    Phase 2 — Disk: select + confirm, partition, optional LUKS, format, mount
#    Phase 3 — Base system install via pacstrap
#    Phase 4 — Configure: locale, timezone, hostname, user, sudo
#    Phase 5 — Bootloader (GRUB with sheol theme + Plymouth splash)
#    Phase 6 — Network + dual-mode (multi-user.target by default)
#    Phase 7 — Reboot prompt; on first user login, optionally clone & install
#               the sheol-dots rice automatically
#
#  Requirements:
#    - UEFI firmware (we don't do BIOS — fix it in the VM/firmware settings)
#    - Internet (wired auto-works in VMs; WiFi requires manual iwctl first)
#    - At least 20GB target disk
#
#  Safety:
#    - Asks before wiping. Twice.
#    - Shows you the disk layout and prompts for explicit "WIPE" confirmation.
#    - LUKS is optional — recommend YES on real hardware, NO on throwaway VMs
# =============================================================================

set -uo pipefail

# ---- Aesthetic --------------------------------------------------------------
GILT='\033[38;2;160;130;64m'
HALO='\033[38;2;232;200;112m'
BONE='\033[38;2;184;174;160m'
LINEN='\033[38;2;107;100;112m'
SANCTUS='\033[38;2;90;26;26m'
RESET='\033[0m'

banner() {
    clear
    echo
    echo -e "${GILT}    ♠  SHEOL${RESET}  ${LINEN}// arch installer${RESET}"
    echo -e "${LINEN}    ─────────────────────────────${RESET}"
    echo -e "${LINEN}    blank disk to riced Hyprland in one pass${RESET}"
    echo
}

step()    { echo -e "${HALO}  ▸${RESET} ${BONE}$1${RESET}"; }
ok()      { echo -e "${GILT}  ✓${RESET} ${BONE}$1${RESET}"; }
warn()    { echo -e "${SANCTUS}  ✘${RESET} ${BONE}$1${RESET}"; }
info()    { echo -e "${LINEN}    $1${RESET}"; }
section() {
    echo
    echo -e "${GILT}    ─── $1 ───${RESET}"
    echo
}

ask() {
    local prompt="$1"
    local default="${2:-}"
    local reply
    if [ -n "$default" ]; then
        echo -ne "${HALO}  ?${RESET} ${BONE}$prompt${RESET} ${LINEN}[$default]${RESET}: " >&2
    else
        echo -ne "${HALO}  ?${RESET} ${BONE}$prompt${RESET}: " >&2
    fi
    read -r reply </dev/tty
    echo "${reply:-$default}"
}

ask_yn() {
    local prompt="$1"
    local default="${2:-Y}"
    local reply
    local hint
    if [ "$default" = "Y" ]; then hint="[Y/n]"; else hint="[y/N]"; fi
    echo -ne "${HALO}  ?${RESET} ${BONE}$prompt${RESET} ${LINEN}$hint${RESET}: "
    read -r reply </dev/tty
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[Yy] ]]
}

die() {
    warn "$1"
    exit 1
}

# =============================================================================
#  PHASE 1 — Pre-flight checks
# =============================================================================
phase_preflight() {
    section "PHASE 1 — pre-flight"

    # Must be root (we are, on the live ISO)
    if [[ $EUID -ne 0 ]]; then
        die "must run as root (you're on the live ISO, you should be already)"
    fi

    # Must be UEFI
    if [ ! -d /sys/firmware/efi ]; then
        die "system is not booted in UEFI mode. fix firmware settings."
    fi
    ok "UEFI mode confirmed"

    # Network
    step "checking connectivity"
    if ping -c 1 -W 3 archlinux.org >/dev/null 2>&1; then
        ok "network up"
    else
        warn "no internet. if WiFi: run 'iwctl' to connect, then re-run this script"
        die "abort"
    fi

    # NTP
    step "syncing time"
    timedatectl set-ntp true >/dev/null 2>&1
    ok "NTP enabled"

    # Keyring (avoids signature errors during pacstrap)
    step "refreshing keyring"
    pacman -Sy --noconfirm archlinux-keyring >/dev/null 2>&1 || \
        warn "keyring refresh had warnings — usually fine"
    ok "keyring up to date"

    # Mirrors
    step "ranking mirrors (this takes ~30s)"
    if command -v reflector >/dev/null 2>&1; then
        local country
        country=$(ask "country for mirror selection" "United States")
        reflector --country "$country" --age 12 --protocol https \
            --sort rate --save /etc/pacman.d/mirrorlist >/dev/null 2>&1 || \
            warn "reflector had warnings (some mirrors slow) — that's normal"
        ok "mirrors ranked"
    fi
}

# =============================================================================
#  PHASE 2 — Disk selection + partitioning
# =============================================================================
phase_disk() {
    section "PHASE 2 — disk"

    step "available disks:"
    echo
    lsblk -d -o NAME,SIZE,TYPE,MODEL | grep -v "loop\|rom"
    echo

    local disk
    disk=$(ask "target disk (e.g. sda, vda, nvme0n1)" "")
    [ -z "$disk" ] && die "no disk specified"

    DISK="/dev/$disk"
    if [ ! -b "$DISK" ]; then
        die "$DISK is not a block device"
    fi

    # Show what's there now
    echo
    info "current contents of $DISK:"
    lsblk "$DISK"
    echo

    if ! ask_yn "WIPE $DISK and continue? this is destructive" "N"; then
        die "aborted by user"
    fi

    # Detect partition naming (sda1 vs nvme0n1p1)
    if [[ "$disk" =~ nvme|mmcblk ]]; then
        PART_PREFIX="${DISK}p"
    else
        PART_PREFIX="${DISK}"
    fi

    EFI_PART="${PART_PREFIX}1"
    ROOT_PART="${PART_PREFIX}2"

    # LUKS choice
    USE_LUKS=false
    if ask_yn "use full-disk encryption (LUKS2)? recommended on real hardware" "Y"; then
        USE_LUKS=true
        info "you'll be prompted for a passphrase shortly"
    else
        info "skipping encryption — fine for VMs"
    fi

    # Confirm one more time
    echo
    warn "ABOUT TO WIPE:    $DISK"
    info "  EFI partition:  $EFI_PART (1G)"
    info "  Root partition: $ROOT_PART (rest)"
    info "  LUKS:           $($USE_LUKS && echo yes || echo no)"
    echo

    local confirm
    echo -ne "${SANCTUS}  type 'WIPE' to proceed: ${RESET}"
    read -r confirm </dev/tty
    [ "$confirm" = "WIPE" ] || die "didn't get confirmation, aborting"

    # Wipe + partition
    step "wiping existing partition table"
    wipefs -a "$DISK" >/dev/null 2>&1
    sgdisk -Z "$DISK" >/dev/null 2>&1
    ok "wiped"

    step "partitioning"
    sgdisk -n 1:0:+1G -t 1:ef00 -c 1:EFI "$DISK" >/dev/null 2>&1
    sgdisk -n 2:0:0   -t 2:8300 -c 2:root "$DISK" >/dev/null 2>&1
    partprobe "$DISK"
    sleep 1
    ok "partitions created"

    # LUKS
    if $USE_LUKS; then
        step "encrypting root partition (you'll be prompted for passphrase)"
        echo
        info "use a strong passphrase. WRITE IT DOWN until memorized."
        info "type 'YES' (uppercase) when prompted, then your passphrase twice"
        echo
        cryptsetup luksFormat --type luks2 "$ROOT_PART" || \
            die "LUKS format failed"

        step "opening encrypted volume"
        cryptsetup open "$ROOT_PART" cryptroot || \
            die "LUKS open failed"

        ROOT_DEVICE=/dev/mapper/cryptroot
        LUKS_UUID=$(blkid -s UUID -o value "$ROOT_PART")
        ok "LUKS volume opened, UUID=$LUKS_UUID"
    else
        ROOT_DEVICE="$ROOT_PART"
        LUKS_UUID=""
    fi

    # Format
    step "formatting EFI as FAT32"
    mkfs.fat -F32 -n EFI "$EFI_PART" >/dev/null 2>&1
    ok "EFI formatted"

    step "formatting root as ext4"
    mkfs.ext4 -L root -F "$ROOT_DEVICE" >/dev/null 2>&1
    ok "root formatted"

    # Mount
    step "mounting"
    mount "$ROOT_DEVICE" /mnt
    mount --mkdir "$EFI_PART" /mnt/boot
    ok "mounted"
}

# =============================================================================
#  PHASE 3 — Base system install
# =============================================================================
phase_pacstrap() {
    section "PHASE 3 — base system"

    # Detect CPU vendor for microcode
    local microcode=""
    local vendor
    vendor=$(lscpu | grep -i "vendor id" | awk '{print $NF}')
    if [[ "$vendor" =~ Intel ]]; then
        microcode="intel-ucode"
    elif [[ "$vendor" =~ AMD ]]; then
        microcode="amd-ucode"
    else
        info "unknown CPU vendor ($vendor) — skipping microcode"
    fi

    info "CPU: $vendor → $microcode"
    echo

    step "pacstrap (downloads ~700MB, takes 5-15 min)"
    pacstrap -K /mnt \
        base base-devel linux linux-firmware linux-headers \
        $microcode \
        networkmanager \
        cryptsetup \
        sudo zsh git vim nano \
        terminus-font \
        plymouth \
        grub efibootmgr \
        man-db man-pages texinfo \
        || die "pacstrap failed"
    ok "base system installed"

    step "generating fstab"
    genfstab -U /mnt > /mnt/etc/fstab
    ok "fstab written"

    # Pre-clone dotfiles repo into /mnt so chroot has theme assets available.
    # If user didn't provide a repo URL, themes are skipped (chroot falls back
    # to default Plymouth and unthemed GRUB — still functional, just plain).
    if [ -n "$SHEOL_REPO" ]; then
        step "pre-cloning sheol-dots into /mnt for boot themes"
        if git clone --depth 1 "$SHEOL_REPO" /mnt/root/sheol-dots-temp 2>/dev/null; then
            ok "dotfiles cloned (theme assets available to chroot)"
        else
            warn "couldn't clone dotfiles — boot will be plain (you can apply themes after first boot via boot-rice.sh)"
        fi
    fi

    # Stash variables for the chroot phase
    cat > /mnt/root/.sheol-install-env <<EOF
USE_LUKS=$USE_LUKS
LUKS_UUID=$LUKS_UUID
ROOT_DEVICE=$ROOT_DEVICE
ROOT_PART=$ROOT_PART
EFI_PART=$EFI_PART
DISK=$DISK
MICROCODE=$microcode
HOSTNAME=$HOSTNAME_VAL
USERNAME=$USERNAME_VAL
TIMEZONE=$TIMEZONE_VAL
INSTALL_RICE=$INSTALL_RICE
SHEOL_REPO=$SHEOL_REPO
EOF
}

# =============================================================================
#  PHASE 4 + 5 — Configure system + bootloader (runs inside chroot)
# =============================================================================
write_chroot_script() {
    cat > /mnt/root/configure.sh << 'CHROOT_EOF'
#!/usr/bin/env bash
set -uo pipefail
source /root/.sheol-install-env

echo "  ▸ time + locale"
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen >/dev/null
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "  ▸ hostname"
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

echo "  ▸ console font"
cat > /etc/vconsole.conf <<EOF
KEYMAP=us
FONT=ter-v22b
EOF

if [ "$USE_LUKS" = "true" ]; then
    echo "  ▸ configuring mkinitcpio for LUKS + Plymouth"
    sed -i 's|^HOOKS=.*|HOOKS=(base systemd plymouth autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)|' /etc/mkinitcpio.conf
else
    echo "  ▸ adding Plymouth hook to mkinitcpio"
    sed -i -E 's/(^HOOKS=\([^)]*\bsystemd\b)/\1 plymouth/' /etc/mkinitcpio.conf
fi

echo "  ▸ regenerating initramfs"
mkinitcpio -P >/dev/null 2>&1

echo "  ▸ creating user $USERNAME (you'll be prompted for passwords)"
echo
echo "    First: ROOT password"
passwd

echo
echo "    Then: $USERNAME password"
useradd -m -G wheel,video,audio,input,storage -s /bin/zsh "$USERNAME"
passwd "$USERNAME"

echo "  ▸ enabling sudo for wheel group"
sed -i 's|^# %wheel ALL=(ALL:ALL) ALL$|%wheel ALL=(ALL:ALL) ALL|' /etc/sudoers

echo "  ▸ installing GRUB bootloader (sheol-themed)"

# Build module list — must include LUKS modules if encrypted, fs module for /
GRUB_MODULES="part_gpt part_msdos fat ext2"
if [ "$USE_LUKS" = "true" ]; then
    GRUB_MODULES="$GRUB_MODULES cryptodisk luks luks2 gcry_rijndael gcry_sha256 gcry_sha512"
    echo "  ▸ LUKS detected — including crypto modules in GRUB binary"
fi

# Install GRUB to ESP with all needed modules baked in
grub-install \
    --target=x86_64-efi \
    --efi-directory=/boot \
    --bootloader-id=GRUB \
    --modules="$GRUB_MODULES" \
    --recheck >/dev/null 2>&1 || { echo "  ✘ grub-install failed"; exit 1; }

# Build kernel cmdline (silent boot + Plymouth)
KERNEL_PARAMS="quiet splash loglevel=3 rd.systemd.show_status=false rd.udev.log_level=3 vt.global_cursor_default=0"

if [ "$USE_LUKS" = "true" ]; then
    GRUB_CMDLINE="rd.luks.name=${LUKS_UUID}=cryptroot root=/dev/mapper/cryptroot rw $KERNEL_PARAMS"
else
    ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PART")
    GRUB_CMDLINE="root=UUID=${ROOT_UUID} rw $KERNEL_PARAMS"
fi

# Install sheol GRUB theme if dotfiles were pre-cloned
SHEOL_GRUB_SRC="/root/sheol-dots-temp/pkgs/grub/usr/share/grub/themes/sheol"
GRUB_THEME_LINE=""
if [ -d "$SHEOL_GRUB_SRC" ]; then
    mkdir -p /usr/share/grub/themes/sheol
    cp -r "$SHEOL_GRUB_SRC"/. /usr/share/grub/themes/sheol/
    GRUB_THEME_LINE='GRUB_THEME="/usr/share/grub/themes/sheol/theme.txt"'
    echo "  ▸ sheol GRUB theme deployed"
fi

# Write /etc/default/grub
cat > /etc/default/grub <<GRUBCONF
# Generated by sheol arch-installer.sh

GRUB_DEFAULT=0
GRUB_TIMEOUT=3
GRUB_TIMEOUT_STYLE=menu
GRUB_DISTRIBUTOR="Sheol Arch"
GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE"
GRUB_CMDLINE_LINUX=""
GRUB_PRELOAD_MODULES="$GRUB_MODULES"
GRUB_TERMINAL_INPUT=console
GRUB_GFXMODE=auto
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_DISABLE_RECOVERY=true
GRUB_DISABLE_OS_PROBER=false
$GRUB_THEME_LINE
GRUBCONF

# Critical for LUKS: tell grub-mkconfig to emit cryptomount calls
if [ "$USE_LUKS" = "true" ]; then
    echo 'GRUB_ENABLE_CRYPTODISK=y' >> /etc/default/grub
fi

# Generate grub.cfg
echo "  ▸ generating grub.cfg"
grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1 || { echo "  ✘ grub-mkconfig failed"; exit 1; }

# ---- Install Plymouth sheol theme (boot splash) -------------------------
SHEOL_PLY_SRC="/root/sheol-dots-temp/pkgs/plymouth/usr/share/plymouth/themes/sheol"
if [ -d "$SHEOL_PLY_SRC" ]; then
    echo "  ▸ installing sheol Plymouth theme"
    mkdir -p /usr/share/plymouth/themes/sheol
    cp -r "$SHEOL_PLY_SRC"/. /usr/share/plymouth/themes/sheol/
    plymouth-set-default-theme sheol >/dev/null 2>&1 || true
    # Rebuild initramfs to pick up new theme
    mkinitcpio -P >/dev/null 2>&1
    echo "  ▸ sheol splash will appear on next boot"
fi

# Clean up the pre-cloned temp copy — install.sh will clone the real one to ~/
[ -d /root/sheol-dots-temp ] && rm -rf /root/sheol-dots-temp

echo "  ▸ enabling NetworkManager + fstrim"
systemctl enable NetworkManager >/dev/null 2>&1
systemctl enable fstrim.timer >/dev/null 2>&1

echo "  ▸ setting boot target to multi-user (TTY-by-default)"
systemctl set-default multi-user.target >/dev/null 2>&1

# Stash sheol-dots auto-install for first user login
if [ "$INSTALL_RICE" = "true" ]; then
    USER_HOME="/home/$USERNAME"
    # Write firstrun script: substitute $USERNAME and $SHEOL_REPO at write-time,
    # then quote-protect the rest so configure.sh's `set -u` doesn't blow up
    # on lines like `$1` or runtime vars.
    cat > "$USER_HOME/.sheol-firstrun.sh" <<FIRSTRUN_EOF
#!/usr/bin/env bash
# Auto-runs once on first login as $USERNAME, then deletes itself.
# Installs the rice end-to-end.
SHEOL_REPO="$SHEOL_REPO"
FIRSTRUN_EOF

    # Append the rest with a QUOTED delimiter so nothing expands at all
    cat >> "$USER_HOME/.sheol-firstrun.sh" <<'FIRSTRUN_BODY'

cd ~

echo
echo "  spade  installing rice on first login"
echo

# AUR helper
if ! command -v paru >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    (cd /tmp/paru && makepkg -si --noconfirm)
fi

# Clone the rice repo (URL was set via env above)
if [ -n "$SHEOL_REPO" ] && [ ! -d ~/arch-dot-files ]; then
    git clone "$SHEOL_REPO" ~/arch-dot-files
fi

# Run install.sh if present
if [ -d ~/arch-dot-files ] && [ -f ~/arch-dot-files/install.sh ]; then
    cd ~/arch-dot-files
    bash install.sh
fi

# Self-destruct
rm -f ~/.sheol-firstrun.sh
sed -i '/sheol-firstrun/d' ~/.zprofile 2>/dev/null
FIRSTRUN_BODY

    chmod +x "$USER_HOME/.sheol-firstrun.sh"
    chown "$USERNAME:$USERNAME" "$USER_HOME/.sheol-firstrun.sh"

    # Hook into .zprofile so it runs on first login.
    # QUOTED delimiter — nothing in the body expands.
    # DIFFERENT delimiter name from any other heredoc nearby.
    cat >> "$USER_HOME/.zprofile" <<'ZPROFILE_HOOK_EOF'

# Sheol first-run hook (auto-deletes after running)
if [ -f ~/.sheol-firstrun.sh ]; then
    bash ~/.sheol-firstrun.sh
fi
ZPROFILE_HOOK_EOF
    chown "$USERNAME:$USERNAME" "$USER_HOME/.zprofile"
fi

echo "  ✓ system configured"
CHROOT_EOF

    chmod +x /mnt/root/configure.sh
}

phase_chroot() {
    section "PHASE 4-5 — configure system + bootloader"

    write_chroot_script
    arch-chroot /mnt /root/configure.sh || \
        die "chroot configuration failed"

    # Clean up
    rm -f /mnt/root/configure.sh /mnt/root/.sheol-install-env
    ok "system configured + bootloader installed"
}

# =============================================================================
#  PHASE 6 — Final reboot prompt
# =============================================================================
phase_finish() {
    section "DONE"

    ok "Arch installed and configured"
    if $USE_LUKS; then
        ok "Full-disk encryption enabled (LUKS2)"
    fi
    ok "GRUB + Plymouth ready"
    ok "TTY-by-default boot target set"
    if [ "$INSTALL_RICE" = "true" ]; then
        ok "Rice will auto-install on first login as $USERNAME_VAL"
        info "  (clones $SHEOL_REPO and runs install.sh automatically)"
    fi
    echo

    info "next steps:"
    info "  1. unmount + reboot"
    info "  2. when system boots: log in to TTY1 as $USERNAME_VAL"
    if [ "$INSTALL_RICE" = "true" ]; then
        info "  3. rice install runs automatically (~15 min)"
        info "  4. log out + log in again to enter Hyprland"
    fi
    echo

    if ask_yn "unmount and reboot now?" "Y"; then
        step "unmounting"
        umount -R /mnt 2>/dev/null
        if $USE_LUKS; then
            cryptsetup close cryptroot 2>/dev/null
        fi
        ok "unmounted"

        echo
        info "REMOVE THE ARCH ISO BEFORE REBOOT (or set boot order to disk first)"
        info "  in UTM: stop the VM, edit drives, remove the IDE/CD entry with the iso"
        echo
        sleep 3
        reboot
    else
        info "manually reboot when ready:"
        info "  umount -R /mnt"
        if $USE_LUKS; then
            info "  cryptsetup close cryptroot"
        fi
        info "  reboot"
    fi
}

# =============================================================================
#  MAIN
# =============================================================================
main() {
    banner

    info "this script will:"
    info "  • partition + format your target disk (DESTRUCTIVE)"
    info "  • install Arch Linux base system"
    info "  • configure user, locale, bootloader"
    info "  • optionally encrypt with LUKS"
    info "  • optionally clone + install sheol-dots rice on first login"
    echo

    if ! ask_yn "continue?" "Y"; then
        die "aborted"
    fi

    # Collect inputs upfront
    section "configuration"
    HOSTNAME_VAL=$(ask "hostname" "crypt")
    USERNAME_VAL=$(ask "username" "jordan")
    TIMEZONE_VAL=$(ask "timezone" "America/Phoenix")

    if ! [ -f "/usr/share/zoneinfo/$TIMEZONE_VAL" ]; then
        warn "timezone '$TIMEZONE_VAL' not found — falling back to America/Phoenix"
        TIMEZONE_VAL="America/Phoenix"
    fi

    INSTALL_RICE=false
    SHEOL_REPO=""
    if ask_yn "auto-install sheol-dots rice on first login?" "Y"; then
        INSTALL_RICE=true
        SHEOL_REPO=$(ask "git URL of your sheol-dots repo" \
            "https://github.com/jordanlanham52/arch-dot-files.git")
    fi

    echo
    info "summary:"
    info "  hostname:    $HOSTNAME_VAL"
    info "  username:    $USERNAME_VAL"
    info "  timezone:    $TIMEZONE_VAL"
    info "  rice repo:   $SHEOL_REPO"
    echo

    if ! ask_yn "proceed with these settings?" "Y"; then
        die "aborted"
    fi

    # Run phases
    phase_preflight
    phase_disk
    phase_pacstrap
    phase_chroot
    phase_finish
}

main "$@"
