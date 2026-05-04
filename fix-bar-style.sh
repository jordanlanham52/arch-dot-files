#!/usr/bin/env bash
# =============================================================================
#  SHEOL // fix-bar-style.sh
#  Rewrites waybar style.css to match the original mockup:
#    - Hairline separators between groups (♠ │ workspaces │ title │ clock)
#    - Active workspace: inset glow + outline box (not just color change)
#    - Generous horizontal padding so sections breathe
#    - 1px gold hairline frame around the entire bar
#    - Module separators in stats register (NET │ CPU │ MEM │ ⏻)
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
echo -e "${GILT}    ♠  bar style overhaul${RESET}"
echo

DOTS=""
for c in "$HOME/sheol-dots" "$HOME/arch-dot-files/sheol-dots" "$HOME/arch-dot-files" "$(pwd)"; do
    if [ -f "$c/pkgs/waybar/.config/waybar/style.css" ]; then
        DOTS="$c"; break
    fi
done

[ -z "$DOTS" ] && { warn "no repo"; exit 1; }
step "found repo: $DOTS"

STYLE="$DOTS/pkgs/waybar/.config/waybar/style.css"
cp "$STYLE" "$STYLE.bak.$(date +%s)"
ok "backed up"
echo

step "writing new style.css"

cat > "$STYLE" << 'STYLE_EOF'
/* =============================================================================
   SHEOL // waybar/style.css  v2
   Two-register iconostasis, calibrated to the Tarnished Reliquary mockup.
   - Hairline separators between every group
   - Active workspace: inset glow + thin outline box
   - 1px hairline gold frame around each register
   - Generous horizontal padding
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

/* ============================ TOP REGISTER ================================ */
window#waybar.top {
    background: linear-gradient(180deg, #0a080d 0%, #050507 100%);
    color: @bone;
    border-top:    1px solid @gilt;
    border-bottom: 1px solid @oxide;
}

/* ========================== BOTTOM REGISTER =============================== */
window#waybar.bottom {
    background: linear-gradient(180deg, #050507 0%, #0a080d 100%);
    color: @linen;
    font-size: 11px;
    border-top:    1px solid @oxide;
    border-bottom: 1px solid @gilt;
}

/* ----- Spade launcher ----------------------------------------------------- */
#custom-spade {
    color: @gilt;
    font-size: 18px;
    padding: 0 18px 0 22px;
    border-right: 1px solid @tarnish;
    transition: color 200ms ease;
}

#custom-spade:hover {
    color: @halo;
}

/* ----- Workspaces (Roman numerals) ---------------------------------------- */
#workspaces {
    padding: 4px 8px;
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

/* Active workspace — outline box + halo glow + brighter text */
#workspaces button.active {
    color: @halo;
    background: rgba(232, 200, 112, 0.05);
    border: 1px solid @oxide;
    box-shadow:
        inset 0 0 8px rgba(232, 200, 112, 0.15),
        inset 0 0 1px rgba(232, 200, 112, 0.4);
}

#workspaces button.urgent {
    color: @sanctus;
    background: rgba(90, 26, 26, 0.15);
    border: 1px solid @sanctus;
}

/* ----- Window title ------------------------------------------------------- */
#window {
    color: @bone;
    font-family: "Cormorant Garamond", serif;
    font-style: italic;
    font-size: 14px;
    padding: 0 24px;
}

window#waybar.top .empty-window-title {
    /* hide if waybar exposes this — otherwise no-op */
}

/* ----- Roman clock (right side of top bar) -------------------------------- */
#custom-roman-clock {
    color: @leaf;
    font-family: "Cinzel Decorative", serif;
    font-size: 14px;
    padding: 0 22px;
    border-left: 1px solid @tarnish;
    letter-spacing: 1px;
}

/* ============================ BOTTOM REGISTER MODULES ===================== */
/* All stats modules: separator hairline on the right */
#network,
#cpu,
#memory,
#battery,
#pulseaudio,
#bluetooth,
#tray {
    color: @linen;
    padding: 0 16px;
    border-right: 1px solid @tarnish;
    font-family: "JetBrainsMono Nerd Font", monospace;
    font-size: 11px;
    letter-spacing: 0.5px;
}

/* Don't put a separator after the last module */
#custom-power {
    color: @oxide;
    padding: 0 18px;
    font-size: 14px;
    transition: color 200ms ease;
}

#custom-power:hover {
    color: @sanctus;
}

/* Hover state for stats modules */
#network:hover,
#cpu:hover,
#memory:hover,
#battery:hover {
    color: @bone;
}

/* States: critical / warning */
#cpu.warning,
#memory.warning,
#battery.warning {
    color: @leaf;
}

#cpu.critical,
#memory.critical,
#battery.critical {
    color: @sanctus;
}

/* Battery charging state */
#battery.charging {
    color: @halo;
}

/* ----- Tray --------------------------------------------------------------- */
#tray {
    padding: 0 12px;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
}

/* ----- Notification module (if used) -------------------------------------- */
#custom-notification {
    color: @linen;
    padding: 0 12px;
    border-right: 1px solid @tarnish;
}

#custom-notification.notification {
    color: @halo;
}

/* ----- Animated active-workspace shimmer ---------------------------------- */
@keyframes halo-pulse {
    0%   { box-shadow: inset 0 0 6px rgba(232, 200, 112, 0.10), inset 0 0 1px rgba(232, 200, 112, 0.35); }
    50%  { box-shadow: inset 0 0 12px rgba(232, 200, 112, 0.20), inset 0 0 1px rgba(232, 200, 112, 0.55); }
    100% { box-shadow: inset 0 0 6px rgba(232, 200, 112, 0.10), inset 0 0 1px rgba(232, 200, 112, 0.35); }
}

#workspaces button.active {
    animation: halo-pulse 4s ease-in-out infinite;
}

/* ----- Tooltip styling ---------------------------------------------------- */
tooltip {
    background: @crypt;
    border: 1px solid @oxide;
    border-radius: 0;
    padding: 4px 8px;
}

tooltip label {
    color: @bone;
    font-family: "Cormorant Garamond", serif;
    font-size: 12px;
}
STYLE_EOF

ok "style.css rewritten"
echo

# Restart waybar so changes take effect immediately
if pgrep -x waybar >/dev/null && [ -n "${WAYLAND_DISPLAY:-}" ]; then
    step "restarting waybar"
    pkill waybar
    sleep 0.5
    waybar -c "$HOME/.config/waybar/top.jsonc"    -s "$HOME/.config/waybar/style.css" >/dev/null 2>&1 &
    waybar -c "$HOME/.config/waybar/bottom.jsonc" -s "$HOME/.config/waybar/style.css" >/dev/null 2>&1 &
    disown -a
    sleep 1
    if pgrep -x waybar >/dev/null; then
        ok "waybar restarted — bar should look like the mockup now"
    else
        warn "waybar didn't come back — check: waybar 2>&1 | head"
        info "  also, you can fall back to 'hyprctl reload' which respawns the exec-once lines"
    fi
else
    info "waybar not running or not in Hyprland — config will apply next launch"
fi
echo

echo -e "${GILT}  ◆${RESET}  ${BONE}done${RESET}"
echo
info "what changed:"
info "  · separators between every group (♠ │ workspaces │ title │ clock)"
info "  · active workspace gets a glowing outline box"
info "  · stats modules separated by hairlines"
info "  · proper padding so sections breathe"
info "  · subtle pulsing halo on active workspace (4s cycle)"
echo
info "commit:"
info "  cd $DOTS && git add -A && git commit -m 'style: bar matches mockup' && git push"
echo
