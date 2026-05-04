#!/usr/bin/env bash
# =============================================================================
#  SHEOL // fix-ignorealpha.sh
#  ignorezero/ignore_zero/ignorealpha → ignore_alpha (Hyprland 0.55+ name).
#  Per official docs: ignorezero and ignorealpha are the same field.
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
echo -e "${GILT}    ♠  ignore_alpha fix${RESET}"
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

HYPR="$HYPR" python3 << 'PYEOF'
import re
import os

path = os.environ['HYPR']
with open(path) as f:
    content = f.read()

original = content

# Strip any "on" appended to old names (left over from earlier conversion runs)
content = re.sub(r'\bignore_zero\s+on\b', 'ignore_zero', content)
content = re.sub(r'\bignorezero\s+on\b',  'ignorezero', content)
content = re.sub(r'\bignorealpha\s+on\b', 'ignorealpha', content)

# Rename old names → ignore_alpha (preserve any numeric value that follows)
# If no numeric value, default to 1 (full opacity threshold)
content = re.sub(r'\bignore_zero\b(\s+\d+(?:\.\d+)?)?', lambda m: 'ignore_alpha' + (m.group(1) or ' 1'), content)
content = re.sub(r'\bignorezero\b(\s+\d+(?:\.\d+)?)?',  lambda m: 'ignore_alpha' + (m.group(1) or ' 1'), content)
content = re.sub(r'\bignorealpha\b(\s+\d+(?:\.\d+)?)?', lambda m: 'ignore_alpha' + (m.group(1) or ' 1'), content)

if content != original:
    with open(path, 'w') as f:
        f.write(content)
    print("config updated")
else:
    print("no changes")
PYEOF

ok "renamed"
echo

step "result:"
echo
grep "^layerrule" "$HYPR" | sed 's/^/    /'
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
info "commit:"
info "  cd $DOTS && git add -A && git commit -m 'fix: ignore_alpha rename' && git push"
echo
