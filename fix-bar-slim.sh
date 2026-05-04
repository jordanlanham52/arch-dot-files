#!/usr/bin/env bash
# =============================================================================
#  SHEOL // fix-bar-slim.sh
#  Bar was too thick. Slim it down.
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
echo -e "${GILT}    ♠  slim bar${RESET}"
echo

DOTS=""
for c in "$HOME/sheol-dots" "$HOME/arch-dot-files/sheol-dots" "$HOME/arch-dot-files" "$(pwd)"; do
    if [ -f "$c/pkgs/waybar/.config/waybar/top.jsonc" ]; then
        DOTS="$c"; break
    fi
done

[ -z "$DOTS" ] && { warn "no repo"; exit 1; }
step "found: $DOTS"
echo

TOP="$DOTS/pkgs/waybar/.config/waybar/top.jsonc"
STYLE="$DOTS/pkgs/waybar/.config/waybar/style.css"
cp "$TOP" "$TOP.bak.$(date +%s)"
cp "$STYLE" "$STYLE.bak.$(date +%s)"

# ---- Cut height from 56 → 32 ------------------------------------------------
step "shrinking bar height: 56 → 32"
sed -i 's/"height": 56/"height": 32/' "$TOP"
ok "height set"
echo

# ---- Tighten padding in style.css ------------------------------------------
step "tightening module padding"

STYLE="$STYLE" python3 << 'PYEOF'
import re, os
path = os.environ['STYLE']
with open(path) as f:
    content = f.read()

# Spade — was padding 0 18px 0 22px → 0 14px 0 16px
content = re.sub(
    r'(#custom-spade\s*\{[^}]*?)padding:[^;]+;',
    r'\1padding: 0 14px 0 16px;',
    content, flags=re.DOTALL
)

# Spade font-size — was 18px → 15px
content = re.sub(
    r'(#custom-spade\s*\{[^}]*?)font-size:\s*\d+px;',
    r'\1font-size: 15px;',
    content, flags=re.DOTALL
)

# Workspaces wrapper padding — was 6px 8px → 2px 6px
content = re.sub(
    r'(#workspaces\s*\{[^}]*?)padding:[^;]+;',
    r'\1padding: 2px 6px;',
    content, flags=re.DOTALL
)

# Workspaces button — was padding 2px 12px → 1px 9px
content = re.sub(
    r'(#workspaces button\s*\{[^}]*?)padding:[^;]+;',
    r'\1padding: 1px 9px;',
    content, flags=re.DOTALL
)

# Workspace button font — was 13px → 12px
content = re.sub(
    r'(#workspaces button\s*\{[^}]*?)font-size:\s*\d+px;',
    r'\1font-size: 12px;',
    content, flags=re.DOTALL
)

# Window title — was padding 0 24px → 0 16px
content = re.sub(
    r'(#window\s*\{[^}]*?)padding:\s*0\s+\d+px;',
    r'\1padding: 0 16px;',
    content, flags=re.DOTALL
)

# Window title font — was 14px → 12px
content = re.sub(
    r'(#window\s*\{[^}]*?)font-size:\s*\d+px;',
    r'\1font-size: 12px;',
    content, flags=re.DOTALL
)

# Stats modules padding — was 0 16px → 0 12px
content = re.sub(
    r'(#network,\s*#cpu,\s*#memory\s*\{[^}]*?)padding:[^;]+;',
    r'\1padding: 0 12px;',
    content, flags=re.DOTALL
)

# Roman clock padding — was 0 22px → 0 14px
content = re.sub(
    r'(#custom-roman-clock\s*\{[^}]*?)padding:[^;]+;',
    r'\1padding: 0 14px;',
    content, flags=re.DOTALL
)

# Roman clock font — was 14px → 12px
content = re.sub(
    r'(#custom-roman-clock\s*\{[^}]*?)font-size:\s*\d+px;',
    r'\1font-size: 12px;',
    content, flags=re.DOTALL
)

# Power button padding — was 0 18px → 0 14px
content = re.sub(
    r'(#custom-power\s*\{[^}]*?)padding:[^;]+;',
    r'\1padding: 0 14px;',
    content, flags=re.DOTALL
)

# Global font size — was 13 → 12
content = re.sub(
    r'(\*\s*\{[^}]*?)font-size:\s*\d+px;',
    r'\1font-size: 12px;',
    content, flags=re.DOTALL
)

with open(path, 'w') as f:
    f.write(content)
print("padding tightened")
PYEOF

ok "padding reduced across all modules"
echo

# ---- Restart waybar ---------------------------------------------------------
if pgrep -x waybar >/dev/null && [ -n "${WAYLAND_DISPLAY:-}" ]; then
    step "restarting waybar"
    pkill waybar
    sleep 0.5
    waybar -c "$HOME/.config/waybar/top.jsonc" -s "$HOME/.config/waybar/style.css" >/dev/null 2>&1 &
    disown -a
    sleep 1
    pgrep -x waybar >/dev/null && ok "waybar restarted"
fi
echo

echo -e "${GILT}  ◆${RESET}  ${BONE}done${RESET}"
echo
info "bar height: 32px (was 56)"
info "module fonts: 12px (was 13-14)"
info "module padding: tightened ~30%"
echo
info "if still too thick, drop further:"
info "  sed -i 's/\"height\": 32/\"height\": 28/' ~/arch-dot-files/sheol-dots/pkgs/waybar/.config/waybar/top.jsonc"
info "  pkill waybar && waybar -c ~/.config/waybar/top.jsonc -s ~/.config/waybar/style.css &"
echo
info "commit:"
info "  cd $DOTS && git add -A && git commit -m 'bar: slimmer profile' && git push"
echo
