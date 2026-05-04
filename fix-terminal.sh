#!/usr/bin/env bash
# =============================================================================
#  SHEOL // fix-terminal.sh
#  Ghostty's GPU renderer crashes in QEMU VMs. Switch to kitty which uses
#  a more forgiving renderer and works fine in virtio GPU environments.
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
echo -e "${GILT}    ♠  terminal: ghostty → kitty${RESET}"
echo

# ---- Install kitty if needed ------------------------------------------------
if ! command -v kitty >/dev/null 2>&1; then
    step "installing kitty"
    sudo pacman -S --needed --noconfirm kitty
    ok "kitty installed"
else
    info "kitty already installed"
fi
echo

# ---- Find the repo ----------------------------------------------------------
DOTS=""
for c in "$HOME/sheol-dots" "$HOME/arch-dot-files/sheol-dots" "$HOME/arch-dot-files" "$(pwd)"; do
    if [ -f "$c/pkgs/hypr/.config/hypr/hyprland.conf" ]; then
        DOTS="$c"; break
    fi
done

[ -z "$DOTS" ] && { warn "no repo"; exit 1; }
step "found repo: $DOTS"
echo

# ---- Patch hyprland.conf ----------------------------------------------------
HYPR="$DOTS/pkgs/hypr/.config/hypr/hyprland.conf"
cp "$HYPR" "$HYPR.bak.$(date +%s)"

step "patching default terminal"
# Replace $terminal definitions with kitty
sed -i \
    -e 's|^\$terminal\s*=.*|$terminal     = kitty|' \
    -e 's|^\$fileManager\s*=.*|$fileManager  = kitty -e yazi|' \
    "$HYPR"

ok "default terminal set to kitty"
info "  changes:"
grep -E "^\\\$terminal|^\\\$fileManager" "$HYPR" | sed 's/^/    /'
echo

# ---- Test that kitty actually launches --------------------------------------
step "testing kitty"
if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    # We're in Hyprland — try to launch
    if kitty --version >/dev/null 2>&1; then
        ok "kitty binary works"
    fi
else
    info "  not in Hyprland session — can't test launch"
fi
echo

# ---- Reload Hyprland --------------------------------------------------------
if pgrep -x Hyprland >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    step "reloading Hyprland"
    hyprctl reload >/dev/null 2>&1 && ok "reloaded"
fi
echo

echo -e "${GILT}  ◆${RESET}  ${BONE}done${RESET}"
echo
info "now press Option+Return — kitty should open and stay open"
info ""
info "if you want the dark gold theme to apply, the kitty config should already"
info "be stowed at ~/.config/kitty/kitty.conf — kitty picks it up automatically"
echo
info "commit:"
info "  cd $DOTS && git add -A && git commit -m 'fix: kitty as default terminal for VM' && git push"
echo
