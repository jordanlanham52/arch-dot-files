#!/usr/bin/env bash
# =============================================================================
#  SHEOL // fix-layerrules.sh
#  Fixes layerrule syntax for Hyprland 0.55+:
#    OLD (wrong):  layerrule = blur on, rofi
#    NEW (right):  layerrule = blur on, match:namespace rofi
#  The rule is "action first, match:namespace second".
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
echo -e "${GILT}    ♠  layerrule namespace fix${RESET}"
echo

DOTS=""
for c in "$HOME/sheol-dots" "$HOME/arch-dot-files/sheol-dots" "$HOME/arch-dot-files" "$(pwd)"; do
    if [ -f "$c/pkgs/hypr/.config/hypr/hyprland.conf" ]; then
        DOTS="$c"; break
    fi
done

if [ -z "$DOTS" ]; then
    warn "couldn't find sheol-dots"
    exit 1
fi

HYPR="$DOTS/pkgs/hypr/.config/hypr/hyprland.conf"
step "found: $HYPR"

cp "$HYPR" "$HYPR.bak.$(date +%s)"
ok "backed up"
echo

step "rewriting layerrule lines"

HYPR="$HYPR" python3 << 'PYEOF'
import re
import os

path = os.environ['HYPR']
with open(path) as f:
    lines = f.readlines()

new_lines = []
fixed = 0

for line in lines:
    if not line.lstrip().startswith('layerrule'):
        new_lines.append(line)
        continue

    # Skip already-correct lines (those with match:namespace already on the right side)
    if 'match:namespace' in line:
        new_lines.append(line)
        continue

    # Parse: "layerrule = <effect>, <namespace>"
    m = re.match(r'^(\s*)layerrule\s*=\s*(.+?),\s*(.+?)\s*$', line.rstrip('\n'))
    if not m:
        new_lines.append(line)
        continue

    indent, effect, namespace = m.groups()
    effect = effect.strip()
    namespace = namespace.strip()

    # The namespace was previously written as a bare word — wrap with match:namespace
    new_line = f'{indent}layerrule = {effect}, match:namespace {namespace}\n'
    new_lines.append(new_line)
    fixed += 1

with open(path, 'w') as f:
    f.writelines(new_lines)

print(f"converted {fixed} layerrule lines")
PYEOF

ok "layerrules fixed"
echo

step "sample of fixed layerrules:"
echo
grep "^layerrule" "$HYPR" | head -10 | sed 's/^/    /'
echo

# Reload Hyprland if running
if pgrep -x Hyprland >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    step "reloading Hyprland"
    if hyprctl reload >/dev/null 2>&1; then
        ok "reloaded — banner should be GONE this time"
    else
        warn "reload reported issues"
    fi
fi
echo

echo -e "${GILT}  ◆${RESET}  ${BONE}done${RESET}"
echo
info "this should be the last syntax fix needed"
echo
info "commit:"
info "  cd $DOTS && git add -A && git commit -m 'fix: layerrule match:namespace' && git push"
echo
