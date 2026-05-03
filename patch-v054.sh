#!/usr/bin/env bash
# =============================================================================
#  SHEOL // patch-v054.sh
#  Applies fixes for Hyprland 0.54+ syntax + spade ASCII to an existing install.
#  Assumes you already have ~/sheol-dots or ~/arch-dot-files cloned.
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
echo -e "${GILT}    ♠  SHEOL patch — Hyprland 0.54+ fix${RESET}"
echo -e "${LINEN}    ──────────────────────────────────────${RESET}"
echo

# Find the dotfiles repo
DOTS=""
for c in "$HOME/sheol-dots" "$HOME/arch-dot-files/sheol-dots" "$HOME/arch-dot-files" "$(pwd)"; do
    if [ -d "$c/pkgs/hypr/.config/hypr" ]; then
        DOTS="$c"; break
    fi
done

if [ -z "$DOTS" ]; then
    warn "couldn't find sheol-dots — cd into the repo first"
    exit 1
fi

step "found repo at: $DOTS"
echo

# ---- Patch hyprland.conf ----------------------------------------------------
HYPR_CONF="$DOTS/pkgs/hypr/.config/hypr/hyprland.conf"

step "backing up current hyprland.conf"
cp "$HYPR_CONF" "$HYPR_CONF.bak.$(date +%s)"
ok "backup saved"

step "writing fixed hyprland.conf (Hyprland 0.54+ syntax)"

cat > "$HYPR_CONF" << 'HYPR_EOF'
# =============================================================================
#  SHEOL // hyprland.conf  v2
#  Compatible with Hyprland 0.54+
# =============================================================================

source = ~/.config/hypr/colors.conf

monitor = , preferred, auto, 1

$terminal     = ghostty
$fileManager  = ghostty -e yazi
$menu         = rofi -show drun -theme ~/.config/rofi/missal.rasi
$browser      = firefox
$lock         = hyprlock

exec-once = swww-daemon
exec-once = sleep 1 && swww img ~/.config/hypr/wallpaper.png --transition-type none
exec-once = waybar -c ~/.config/waybar/top.jsonc -s ~/.config/waybar/style.css
exec-once = waybar -c ~/.config/waybar/bottom.jsonc -s ~/.config/waybar/style.css
exec-once = swaync
exec-once = hypridle
exec-once = systemctl --user start hyprpolkitagent
exec-once = wl-paste --watch cliphist store

env = XCURSOR_SIZE,24
env = HYPRCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt6ct
env = GDK_BACKEND,wayland,x11
env = QT_QPA_PLATFORM,wayland;xcb
env = MOZ_ENABLE_WAYLAND,1
env = ELECTRON_OZONE_PLATFORM_HINT,wayland

input {
    kb_layout = us
    follow_mouse = 1
    sensitivity = 0
    accel_profile = flat

    touchpad {
        natural_scroll = true
        disable_while_typing = true
        tap-to-click = true
    }
}

# Touchpad gesture (workspace swipe) — top-level in 0.54+
gesture = 3, horizontal, workspace

general {
    border_size = 2
    gaps_in = 8
    gaps_out = 16
    gaps_workspaces = 40
    col.active_border = $tarnishA $gildA $haloA $gildA $tarnishA 45deg
    col.inactive_border = rgba(2a2530ff)
    layout = dwindle
    resize_on_border = true
    allow_tearing = false
}

decoration {
    rounding = 0
    active_opacity = 1.0
    inactive_opacity = 0.95
    dim_inactive = true
    dim_strength = 0.18
    dim_special = 0.4

    blur {
        enabled = true
        size = 8
        passes = 3
        new_optimizations = true
        ignore_opacity = true
        contrast = 1.2
        brightness = 0.85
        vibrancy = 0.0
        noise = 0.02
    }

    shadow {
        enabled = true
        range = 30
        render_power = 4
        color = $shadowA
        color_inactive = $cryptA
        offset = 0 4
    }
}

animations {
    enabled = yes
    bezier = censer,    0.4, 0.0, 0.2, 1.0
    bezier = liturgy,   0.7, 0.0, 0.3, 1.0
    bezier = veil,      0.6, 0.0, 0.4, 1.0
    bezier = mechanism, 0.25, 0.0, 0.0, 1.0

    animation = windows,         1, 6,  censer, slide
    animation = windowsIn,       1, 6,  censer, slide
    animation = windowsOut,      1, 5,  mechanism, slide
    animation = windowsMove,     1, 5,  liturgy
    animation = workspaces,      1, 7,  liturgy, slidevert
    animation = specialWorkspace, 1, 6, censer, slidevert
    animation = fade,            1, 5,  veil
    animation = fadeIn,          1, 5,  veil
    animation = fadeOut,         1, 4,  veil
    animation = border,          1, 12, liturgy
    animation = borderangle,     1, 200, liturgy, loop
    animation = layers,          1, 5,  veil, slide
}

dwindle {
    pseudotile = true
    preserve_split = true
    smart_split = false
    smart_resizing = true
    force_split = 2
}

master {
    new_status = master
}

misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    force_default_wallpaper = 0
    vfr = true
    mouse_move_enables_dpms = true
    key_press_enables_dpms = true
    background_color = $abyss
}

# Window rules — 0.54+ syntax
windowrule = float, class:^(pavucontrol)$
windowrule = float, class:^(nm-connection-editor)$
windowrule = float, class:^(blueman-manager)$
windowrule = float, class:^(nwg-look)$
windowrule = float, class:^(qt5ct|qt6ct)$
windowrule = float, class:^(file_progress)$
windowrule = float, class:^(confirm)$
windowrule = float, class:^(dialog)$
windowrule = float, class:^(download)$
windowrule = float, class:^(notification)$
windowrule = float, class:^(error)$
windowrule = float, class:^(splash)$
windowrule = float, class:^(confirmreset)$
windowrule = float, title:^(Open File)(.*)$
windowrule = float, title:^(Select a File)(.*)$
windowrule = float, title:^(Choose wallpaper)(.*)$
windowrule = float, title:^(Open Folder)(.*)$
windowrule = float, title:^(Save As)(.*)$
windowrule = size 800 600, class:^(pavucontrol)$
windowrule = size 900 700, class:^(nwg-look)$
windowrule = workspace special silent, class:^(scratch)$
windowrule = float, title:^(Picture-in-Picture)$
windowrule = pin, title:^(Picture-in-Picture)$
windowrule = size 480 270, title:^(Picture-in-Picture)$
windowrule = idleinhibit fullscreen, class:.*
windowrule = noblur, class:^(firefox)$
windowrule = noblur, class:^(chromium)$
windowrule = opacity 1.0 1.0, class:^(firefox)$
windowrule = opacity 1.0 1.0, class:^(chromium)$
windowrule = opacity 1.0 1.0, class:^(code)$
windowrule = opacity 0.94 0.92, class:^(com\.mitchellh\.ghostty)$
windowrule = opacity 0.94 0.92, class:^(kitty)$
windowrule = opacity 0.94 0.92, class:^(Alacritty)$

layerrule = blur, rofi
layerrule = ignorezero, rofi
layerrule = blur, waybar
layerrule = ignorezero, waybar
layerrule = blur, swaync-control-center
layerrule = blur, swaync-notification-window
layerrule = ignorezero, swaync-control-center
layerrule = ignorezero, swaync-notification-window

workspace = 1, monitor:, default:true, persistent:true
workspace = 2, monitor:, persistent:true
workspace = 3, monitor:, persistent:true
workspace = 4, monitor:, persistent:true
workspace = 5, monitor:, persistent:true
workspace = special:joker, on-created-empty:[float] $terminal

$mod = SUPER

bind = $mod, Return,    exec, $terminal
bind = $mod, Q,         killactive,
bind = $mod SHIFT, E,   exit,
bind = $mod, E,         exec, $fileManager
bind = $mod, V,         togglefloating,
bind = $mod, R,         exec, $menu
bind = $mod, P,         pseudo,
bind = $mod, T,         togglesplit,
bind = $mod, F,         fullscreen, 0
bind = $mod SHIFT, F,   fullscreen, 1
bind = $mod CTRL, L,    exec, $lock
bind = $mod, B,         exec, $browser
bind = $mod, N,         exec, swaync-client -t -sw
bind = $mod, C,         exec, cliphist list | rofi -dmenu -theme ~/.config/rofi/missal.rasi | cliphist decode | wl-copy

bind = $mod, left,      movefocus, l
bind = $mod, right,     movefocus, r
bind = $mod, up,        movefocus, u
bind = $mod, down,      movefocus, d
bind = $mod, H,         movefocus, l
bind = $mod, K,         movefocus, u
bind = $mod, J,         movefocus, d

bind = $mod SHIFT, left,  movewindow, l
bind = $mod SHIFT, right, movewindow, r
bind = $mod SHIFT, up,    movewindow, u
bind = $mod SHIFT, down,  movewindow, d

binde = $mod CTRL, left,  resizeactive, -40 0
binde = $mod CTRL, right, resizeactive, 40 0
binde = $mod CTRL, up,    resizeactive, 0 -40
binde = $mod CTRL, down,  resizeactive, 0 40

bind = $mod, 1, workspace, 1
bind = $mod, 2, workspace, 2
bind = $mod, 3, workspace, 3
bind = $mod, 4, workspace, 4
bind = $mod, 5, workspace, 5
bind = $mod, 6, workspace, 6
bind = $mod, 7, workspace, 7
bind = $mod, 8, workspace, 8
bind = $mod, 9, workspace, 9
bind = $mod, 0, workspace, 10

bind = $mod SHIFT, 1, movetoworkspace, 1
bind = $mod SHIFT, 2, movetoworkspace, 2
bind = $mod SHIFT, 3, movetoworkspace, 3
bind = $mod SHIFT, 4, movetoworkspace, 4
bind = $mod SHIFT, 5, movetoworkspace, 5
bind = $mod SHIFT, 6, movetoworkspace, 6
bind = $mod SHIFT, 7, movetoworkspace, 7
bind = $mod SHIFT, 8, movetoworkspace, 8
bind = $mod SHIFT, 9, movetoworkspace, 9
bind = $mod SHIFT, 0, movetoworkspace, 10

bind = $mod, mouse_down, workspace, e+1
bind = $mod, mouse_up,   workspace, e-1
bind = $mod, period,     workspace, e+1
bind = $mod, comma,      workspace, e-1

bind = $mod, S,           togglespecialworkspace, joker
bind = $mod SHIFT, S,     movetoworkspace, special:joker

bindm = $mod, mouse:272, movewindow
bindm = $mod, mouse:273, resizewindow

bind = , Print,          exec, hyprshot -m region -o ~/Pictures/Screenshots
bind = SHIFT, Print,     exec, hyprshot -m window -o ~/Pictures/Screenshots
bind = CTRL, Print,      exec, hyprshot -m output -o ~/Pictures/Screenshots
bind = $mod SHIFT, C,    exec, hyprpicker -a

bindel = , XF86AudioRaiseVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bindel = , XF86AudioLowerVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindel = , XF86AudioMute,         exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindel = , XF86AudioMicMute,      exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
bindel = , XF86MonBrightnessUp,   exec, brightnessctl s 5%+
bindel = , XF86MonBrightnessDown, exec, brightnessctl s 5%-

bindl = , XF86AudioPlay, exec, playerctl play-pause
bindl = , XF86AudioNext, exec, playerctl next
bindl = , XF86AudioPrev, exec, playerctl previous

bind = $mod, X, submap, resize
submap = resize
binde = , left,  resizeactive, -30 0
binde = , right, resizeactive, 30 0
binde = , up,    resizeactive, 0 -30
binde = , down,  resizeactive, 0 30
bind  = , escape, submap, reset
bind  = , Return, submap, reset
submap = reset
HYPR_EOF

ok "hyprland.conf updated"
echo

# ---- Patch the spade ASCII --------------------------------------------------
SPADE="$DOTS/pkgs/fastfetch/.config/fastfetch/spade.txt"
if [ -f "$SPADE" ]; then
    step "backing up spade.txt"
    cp "$SPADE" "$SPADE.bak.$(date +%s)"
    step "writing proper spade ASCII"
    cat > "$SPADE" << 'SPADE_EOF'
    $1┌─◆─◆─◆─◆─◆─◆─◆─◆─┐
    $1│                  │
    $1│        $2▄▄▄$1         │
    $1│       $2▄███▄$1        │
    $1│      $2▄█████▄$1       │
    $1│     $2▄███████▄$1      │
    $1│    $2▄█████████▄$1     │
    $1│   $2▄███████████▄$1    │
    $1│   $2▝▀▀▀▀█▀▀▀▀▘$1     │
    $1│        $2▟█▙$1         │
    $1│       $2▔▀▀▀▔$1        │
    $1│                  │
    $1└─◆─◆─◆─◆─◆─◆─◆─◆─┘
       $2IORDANUS LANHAM
SPADE_EOF
    ok "spade.txt updated (now reads as a spade, not a diamond)"
else
    warn "spade.txt not found at $SPADE — skipping"
fi
echo

# ---- Reload Hyprland if running ---------------------------------------------
if pgrep -x Hyprland >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    step "reloading Hyprland config"
    if hyprctl reload >/dev/null 2>&1; then
        ok "Hyprland reloaded — red banner should be gone"
    else
        warn "hyprctl reload returned non-zero — check for new errors"
    fi
else
    info "Hyprland not running in this session — config will load next time"
fi
echo

# ---- Done -------------------------------------------------------------------
echo -e "${GILT}  ◆${RESET}  ${BONE}patch complete${RESET}"
echo
info "what's next:"
info "  · commit + push the changes from your repo so future installs work"
info "  · git -C $DOTS add -A && git -C $DOTS commit -m 'fix: 0.54+ syntax + spade'"
info "  · git -C $DOTS push"
echo
echo -e "${HALO}  ♠${RESET}  ${BONE}memento ludere${RESET}"
echo
