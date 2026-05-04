#!/usr/bin/env bash
# =============================================================================
#  SHEOL // fix-transparency.sh
#  - Bar background: translucent black (rgba) so wallpaper shows through
#    with a darken effect — the bar becomes a glass plate over illumination
#  - Kitty: make sure the stowed config is in place (opacity 0.93, blur 20)
#  - Hyprland blur is already enabled, so the bar will get layer blur applied
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
echo -e "${GILT}    ♠  transparency pass${RESET}"
echo

DOTS=""
for c in "$HOME/sheol-dots" "$HOME/arch-dot-files/sheol-dots" "$HOME/arch-dot-files" "$(pwd)"; do
    if [ -f "$c/pkgs/waybar/.config/waybar/style.css" ]; then
        DOTS="$c"; break
    fi
done

[ -z "$DOTS" ] && { warn "no repo"; exit 1; }
step "found repo: $DOTS"
echo

# ---- Patch waybar style.css for translucency --------------------------------
STYLE="$DOTS/pkgs/waybar/.config/waybar/style.css"
cp "$STYLE" "$STYLE.bak.$(date +%s)"

step "making bar translucent"
# Replace the gradient backgrounds with rgba versions (75% opacity)
# The Hyprland layerrule already blurs the waybar namespace, so this gives
# us a frosted glass effect over the wallpaper.
python3 << PYEOF
import re

path = "$STYLE"
with open(path) as f:
    content = f.read()

# Top register: was solid black gradient, make rgba
content = re.sub(
    r'window#waybar\.top\s*\{[^}]*?background:[^;]+;',
    'window#waybar.top {\n    background: linear-gradient(180deg, rgba(10, 8, 13, 0.78) 0%, rgba(5, 5, 7, 0.82) 100%);',
    content, count=1
)

# Bottom register: same treatment
content = re.sub(
    r'window#waybar\.bottom\s*\{[^}]*?background:[^;]+;',
    'window#waybar.bottom {\n    background: linear-gradient(180deg, rgba(5, 5, 7, 0.82) 0%, rgba(10, 8, 13, 0.78) 100%);',
    content, count=1
)

with open(path, 'w') as f:
    f.write(content)
PYEOF

ok "style.css updated"
echo

# ---- Verify Hyprland blur is on for waybar layer ---------------------------
HYPR="$DOTS/pkgs/hypr/.config/hypr/hyprland.conf"
step "checking layerrule for waybar blur"
if grep -q "layerrule = blur on, match:namespace waybar" "$HYPR"; then
    ok "waybar blur layerrule present"
else
    warn "waybar blur layerrule missing — adding it"
    # Append after the last layerrule (or end of file)
    cat >> "$HYPR" << 'EOF'

# Re-add waybar blur (lost or missing)
layerrule = blur on, match:namespace waybar
layerrule = ignore_alpha 0.6, match:namespace waybar
EOF
    ok "added"
fi
echo

# ---- Make sure kitty config is stowed ---------------------------------------
step "verifying kitty config is in place"
KITTY_CONF="$HOME/.config/kitty/kitty.conf"
SRC_KITTY_CONF="$DOTS/pkgs/ghostty/.config/kitty/kitty.conf"

if [ -f "$SRC_KITTY_CONF" ]; then
    if [ ! -L "$KITTY_CONF" ] && [ ! -f "$KITTY_CONF" ]; then
        info "  no kitty.conf at ~/.config/kitty — stowing"
        mkdir -p "$HOME/.config/kitty"
        cp "$SRC_KITTY_CONF" "$KITTY_CONF"
        ok "kitty.conf installed"
    elif [ -L "$KITTY_CONF" ]; then
        ok "kitty.conf is a symlink (stow)"
    else
        info "  kitty.conf exists but not symlinked — replacing with copy from repo"
        cp "$SRC_KITTY_CONF" "$KITTY_CONF"
        ok "kitty.conf updated"
    fi

    # Verify transparency settings are present
    if grep -q "^background_opacity" "$KITTY_CONF"; then
        OPACITY=$(grep "^background_opacity" "$KITTY_CONF" | awk '{print $2}')
        info "  kitty background_opacity = $OPACITY"
    else
        warn "  no background_opacity in kitty.conf — adding"
        echo "" >> "$KITTY_CONF"
        echo "background_opacity 0.92" >> "$KITTY_CONF"
        echo "background_blur 20" >> "$KITTY_CONF"
        ok "  added"
    fi
else
    warn "kitty.conf source not found at $SRC_KITTY_CONF"
fi
echo

# ---- Restart waybar so the translucent style takes effect -------------------
if pgrep -x waybar >/dev/null && [ -n "${WAYLAND_DISPLAY:-}" ]; then
    step "restarting waybar"
    pkill waybar
    sleep 0.5
    waybar -c "$HOME/.config/waybar/top.jsonc"    -s "$HOME/.config/waybar/style.css" >/dev/null 2>&1 &
    waybar -c "$HOME/.config/waybar/bottom.jsonc" -s "$HOME/.config/waybar/style.css" >/dev/null 2>&1 &
    disown -a
    sleep 1
    pgrep -x waybar >/dev/null && ok "waybar restarted"
fi

# Reload Hyprland to apply layerrule changes
if pgrep -x Hyprland >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload >/dev/null 2>&1 && ok "Hyprland reloaded"
fi
echo

echo -e "${GILT}  ◆${RESET}  ${BONE}done${RESET}"
echo
info "what to expect:"
info "  · bar: ~80% opaque, blurred wallpaper visible behind"
info "  · kitty: 92% opaque background, you can see wallpaper through text"
info ""
info "to make kitty MORE transparent, edit ~/.config/kitty/kitty.conf:"
info "  background_opacity 0.85   (or lower)"
info "  then restart kitty"
echo
info "commit:"
info "  cd $DOTS && git add -A && git commit -m 'style: translucency pass' && git push"
echo
