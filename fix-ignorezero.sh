#!/usr/bin/env bash
# =============================================================================
#  SHEOL // fix-ignorezero.sh
#  Renames `ignorezero` to `ignore_zero` (underscored form Hyprland 0.55+ wants)
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
echo -e "${GILT}    ♠  ignorezero → ignore_zero${RESET}"
echo

DOTS=""
for c in "$HOME/sheol-dots" "$HOME/arch-dot-files/sheol-dots" "$HOME/arch-dot-files" "$(pwd)"; do
    if [ -f "$c/pkgs/hypr/.config/hypr/hyprland.conf" ]; then
        DOTS="$c"; break
    fi
done

[ -z "$DOTS" ] && { warn "no repo"; exit 1; }

HYPR="$DOTS/pkgs/hypr/.config/hypr/hyprland.conf"
cp "$HYPR" "$HYPR.bak.$(date +%s)"
ok "backed up"

step "renaming"
# \bignorezero\b — word boundary, but not preceded by an underscore (already-converted)
sed -i 's/\bignorezero\b/ignore_zero/g' "$HYPR"
ok "renamed"
echo

step "result:"
echo
grep "^layerrule" "$HYPR" | head -10 | sed 's/^/    /'
echo

if pgrep -x Hyprland >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    step "reloading Hyprland"
    if hyprctl reload >/dev/null 2>&1; then
        ok "reloaded"
    fi
fi
echo

echo -e "${GILT}  ◆${RESET}  ${BONE}done${RESET}"
echo
info "commit: cd $DOTS && git add -A && git commit -m 'fix: ignore_zero rename' && git push"
echo
