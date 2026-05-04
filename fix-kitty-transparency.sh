#!/usr/bin/env bash
# =============================================================================
#  SHEOL // fix-kitty-transparency.sh
#  Diagnose why kitty isn't transparent and fix it.
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
echo -e "${GILT}    ♠  kitty transparency diagnostic${RESET}"
echo

# ---- Diagnose ---------------------------------------------------------------
step "checking what kitty is actually doing"

# Kitty's actual config path
KITTY_CONF="$HOME/.config/kitty/kitty.conf"

if [ ! -f "$KITTY_CONF" ]; then
    warn "no kitty.conf at $KITTY_CONF"
    info "  creating one"
    mkdir -p "$HOME/.config/kitty"
fi

# What kitty thinks its config is — kitty +kitten defaults will tell us
if command -v kitten >/dev/null 2>&1 || command -v kitty >/dev/null 2>&1; then
    info "  kitty version: $(kitty --version 2>/dev/null || echo unknown)"
    info "  config path:   $KITTY_CONF"
    if [ -f "$KITTY_CONF" ]; then
        info "  current opacity setting:"
        grep -E "^(background_opacity|background_blur|dynamic_background_opacity)" "$KITTY_CONF" 2>/dev/null | sed 's/^/    /' || \
            info "    (none set)"
    fi
fi
echo

# ---- Find the repo so we patch the source too -------------------------------
DOTS=""
for c in "$HOME/sheol-dots" "$HOME/arch-dot-files/sheol-dots" "$HOME/arch-dot-files" "$(pwd)"; do
    if [ -d "$c/pkgs" ]; then
        DOTS="$c"; break
    fi
done

# ---- Write a fresh kitty config with all transparency tricks ---------------
step "writing fresh kitty.conf with maximum transparency support"

cat > "$KITTY_CONF" << 'KITTY_EOF'
# =============================================================================
#  SHEOL // kitty.conf
#  Configured for max transparency in Wayland/Hyprland
# =============================================================================

# ---- Font -------------------------------------------------------------------
font_family       JetBrainsMono Nerd Font
bold_font         auto
italic_font       auto
bold_italic_font  auto
font_size         12.0
disable_ligatures always

# ---- Window -----------------------------------------------------------------
window_padding_width 18
hide_window_decorations yes
confirm_os_window_close 0
remember_window_size no
initial_window_width 1000
initial_window_height 600

# ---- Transparency -----------------------------------------------------------
# Critical: this is the real opacity. Set lower for more see-through.
background_opacity 0.75
# Allow runtime toggle with Ctrl+Shift+a > m
dynamic_background_opacity yes
# Background tint for blur effect — 0.0 = pure transparency, no tint
background_tint 0.0
background_tint_gaps 0.0
# In some Wayland compositors, kitty needs this for proper alpha
background_blur 0

# ---- Cursor -----------------------------------------------------------------
cursor_shape beam
cursor_blink_interval 0
cursor #e8c870

# ---- Selection --------------------------------------------------------------
selection_foreground #d4c8b0
selection_background #14111a

# ---- URL --------------------------------------------------------------------
url_color #a08240
url_style curly

# ---- Tabs -------------------------------------------------------------------
tab_bar_edge top
tab_bar_style powerline
tab_powerline_style slanted
active_tab_foreground   #e8c870
active_tab_background   #14111a
inactive_tab_foreground #6b6470
inactive_tab_background #050507

# ---- Bell -------------------------------------------------------------------
enable_audio_bell no
visual_bell_duration 0.0

# ---- Mouse ------------------------------------------------------------------
mouse_hide_wait 3.0
url_excluded_characters

# ---- Keybinds (sheol-aligned) -----------------------------------------------
map ctrl+shift+c    copy_to_clipboard
map ctrl+shift+v    paste_from_clipboard
map ctrl+shift+plus change_font_size all +1
map ctrl+shift+minus change_font_size all -1
map ctrl+shift+0    change_font_size all 0

# ---- Sheol palette ----------------------------------------------------------
# Background: pure black so transparency reads as wallpaper, not a tint
foreground            #b8aea0
background            #050507
selection_foreground  #d4c8b0
selection_background  #2a2530

# 16 ANSI colors — no cool tones, only golds/grays
# 0 black
color0  #14111a
color8  #2a2530
# 1 red — sanctus deep crimson
color1  #5a1a1a
color9  #7a2a2a
# 2 green — repurposed as oxide gold (no greens in sheol)
color2  #6b5530
color10 #8a7040
# 3 yellow — gilt
color3  #a08240
color11 #c9a651
# 4 blue — repurposed as muted bone (no blues in sheol)
color4  #6b6470
color12 #8a8088
# 5 magenta — repurposed as deep tarnish (no magentas)
color5  #4a3a1f
color13 #6b5530
# 6 cyan — repurposed as halo highlight (no cyans)
color6  #c9a651
color14 #e8c870
# 7 white — bone
color7  #b8aea0
color15 #d4c8b0
KITTY_EOF

ok "kitty.conf written with background_opacity 0.75"
echo

# ---- Mirror to repo so it's tracked ----------------------------------------
if [ -n "$DOTS" ]; then
    REPO_KITTY="$DOTS/pkgs/ghostty/.config/kitty/kitty.conf"
    if [ -f "$REPO_KITTY" ]; then
        cp "$KITTY_CONF" "$REPO_KITTY"
        ok "mirrored to repo at $REPO_KITTY"
    fi
fi
echo

# ---- Force-restart all kitty instances --------------------------------------
step "killing all kitty instances so they reload config"
pkill -x kitty 2>/dev/null && info "  killed running kitty windows" || info "  none running"
sleep 1
echo

# ---- Verify Hyprland decoration blur is on ---------------------------------
HYPR="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR" ]; then
    if grep -q "blur {" "$HYPR" && grep -A 5 "blur {" "$HYPR" | grep -q "enabled = true"; then
        ok "Hyprland decoration blur is on"
    else
        warn "Hyprland decoration blur may not be enabled"
    fi

    # Check decoration opacity for terminals
    if grep -q "active_opacity" "$HYPR"; then
        info "  Hyprland window opacity:"
        grep -E "(active_opacity|inactive_opacity)" "$HYPR" | head -2 | sed 's/^/    /'
    fi
fi
echo

echo -e "${GILT}  ◆${RESET}  ${BONE}done${RESET}"
echo
info "now open a new kitty window:"
info "  Option+Return"
info ""
info "should be SIGNIFICANTLY more transparent (0.75 = 25% see-through)"
info ""
info "if still solid, the QEMU virtio GPU may not support alpha compositing."
info "in that case it's a VM limitation — on real hardware it'll work."
echo
info "tweaks (edit ~/.config/kitty/kitty.conf):"
info "  background_opacity 0.65  ← more transparent"
info "  background_opacity 0.50  ← very transparent"
info "  background_opacity 1.0   ← fully opaque (back to default)"
echo
