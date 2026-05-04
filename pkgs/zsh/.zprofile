# =============================================================================
#  SHEOL // .zprofile
#  Dual-mode boot: TTY by default, optional Hyprland launch on TTY1.
#  Launcher logs failures to /tmp/hyprland.log; never loops back to login.
# =============================================================================

# ---- Environment -------------------------------------------------------------
export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export BROWSER=firefox
export TERMINAL=kitty

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

# ---- Hyprland launcher on TTY1 ----------------------------------------------
# Press Y within 5s to launch, otherwise stay in TTY.
# On Hyprland exit (success OR failure), drop to shell — never re-loop.

if [[ -z "$WAYLAND_DISPLAY" && "$XDG_VTNR" == "1" && -z "$SSH_TTY" ]]; then
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
            print -P "  %F{yellow}starting Hyprland...%f"
            echo

            # Try uwsm first (proper systemd integration), then bare Hyprland.
            # Capture output so we can see what failed.
            if command -v uwsm >/dev/null 2>&1; then
                uwsm start hyprland-uwsm.desktop > /tmp/hyprland.log 2>&1
            else
                Hyprland > /tmp/hyprland.log 2>&1
            fi

            EXIT=$?
            echo
            print -P "  %F{8}Hyprland exited (code $EXIT)%f"
            print -P "  %F{8}log: /tmp/hyprland.log%f"
            print -P "  %F{8}─────────────────%f"
            echo

            if [ $EXIT -ne 0 ] && [ -f /tmp/hyprland.log ]; then
                print -P "  %F{red}last lines of log:%f"
                tail -10 /tmp/hyprland.log
                echo
            fi
        fi
    else
        echo
        print -P "  %F{8}timeout — staying in tty%f"
    fi
fi
