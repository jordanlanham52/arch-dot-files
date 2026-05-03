# =============================================================================
#  SHEOL // .zprofile
#  Dual-mode boot: TTY by default, optional Hyprland launch on TTY1.
# =============================================================================

# ---- Environment -------------------------------------------------------------
export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export BROWSER=firefox
export TERMINAL=ghostty

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# ---- Starship config switch — GUI vs TTY ------------------------------------
if [[ "$TERM" == "linux" ]]; then
    export STARSHIP_CONFIG="$HOME/.config/starship-tty.toml"
else
    export STARSHIP_CONFIG="$HOME/.config/starship.toml"
fi

# ---- Wayland session vars ----------------------------------------------------
export QT_QPA_PLATFORM="wayland;xcb"
export GDK_BACKEND=wayland,x11
export MOZ_ENABLE_WAYLAND=1
export ELECTRON_OZONE_PLATFORM_HINT=wayland
export _JAVA_AWT_WM_NONREPARENTING=1
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland

# ---- Auto-launch Hyprland on TTY1 only --------------------------------------
# Press any key to launch within 5s, otherwise stay in TTY.
# Other TTYs (2-6) always remain raw shell.

if [[ -z "$WAYLAND_DISPLAY" && "$XDG_VTNR" == "1" && -z "$SSH_TTY" ]]; then
    # Print a small Deco prompt
    print -P ""
    print -P "  %F{yellow}♠%f  %F{white}sheol://login%f"
    print -P "  %F{8}─────────────────%f"
    print -P "  %F{white}[Y/n]%f  enter Hyprland   %F{8}(5s → tty)%f"
    print -P ""

    if read -t 5 -k 1 reply; then
        echo
        if [[ "$reply" == "n" || "$reply" == "N" ]]; then
            print -P "  %F{8}staying in tty%f"
        else
            print -P "  %F{yellow}entering...%f"
            exec uwsm start hyprland-uwsm.desktop 2>/dev/null || exec Hyprland
        fi
    else
        echo
        print -P "  %F{8}timeout — staying in tty%f"
    fi
fi
