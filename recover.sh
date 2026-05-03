#!/usr/bin/env bash
# =============================================================================
#  SHEOL // recover.sh
#  Fixes the aftermath of a partial/failed install:
#  - Resolves stow conflicts (removes plain files, restows as symlinks)
#  - Installs Cinzel + Cinzel Decorative from GitHub (bypasses Google Fonts API)
#  - Verifies everything ended up where it should
# =============================================================================

set -u

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
echo -e "${GILT}    ♠  SHEOL recovery${RESET}"
echo -e "${LINEN}    ───────────────────────${RESET}"
echo

# ---- Find the dotfiles repo -------------------------------------------------
# Try common locations
DOTS=""
for candidate in \
    "$HOME/sheol-dots" \
    "$HOME/arch-dot-files/sheol-dots" \
    "$HOME/arch-dot-files" \
    "$(pwd)" \
    "$(pwd)/sheol-dots"
do
    if [ -d "$candidate/pkgs" ]; then
        DOTS="$candidate"
        break
    fi
done

if [ -z "$DOTS" ]; then
    warn "couldn't find sheol-dots repo (looked in ~/sheol-dots, ~/arch-dot-files, etc)"
    warn "cd into the repo first, then re-run this script"
    exit 1
fi

step "found dotfiles at: $DOTS"
echo

# ---- Resolve stow conflicts -------------------------------------------------
step "clearing stow conflicts (removing leftover files from partial install)"

# These are the targets the stow packages place into $HOME.
# We remove them whether they're files, dirs, or broken symlinks — stow recreates them.
for path in \
    "$HOME/.config/hypr" \
    "$HOME/.config/waybar" \
    "$HOME/.config/rofi" \
    "$HOME/.config/swaync" \
    "$HOME/.config/ghostty" \
    "$HOME/.config/kitty" \
    "$HOME/.config/fastfetch" \
    "$HOME/.config/starship.toml" \
    "$HOME/.config/starship-tty.toml" \
    "$HOME/.zshrc" \
    "$HOME/.zprofile"
do
    if [ -e "$path" ] || [ -L "$path" ]; then
        rm -rf "$path"
        info "cleared $path"
    fi
done
echo

# ---- Restow everything ------------------------------------------------------
step "stowing dotfiles"
cd "$DOTS/pkgs" || exit 1

for pkg in hypr waybar rofi swaync starship ghostty fastfetch zsh; do
    if [ ! -d "$pkg" ]; then
        warn "stow $pkg: package directory missing"
        continue
    fi
    if stow -t "$HOME" "$pkg" 2>/dev/null; then
        ok "stow $pkg"
    else
        warn "stow $pkg failed even after cleanup — running with -v for details:"
        stow -t "$HOME" -v "$pkg" 2>&1 | head -10
    fi
done
echo

# ---- Verify scripts directory and roman_clock.py ----------------------------
step "verifying scripts"
mkdir -p "$HOME/.config/hypr/scripts"
if [ -f "$DOTS/scripts/roman_clock.py" ]; then
    cp "$DOTS/scripts/roman_clock.py" "$HOME/.config/hypr/scripts/roman_clock.py"
    chmod +x "$HOME/.config/hypr/scripts/roman_clock.py"
    if "$HOME/.config/hypr/scripts/roman_clock.py" --time >/dev/null 2>&1; then
        ok "roman_clock.py works ($("$HOME/.config/hypr/scripts/roman_clock.py" --time))"
    else
        warn "roman_clock.py installed but errored on test run"
    fi
fi
echo

# ---- Wallpaper check --------------------------------------------------------
step "wallpaper status"
if [ -f "$HOME/.config/hypr/wallpaper.png" ]; then
    size=$(stat -c %s "$HOME/.config/hypr/wallpaper.png" 2>/dev/null || echo 0)
    if [ "$size" -lt 1000 ]; then
        info "wallpaper.png is $size bytes — that's the placeholder, replace with real one"
    else
        ok "wallpaper.png in place ($(numfmt --to=iec "$size"))"
    fi
else
    warn "no wallpaper at ~/.config/hypr/wallpaper.png"
    info "  drop your generated wallpaper there before launching Hyprland"
fi
echo

# ---- Install Cinzel + Cinzel Decorative from GitHub ------------------------
step "installing Cinzel fonts from Google Fonts GitHub (bypassing fonts.google.com)"

FONT_DIR="$HOME/.local/share/fonts/sheol"
mkdir -p "$FONT_DIR/Cinzel" "$FONT_DIR/Cinzel-Decorative"

# Cinzel — variable font (single file, all weights)
if ! fc-list 2>/dev/null | grep -q "Cinzel:"; then
    info "downloading Cinzel"
    if curl -fsSL -o "$FONT_DIR/Cinzel/Cinzel.ttf" \
        "https://github.com/google/fonts/raw/main/ofl/cinzel/Cinzel%5Bwght%5D.ttf"; then
        if file "$FONT_DIR/Cinzel/Cinzel.ttf" 2>/dev/null | grep -q "TrueType"; then
            ok "Cinzel installed"
        else
            warn "Cinzel download not a valid font file"
            rm -f "$FONT_DIR/Cinzel/Cinzel.ttf"
        fi
    else
        warn "Cinzel download failed"
    fi
else
    info "Cinzel already installed"
fi

# Cinzel Decorative — three discrete weights
if ! fc-list 2>/dev/null | grep -q "Cinzel Decorative"; then
    info "downloading Cinzel Decorative"
    failed=0
    for weight in Regular Bold Black; do
        if ! curl -fsSL -o "$FONT_DIR/Cinzel-Decorative/CinzelDecorative-${weight}.ttf" \
            "https://github.com/google/fonts/raw/main/ofl/cinzeldecorative/CinzelDecorative-${weight}.ttf"; then
            failed=1
        fi
    done
    if [ $failed -eq 0 ]; then
        ok "Cinzel Decorative installed (3 weights)"
    else
        warn "Cinzel Decorative: some weights failed"
    fi
else
    info "Cinzel Decorative already installed"
fi

# Cormorant Garamond — backup install in case the original failed too
if ! fc-list 2>/dev/null | grep -q "Cormorant Garamond"; then
    info "downloading Cormorant Garamond"
    mkdir -p "$FONT_DIR/Cormorant-Garamond"
    failed=0
    for weight in Light Regular Medium SemiBold Bold; do
        for style in "" "Italic"; do
            fname="CormorantGaramond-${weight}${style}.ttf"
            if ! curl -fsSL -o "$FONT_DIR/Cormorant-Garamond/$fname" \
                "https://github.com/google/fonts/raw/main/ofl/cormorantgaramond/$fname"; then
                failed=$((failed + 1))
            fi
        done
    done
    if [ $failed -lt 5 ]; then
        ok "Cormorant Garamond installed"
    else
        warn "Cormorant Garamond: many weights failed"
    fi
else
    info "Cormorant Garamond already installed"
fi

# Refresh font cache
fc-cache -f >/dev/null 2>&1
echo

# ---- Final verification -----------------------------------------------------
step "verification"
echo

verify() {
    local label="$1"
    local check="$2"
    if eval "$check" >/dev/null 2>&1; then
        ok "$label"
    else
        warn "$label"
    fi
}

verify "Hyprland binary"        "command -v Hyprland"
verify "Waybar binary"          "command -v waybar"
verify "Rofi binary"            "command -v rofi"
verify "Ghostty binary"         "command -v ghostty"
verify "Starship binary"        "command -v starship"
verify "Hyprland config"        "[ -f $HOME/.config/hypr/hyprland.conf ]"
verify "Hyprlock config"        "[ -f $HOME/.config/hypr/hyprlock.conf ]"
verify "Waybar top.jsonc"       "[ -f $HOME/.config/waybar/top.jsonc ]"
verify "Waybar bottom.jsonc"    "[ -f $HOME/.config/waybar/bottom.jsonc ]"
verify "Rofi missal.rasi"       "[ -f $HOME/.config/rofi/missal.rasi ]"
verify "Roman clock script"     "[ -x $HOME/.config/hypr/scripts/roman_clock.py ]"
verify ".zprofile"              "[ -L $HOME/.zprofile ]"
verify ".zshrc"                 "[ -L $HOME/.zshrc ]"
verify "wallpaper.png"          "[ -f $HOME/.config/hypr/wallpaper.png ]"
verify "Cinzel font"            "fc-list | grep -q Cinzel:"
verify "Cinzel Decorative"      "fc-list | grep -q 'Cinzel Decorative'"
verify "Cormorant Garamond"     "fc-list | grep -q 'Cormorant Garamond'"
verify "JetBrains Mono Nerd"    "fc-list | grep -qi 'JetBrainsMono Nerd'"

echo
echo -e "${GILT}  ◆${RESET}  ${BONE}recovery complete${RESET}"
echo
echo -e "${BONE}  to launch Hyprland:${RESET}"
echo -e "${LINEN}    type 'exit' to log out, then log back in on TTY1${RESET}"
echo -e "${LINEN}    follow the [Y/n] prompt to enter Hyprland${RESET}"
echo
echo -e "${HALO}  ♠${RESET}  ${BONE}memento ludere${RESET}"
echo
