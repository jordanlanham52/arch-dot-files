#!/usr/bin/env bash
# =============================================================================
#  SHEOL // fix-windowrules.sh
#  Updates windowrule lines to the newest Hyprland 0.55+ syntax:
#    OLD: windowrule = float, class:^(foo)$
#    NEW: windowrule = match:class ^(foo)$, float on
#  Plus: pin → pin on, opacity needs explicit values, etc.
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
echo -e "${GILT}    ♠  windowrule syntax fix (Hyprland 0.55+)${RESET}"
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

# Backup
cp "$HYPR" "$HYPR.bak.$(date +%s)"
ok "backed up"
echo

# Use Python for the rewrite — sed gets gnarly with regex inside regex
step "rewriting windowrule lines"

python3 << 'PYEOF'
import re
import os

path = os.path.expanduser(os.environ.get('HYPR', ''))
if not path:
    # Fall back: find it
    for c in ['~/sheol-dots', '~/arch-dot-files/sheol-dots', '~/arch-dot-files']:
        p = os.path.expanduser(f"{c}/pkgs/hypr/.config/hypr/hyprland.conf")
        if os.path.exists(p):
            path = p
            break

with open(path) as f:
    lines = f.readlines()

new_lines = []
changed = 0

for line in lines:
    original = line
    stripped = line.strip()

    # Skip if not a windowrule
    if not stripped.startswith('windowrule'):
        new_lines.append(line)
        continue

    # Skip already-converted lines (those using "match:" prefix)
    if 'match:' in stripped:
        new_lines.append(line)
        continue

    # Parse: "windowrule = <effect>, <matcher>"
    # where matcher is "class:RE", "title:RE", or just RE
    m = re.match(r'^(\s*)windowrule\s*=\s*(.+?),\s*(.+?)\s*$', line.rstrip('\n'))
    if not m:
        new_lines.append(line)
        continue

    indent, effect, matcher = m.groups()
    effect = effect.strip()
    matcher = matcher.strip()

    # Convert matcher: "class:^(foo)$" → "match:class ^(foo)$"
    # "title:^(bar)$" → "match:title ^(bar)$"
    # bare "^(foo)$" → "match:class ^(foo)$"
    if matcher.startswith('class:'):
        new_matcher = 'match:class ' + matcher[len('class:'):]
    elif matcher.startswith('title:'):
        new_matcher = 'match:title ' + matcher[len('title:'):]
    elif matcher.startswith('workspace:'):
        new_matcher = 'match:workspace ' + matcher[len('workspace:'):]
    elif matcher.startswith('match:'):
        new_matcher = matcher
    else:
        # Bare regex — treat as class match
        new_matcher = 'match:class ' + matcher

    # Convert effect: bare keywords need explicit "on"
    bare_to_on = {
        'float', 'pin', 'noblur', 'noborder', 'noshadow', 'norounding',
        'noanim', 'noinitialfocus', 'nodim', 'noscreenshare', 'fakefullscreen',
        'idleinhibit', 'stayfocused', 'tile', 'fullscreen', 'maximize',
        'center', 'noinitialfocus', 'pseudo'
    }

    parts = [p.strip() for p in effect.split(',')]
    new_parts = []
    for p in parts:
        # If it's just a bare keyword that needs "on"
        if p in bare_to_on:
            new_parts.append(f'{p} on')
        # idleinhibit fullscreen is a special case — fullscreen is the value
        elif p.startswith('idleinhibit '):
            new_parts.append(p)
        else:
            new_parts.append(p)

    new_effect = ', '.join(new_parts)

    new_line = f'{indent}windowrule = {new_matcher}, {new_effect}\n'
    if new_line != original:
        changed += 1
    new_lines.append(new_line)

with open(path, 'w') as f:
    f.writelines(new_lines)

print(f"converted {changed} windowrule lines")
PYEOF

ok "windowrules rewritten"
echo

# Show a sample of the new rules
step "sample of new rules:"
echo
grep "^windowrule" "$HYPR" | head -8 | sed 's/^/    /'
echo "    ..."
echo

# Reload Hyprland if running
if pgrep -x Hyprland >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    step "reloading Hyprland"
    if hyprctl reload >/dev/null 2>&1; then
        ok "Hyprland reloaded — red banner should be gone"
    else
        warn "hyprctl reload had issues — check 'hyprctl reload' output"
    fi
else
    info "Hyprland not running — config will load next time"
fi
echo

echo -e "${GILT}  ◆${RESET}  ${BONE}done${RESET}"
echo
info "commit + push:"
info "  cd $DOTS && git add -A && git commit -m 'fix: windowrules 0.55+ syntax' && git push"
echo
