#!/usr/bin/env bash
# =============================================================================
#  SHEOL // fix-rules-final.sh
#  Final patch for Hyprland 0.55+ rule field naming.
#  Idempotent — safe to run multiple times. Handles partially-converted state.
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
echo -e "${GILT}    ♠  final rule syntax fix${RESET}"
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

step "rewriting rule field names"

HYPR="$HYPR" python3 << 'PYEOF'
import re
import os

path = os.environ['HYPR']
with open(path) as f:
    content = f.read()

original = content

# Old → new field name (no value handling here, we do that next)
field_renames = {
    'idleinhibit':    'idle_inhibit',
    'noblur':         'no_blur',
    'noborder':       'no_border',
    'noshadow':       'no_shadow',
    'norounding':     'no_rounding',
    'noanim':         'no_anim',
    'noinitialfocus': 'no_initial_focus',
    'nodim':          'no_dim',
    'noscreenshare':  'no_screen_share',
    'fakefullscreen': 'fake_fullscreen',
    'stayfocused':    'stay_focused',
}

# Fields that take "on/off" — need explicit "on" if bare.
# idle_inhibit takes a mode (none/always/focus/fullscreen), not on/off — exclude.
need_on_fields = {
    'no_blur', 'no_border', 'no_shadow', 'no_rounding', 'no_anim',
    'no_initial_focus', 'no_dim', 'no_screen_share', 'fake_fullscreen',
    'stay_focused',
}

# Layer rule keywords that need explicit on/off
layerrule_need_on = {'blur', 'ignorezero', 'noanim', 'noeffects', 'unset'}

def fix_windowrule(line):
    if not line.lstrip().startswith('windowrule'):
        return line
    new_line = line
    # 1. Rename old → new
    for old, new in field_renames.items():
        pattern = r'\b' + re.escape(old) + r'\b'
        new_line = re.sub(pattern, new, new_line)
    # 2. Collapse double "on on" (caused by previous patches that added 'on' to noblur)
    for f in need_on_fields:
        new_line = re.sub(rf'\b{f}\s+on\s+on\b', f'{f} on', new_line)
    # 3. Add "on" to bare instances (e.g. ", no_blur," or ", no_blur" at end)
    for f in need_on_fields:
        # Match: word boundary <f> word boundary, NOT followed by another value
        pattern = rf'\b{f}\b(?!\s+(on|off))(?=\s*,|\s*$)'
        new_line = re.sub(pattern, f'{f} on', new_line)
    return new_line

def fix_layerrule(line):
    if not line.lstrip().startswith('layerrule'):
        return line
    m = re.match(r'^(\s*)layerrule\s*=\s*(.+?),\s*(.+?)\s*$', line.rstrip('\n'))
    if not m:
        return line
    indent, effect, namespace = m.groups()
    effect = effect.strip()
    namespace = namespace.strip()
    # If effect is a bare keyword that needs "on", add it
    if effect in layerrule_need_on:
        effect = f'{effect} on'
    return f'{indent}layerrule = {effect}, {namespace}'

lines = content.split('\n')
fixed = []
for line in lines:
    line = fix_windowrule(line)
    line = fix_layerrule(line)
    fixed.append(line)

content = '\n'.join(fixed)

if content != original:
    with open(path, 'w') as f:
        f.write(content)
    print("config updated")
else:
    print("no changes — already up to date")
PYEOF

ok "field names normalized"
echo

step "sample of fixed rules:"
echo
grep -E "^(windowrule|layerrule)" "$HYPR" | grep -E "no_blur|idle_inhibit|^layerrule" | head -10 | sed 's/^/    /'
echo

# Reload Hyprland if running
if pgrep -x Hyprland >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    step "reloading Hyprland"
    if hyprctl reload >/dev/null 2>&1; then
        ok "reloaded — banner should clear"
    else
        warn "reload reported issues"
        info "  check: hyprctl reload 2>&1 | head"
    fi
fi
echo

echo -e "${GILT}  ◆${RESET}  ${BONE}done${RESET}"
echo
info "if any errors remain, run this and screenshot:"
info "  hyprctl reload 2>&1 | head -20"
echo
info "commit:"
info "  cd $DOTS && git add -A && git commit -m 'fix: 0.55+ field names' && git push"
echo
