#!/usr/bin/env bash
# =============================================================================
#  SHEOL // fix-aesthetics.sh
#  - Hyprland: set proper window opacity (transparency for ALL windows)
#  - Hyprland: reduce blur so wallpaper shows through clearly
#  - Waybar: stack bars flush (no gap between top and bottom)
#  - Waybar: add side margins so bars don't cover corner ornaments
#  - Kitty: opaque background (since transparency is now Hyprland-driven)
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
echo -e "${GILT}    ♠  aesthetics overhaul${RESET}"
echo

DOTS=""
for c in "$HOME/sheol-dots" "$HOME/arch-dot-files/sheol-dots" "$HOME/arch-dot-files" "$(pwd)"; do
    if [ -d "$c/pkgs" ]; then
        DOTS="$c"; break
    fi
done

[ -z "$DOTS" ] && { warn "no repo"; exit 1; }
step "found repo: $DOTS"
echo

# ---- 1. Hyprland: window opacity + blur tuning ------------------------------
HYPR="$DOTS/pkgs/hypr/.config/hypr/hyprland.conf"
cp "$HYPR" "$HYPR.bak.$(date +%s)"

step "tuning Hyprland decoration"

HYPR="$HYPR" python3 << 'PYEOF'
import re
import os

path = os.environ['HYPR']
with open(path) as f:
    content = f.read()

# Set active_opacity and inactive_opacity for all windows
# Active = focused window, Inactive = not focused
content = re.sub(
    r'active_opacity\s*=\s*[\d.]+',
    'active_opacity = 0.92',
    content
)
content = re.sub(
    r'inactive_opacity\s*=\s*[\d.]+',
    'inactive_opacity = 0.85',
    content
)

# Reduce blur so the wallpaper shows through, not just mist
# Currently size=8 passes=3 — way too heavy. Drop to size=4 passes=2.
content = re.sub(
    r'(blur\s*\{[^}]*?)size\s*=\s*\d+',
    r'\1size = 4',
    content,
    flags=re.DOTALL
)
content = re.sub(
    r'(blur\s*\{[^}]*?)passes\s*=\s*\d+',
    r'\1passes = 2',
    content,
    flags=re.DOTALL
)
# brightness — was 0.85 (darkening too much). Set to 1.0 (no darken)
content = re.sub(
    r'(blur\s*\{[^}]*?)brightness\s*=\s*[\d.]+',
    r'\1brightness = 1.0',
    content,
    flags=re.DOTALL
)
# contrast — was 1.2 (too punchy). Set to 1.0 (neutral)
content = re.sub(
    r'(blur\s*\{[^}]*?)contrast\s*=\s*[\d.]+',
    r'\1contrast = 1.0',
    content,
    flags=re.DOTALL
)

with open(path, 'w') as f:
    f.write(content)
print("Hyprland decoration tuned")
PYEOF

ok "Hyprland: opacity 0.92/0.85, blur softened"
echo

# ---- 2. Waybar: flush stack + side margins ---------------------------------
TOP="$DOTS/pkgs/waybar/.config/waybar/top.jsonc"
BOTTOM="$DOTS/pkgs/waybar/.config/waybar/bottom.jsonc"

cp "$TOP" "$TOP.bak.$(date +%s)"
cp "$BOTTOM" "$BOTTOM.bak.$(date +%s)"

step "stacking bars flush + adding side margins"

# Top bar: keep position top, add side margins, no bottom margin
python3 << PYEOF
import re

# --- Top bar ---
path = "$TOP"
with open(path) as f:
    content = f.read()
# Set side margins
content = re.sub(r'"margin-left":\s*\d+', '"margin-left": 12', content)
content = re.sub(r'"margin-right":\s*\d+', '"margin-right": 12', content)
content = re.sub(r'"margin-top":\s*\d+', '"margin-top": 8', content)
content = re.sub(r'"margin-bottom":\s*\d+', '"margin-bottom": 0', content)
with open(path, 'w') as f:
    f.write(content)

# --- Bottom bar (the stats register stacked under the top) ---
path = "$BOTTOM"
with open(path) as f:
    content = f.read()
# Position stays "top" since we want it stacked under top bar, not at screen bottom
# margin-top should equal top bar's height (30) so it sits flush
content = re.sub(r'"margin-left":\s*\d+', '"margin-left": 12', content)
content = re.sub(r'"margin-right":\s*\d+', '"margin-right": 12', content)
content = re.sub(r'"margin-top":\s*\d+', '"margin-top": 38', content)  # 8 (top margin) + 30 (top bar height)
content = re.sub(r'"margin-bottom":\s*\d+', '"margin-bottom": 0', content)
with open(path, 'w') as f:
    f.write(content)

print("waybar margins set")
PYEOF

ok "waybar: 12px side margins, bars stack flush"
echo

# ---- 3. Update style.css to round off bar edges and add subtle frame -------
STYLE="$DOTS/pkgs/waybar/.config/waybar/style.css"
cp "$STYLE" "$STYLE.bak.$(date +%s)"

step "tightening bar style"

python3 << PYEOF
import re

path = "$STYLE"
with open(path) as f:
    content = f.read()

# Make bar bottom border thicker (the seam between top and bottom registers)
# So when stacked, the seam reads as one decorative line, not two
content = re.sub(
    r'window#waybar\.top\s*\{([^}]*)border-bottom:[^;]+;',
    r'window#waybar.top {\1border-bottom: 1px solid @gilt;',
    content
)
content = re.sub(
    r'window#waybar\.bottom\s*\{([^}]*)border-top:[^;]+;',
    r'window#waybar.bottom {\1border-top: 0;',
    content
)

with open(path, 'w') as f:
    f.write(content)
print("style.css refined")
PYEOF

ok "bar seam unified"
echo

# ---- 4. Kitty: opaque background, transparency comes from Hyprland ---------
KITTY_CONF="$HOME/.config/kitty/kitty.conf"
REPO_KITTY="$DOTS/pkgs/ghostty/.config/kitty/kitty.conf"

step "kitty: opaque (transparency now via Hyprland window opacity)"

# Set kitty fully opaque — let Hyprland handle window-level transparency
if [ -f "$KITTY_CONF" ]; then
    sed -i 's/^background_opacity.*/background_opacity 1.0/' "$KITTY_CONF"
    # Remove background_blur since Hyprland handles blur now
    sed -i 's/^background_blur.*/background_blur 0/' "$KITTY_CONF"
    ok "kitty.conf: opacity 1.0 (Hyprland-driven transparency)"
fi

# Mirror back to repo
if [ -f "$REPO_KITTY" ] && [ -f "$KITTY_CONF" ]; then
    cp "$KITTY_CONF" "$REPO_KITTY"
fi
echo

# ---- 5. Restart everything --------------------------------------------------
step "restarting waybar"
if pgrep -x waybar >/dev/null && [ -n "${WAYLAND_DISPLAY:-}" ]; then
    pkill waybar
    sleep 0.5
    waybar -c "$HOME/.config/waybar/top.jsonc"    -s "$HOME/.config/waybar/style.css" >/dev/null 2>&1 &
    waybar -c "$HOME/.config/waybar/bottom.jsonc" -s "$HOME/.config/waybar/style.css" >/dev/null 2>&1 &
    disown -a
    sleep 1
    pgrep -x waybar >/dev/null && ok "waybar restarted"
fi

step "killing kitty so it reloads with new opacity"
pkill -x kitty 2>/dev/null || true
sleep 0.5

step "reloading Hyprland"
if pgrep -x Hyprland >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload >/dev/null 2>&1 && ok "Hyprland reloaded"
fi
echo

echo -e "${GILT}  ◆${RESET}  ${BONE}done${RESET}"
echo
info "what changed:"
info "  · Hyprland window opacity: active 92%, inactive 85%"
info "    (every app gets transparency, not just kitty)"
info "  · blur: size 8→4, passes 3→2 (lighter so wallpaper shows)"
info "  · brightness/contrast: neutralized (no more darkening)"
info "  · waybar: 12px side margins (corner ornaments visible)"
info "  · waybar: bottom register flush against top (no gap)"
info "  · kitty: opacity 1.0 (Hyprland handles it)"
info ""
info "open a fresh kitty: Option+Return"
info "you should see the wallpaper subtly through it"
echo
info "tweak knobs (in hyprland.conf, then hyprctl reload):"
info "  active_opacity = 0.95   ← less transparent"
info "  active_opacity = 0.85   ← more transparent"
info "  blur { size = 6 }       ← more frosted"
info "  blur { size = 2 }       ← less frosted, sharper wallpaper"
echo
info "commit:"
info "  cd $DOTS && git add -A && git commit -m 'aesthetics: window opacity + bar layout' && git push"
echo
