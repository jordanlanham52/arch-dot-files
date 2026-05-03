#!/usr/bin/env bash
# =============================================================================
#  SHEOL // fix-zprofile.sh
#  Replaces the broken Hyprland launcher in .zprofile with one that:
#    - doesn't loop infinitely on failure
#    - logs to /tmp/hyprland.log so we can see why it's failing
#    - drops you back to a shell instead of re-prompting
#
#  Run from any TTY/terminal — the script auto-finds the .zprofile via stow.
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
echo -e "${GILT}    ♠  fixing zprofile launcher${RESET}"
echo

# Find the dotfiles repo
DOTS=""
for c in "$HOME/sheol-dots" "$HOME/arch-dot-files/sheol-dots" "$HOME/arch-dot-files" "$(pwd)"; do
    if [ -f "$c/pkgs/zsh/.zprofile" ]; then
        DOTS="$c"; break
    fi
done

if [ -z "$DOTS" ]; then
    warn "couldn't find sheol-dots/pkgs/zsh/.zprofile"
    exit 1
fi

ZPROFILE="$DOTS/pkgs/zsh/.zprofile"
step "found at: $ZPROFILE"

# Diagnose what's available before patching
echo
step "checking what's installed:"
if command -v uwsm >/dev/null 2>&1; then
    info "  uwsm: present"
    UWSM_OK=true
else
    info "  uwsm: NOT installed (was the silent failure)"
    UWSM_OK=false
fi
if command -v Hyprland >/dev/null 2>&1; then
    info "  Hyprland: $(command -v Hyprland)"
else
    warn "  Hyprland: NOT installed — this is a bigger problem"
fi
echo

# Backup
step "backing up old .zprofile"
cp "$ZPROFILE" "$ZPROFILE.bak.$(date +%s)"
ok "backup saved"

# Write the fixed .zprofile
step "writing new .zprofile (no-loop launcher)"

cat > "$ZPROFILE" << 'ZPROFILE_EOF'
# =============================================================================
#  SHEOL // .zprofile  v2
#  Dual-mode boot: TTY by default, optional Hyprland launch on TTY1.
#  Launcher logs failures to /tmp/hyprland.log and drops to shell, no loop.
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

# ---- Hyprland launcher on TTY1 ----------------------------------------------
# Press any key within 5s to launch, otherwise stay in TTY.
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
            # Capture output to a log so we can see what fails.
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

            # If exit was non-zero, show last lines of log so user sees the error
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
ZPROFILE_EOF

ok ".zprofile updated"
echo

# Verify the symlink is intact
if [ -L "$HOME/.zprofile" ]; then
    LINK_TARGET=$(readlink -f "$HOME/.zprofile")
    EXPECTED=$(readlink -f "$ZPROFILE")
    if [ "$LINK_TARGET" = "$EXPECTED" ]; then
        ok "~/.zprofile symlink is correct"
    else
        warn "~/.zprofile points to $LINK_TARGET (expected $EXPECTED)"
        info "  re-stowing to fix..."
        cd "$DOTS/pkgs"
        rm "$HOME/.zprofile"
        stow -t "$HOME" zsh && ok "re-stowed"
    fi
else
    warn "~/.zprofile is not a symlink"
    info "  removing and re-stowing..."
    rm -f "$HOME/.zprofile"
    cd "$DOTS/pkgs"
    stow -t "$HOME" zsh && ok "stowed"
fi
echo

echo -e "${GILT}  ◆${RESET}  ${BONE}done${RESET}"
echo
info "now:"
info "  1. log out:  exit"
info "  2. log back into TTY1 as your user"
info "  3. hit Y at the sheol://login prompt"
info "  4. either Hyprland starts, OR you see the error log"
info ""
info "no more infinite loop. if it fails, we'll see why."
echo
