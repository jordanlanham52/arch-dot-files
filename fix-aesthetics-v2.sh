#!/usr/bin/env bash
# =============================================================================
#  SHEOL // fix-aesthetics-v2.sh
#  - Hyprland: disable window blur entirely (keep transparency)
#  - Hyprland: bump transparency to 0.85 active / 0.75 inactive
#  - Waybar: merge into ONE bar with all modules so no gap exists
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
echo -e "${GILT}    ♠  blur off + single bar${RESET}"
echo

DOTS=""
for c in "$HOME/sheol-dots" "$HOME/arch-dot-files/sheol-dots" "$HOME/arch-dot-files" "$(pwd)"; do
    if [ -d "$c/pkgs" ]; then
        DOTS="$c"; break
    fi
done

[ -z "$DOTS" ] && { warn "no repo"; exit 1; }
step "found: $DOTS"
echo

# ---- 1. Hyprland: disable blur, more transparency ---------------------------
HYPR="$DOTS/pkgs/hypr/.config/hypr/hyprland.conf"
cp "$HYPR" "$HYPR.bak.$(date +%s)"

step "disabling blur, bumping transparency"

HYPR="$HYPR" python3 << 'PYEOF'
import re, os
path = os.environ['HYPR']
with open(path) as f:
    content = f.read()

# Disable blur entirely (was enabled = true)
content = re.sub(
    r'(blur\s*\{[^}]*?)enabled\s*=\s*true',
    r'\1enabled = false',
    content,
    flags=re.DOTALL
)

# More transparent windows
content = re.sub(r'active_opacity\s*=\s*[\d.]+', 'active_opacity = 0.85', content)
content = re.sub(r'inactive_opacity\s*=\s*[\d.]+', 'inactive_opacity = 0.75', content)

with open(path, 'w') as f:
    f.write(content)
print("Hyprland updated")
PYEOF

ok "blur off; opacity active=0.85, inactive=0.75"
echo

# ---- 2. Waybar: merge top + bottom into single bar -------------------------
step "merging waybars into one bar"

# Backup originals
TOP="$DOTS/pkgs/waybar/.config/waybar/top.jsonc"
BOTTOM="$DOTS/pkgs/waybar/.config/waybar/bottom.jsonc"
[ -f "$TOP" ] && cp "$TOP" "$TOP.bak.$(date +%s)"
[ -f "$BOTTOM" ] && cp "$BOTTOM" "$BOTTOM.bak.$(date +%s)"

# Write a single config that has TWO ROWS but in ONE waybar instance
# Waybar can't do that natively, so we use a different approach:
# put all modules in a single bar with internal separators
cat > "$TOP" << 'EOF'
// =============================================================================
//  SHEOL // waybar/top.jsonc — single unified bar
//  All modules in one bar, two visual rows simulated via spacing
// =============================================================================
{
    "name": "main",
    "layer": "top",
    "position": "top",
    "height": 56,
    "spacing": 0,
    "margin-top": 8,
    "margin-bottom": 0,
    "margin-left": 12,
    "margin-right": 12,
    "exclusive": true,
    "passthrough": false,
    "fixed-center": true,

    "modules-left":   ["custom/spade", "hyprland/workspaces", "hyprland/window"],
    "modules-center": [],
    "modules-right":  ["network", "cpu", "memory", "custom/roman-clock", "custom/power"],

    "custom/spade": {
        "format": "♠",
        "tooltip": false,
        "on-click": "rofi -show drun -theme ~/.config/rofi/missal.rasi"
    },

    "hyprland/workspaces": {
        "format": "{name}",
        "format-icons": {
            "1": "I",
            "2": "II",
            "3": "III",
            "4": "IV",
            "5": "V"
        },
        "persistent-workspaces": {
            "*": [1, 2, 3, 4, 5]
        },
        "on-click": "activate"
    },

    "hyprland/window": {
        "format": "{title}",
        "max-length": 50,
        "separate-outputs": true
    },

    "network": {
        "format-wifi": "NET {bandwidthDownBytes}↓ {bandwidthUpBytes}↑",
        "format-ethernet": "NET {bandwidthDownBytes}↓ {bandwidthUpBytes}↑",
        "format-disconnected": "NET ✘",
        "interval": 5,
        "tooltip-format": "{ifname}: {ipaddr}/{cidr}"
    },

    "cpu": {
        "format": "CPU {usage}%",
        "interval": 2
    },

    "memory": {
        "format": "MEM {used:0.1f}G",
        "interval": 5
    },

    "custom/roman-clock": {
        "exec": "~/.config/hypr/scripts/roman_clock.py --bar",
        "interval": 30,
        "tooltip": false
    },

    "custom/power": {
        "format": "⏻",
        "tooltip": false,
        "on-click": "wlogout || hyprctl dispatch exit"
    }
}
EOF

# Make the bottom bar empty / disabled by overwriting with an empty bar config
# (or we could just remove its exec-once line — let's neutralize it)
cat > "$BOTTOM" << 'EOF'
// Empty placeholder — bottom register merged into top in v2
{
    "name": "disabled",
    "layer": "bottom",
    "position": "bottom",
    "height": 1,
    "modules-left": [],
    "modules-center": [],
    "modules-right": []
}
EOF

ok "single unified bar configured"
echo

# ---- 3. Remove the bottom bar from Hyprland's exec-once --------------------
step "removing bottom bar exec from hyprland.conf"
sed -i '/waybar.*bottom\.jsonc/d' "$HYPR"
ok "only top bar will spawn"
echo

# ---- 4. Update style.css for single bar ------------------------------------
STYLE="$DOTS/pkgs/waybar/.config/waybar/style.css"
cp "$STYLE" "$STYLE.bak.$(date +%s)"

step "writing new style.css for single bar"

cat > "$STYLE" << 'CSS_EOF'
/* =============================================================================
   SHEOL // waybar/style.css  v3 — single unified bar
   ============================================================================= */

@define-color abyss      #050507;
@define-color crypt      #0c0a10;
@define-color sepulcher  #14111a;
@define-color shroud     #1f1a26;
@define-color ash        #2a2530;
@define-color linen      #6b6470;
@define-color bone       #b8aea0;
@define-color relic      #d4c8b0;
@define-color pallor     #e8dfd0;
@define-color tarnish    #4a3a1f;
@define-color oxide      #6b5530;
@define-color gilt       #a08240;
@define-color leaf       #c9a651;
@define-color halo       #e8c870;
@define-color sanctus    #5a1a1a;

* {
    font-family: "Cinzel Decorative", "Cormorant Garamond", "JetBrainsMono Nerd Font", serif;
    font-size: 13px;
    border-radius: 0;
    border: none;
    margin: 0;
    padding: 0;
    min-height: 0;
}

window#waybar {
    background: rgba(5, 5, 7, 0.78);
    color: @bone;
    border: 1px solid @gilt;
}

/* Hide the disabled bottom bar entirely */
window#waybar.disabled {
    background: transparent;
    border: none;
    opacity: 0;
}

/* ---- Spade launcher ----------------------------------------------------- */
#custom-spade {
    color: @gilt;
    font-size: 18px;
    padding: 0 18px 0 22px;
    border-right: 1px solid @tarnish;
    transition: color 200ms ease;
}
#custom-spade:hover { color: @halo; }

/* ---- Workspaces (Roman) ------------------------------------------------- */
#workspaces {
    padding: 6px 8px;
    border-right: 1px solid @tarnish;
}
#workspaces button {
    color: @linen;
    font-family: "Cinzel Decorative", serif;
    font-size: 13px;
    padding: 2px 12px;
    margin: 0 2px;
    border: 1px solid transparent;
    background: transparent;
    transition: all 250ms ease;
}
#workspaces button:hover {
    color: @bone;
    background: rgba(160, 130, 64, 0.06);
}
#workspaces button.active {
    color: @halo;
    background: rgba(232, 200, 112, 0.05);
    border: 1px solid @oxide;
    box-shadow:
        inset 0 0 8px rgba(232, 200, 112, 0.15),
        inset 0 0 1px rgba(232, 200, 112, 0.4);
    animation: halo-pulse 4s ease-in-out infinite;
}
@keyframes halo-pulse {
    0%   { box-shadow: inset 0 0 6px rgba(232, 200, 112, 0.10), inset 0 0 1px rgba(232, 200, 112, 0.35); }
    50%  { box-shadow: inset 0 0 12px rgba(232, 200, 112, 0.20), inset 0 0 1px rgba(232, 200, 112, 0.55); }
    100% { box-shadow: inset 0 0 6px rgba(232, 200, 112, 0.10), inset 0 0 1px rgba(232, 200, 112, 0.35); }
}

/* ---- Window title ------------------------------------------------------- */
#window {
    color: @bone;
    font-family: "Cormorant Garamond", serif;
    font-style: italic;
    font-size: 14px;
    padding: 0 24px;
}

/* ---- Stats modules ------------------------------------------------------ */
#network, #cpu, #memory {
    color: @linen;
    padding: 0 16px;
    border-right: 1px solid @tarnish;
    font-family: "JetBrainsMono Nerd Font", monospace;
    font-size: 11px;
    letter-spacing: 0.5px;
}
#network:hover, #cpu:hover, #memory:hover { color: @bone; }
#cpu.warning, #memory.warning { color: @leaf; }
#cpu.critical, #memory.critical { color: @sanctus; }

/* ---- Roman clock -------------------------------------------------------- */
#custom-roman-clock {
    color: @leaf;
    font-family: "Cinzel Decorative", serif;
    font-size: 14px;
    padding: 0 22px;
    border-right: 1px solid @tarnish;
    letter-spacing: 1px;
}

/* ---- Power -------------------------------------------------------------- */
#custom-power {
    color: @oxide;
    padding: 0 18px;
    font-size: 14px;
    transition: color 200ms ease;
}
#custom-power:hover { color: @sanctus; }

tooltip {
    background: @crypt;
    border: 1px solid @oxide;
    padding: 4px 8px;
}
tooltip label {
    color: @bone;
    font-family: "Cormorant Garamond", serif;
    font-size: 12px;
}
CSS_EOF

ok "style.css for single bar written"
echo

# ---- 5. Set kitty fully opaque (Hyprland handles transparency) ------------
KITTY_CONF="$HOME/.config/kitty/kitty.conf"
if [ -f "$KITTY_CONF" ]; then
    sed -i 's/^background_opacity.*/background_opacity 1.0/' "$KITTY_CONF"
    sed -i 's/^background_blur.*/background_blur 0/' "$KITTY_CONF"
    ok "kitty: opacity 1.0 (Hyprland handles it)"
fi
echo

# ---- 6. Restart everything --------------------------------------------------
step "restarting waybar"
if pgrep -x waybar >/dev/null && [ -n "${WAYLAND_DISPLAY:-}" ]; then
    pkill waybar
    sleep 0.5
    # Only spawn the top bar now
    waybar -c "$HOME/.config/waybar/top.jsonc" -s "$HOME/.config/waybar/style.css" >/dev/null 2>&1 &
    disown -a
    sleep 1
    pgrep -x waybar >/dev/null && ok "waybar restarted (single bar)"
fi

step "killing kitty"
pkill -x kitty 2>/dev/null || true

step "reloading Hyprland"
if pgrep -x Hyprland >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload >/dev/null 2>&1 && ok "reloaded"
fi
echo

echo -e "${GILT}  ◆${RESET}  ${BONE}done${RESET}"
echo
info "what changed:"
info "  · ONE bar (was two) — no gap possible"
info "  · 56px tall, all modules in single row"
info "  · blur DISABLED — wallpaper sharp through windows"
info "  · windows 85% opaque active, 75% inactive"
info ""
info "open kitty: Option+Return — should see wallpaper clearly behind text"
echo
info "tweak knobs:"
info "  - more transparent: hyprland.conf → active_opacity = 0.75"
info "  - less transparent: hyprland.conf → active_opacity = 0.92"
info "  then: hyprctl reload"
echo
info "commit:"
info "  cd $DOTS && git add -A && git commit -m 'aesthetics: single bar, no blur' && git push"
echo
