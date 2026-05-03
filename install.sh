#!/usr/bin/env bash
# =============================================================================
#  SHEOL // install.sh  v3
#  Build the rice. Calibrated for Arch Linux.
#
#  Resilient: individual package installs (one bad apple doesn't kill the run),
#  fonts installed directly from Google Fonts (avoids AUR name churn),
#  AUR packages opt-in (no interactive provider prompts).
# =============================================================================

# NB: no `set -e` — we want to continue on individual failures and report.
set -u

GILT='\033[38;2;160;130;64m'
HALO='\033[38;2;232;200;112m'
BONE='\033[38;2;184;174;160m'
LINEN='\033[38;2;107;100;112m'
SANCTUS='\033[38;2;90;26;26m'
RESET='\033[0m'

banner() {
    echo
    echo -e "${GILT}    ♠  SHEOL${RESET}  ${LINEN}// tarnished reliquary${RESET}"
    echo -e "${LINEN}    ───────────────────────────────${RESET}"
    echo
}

step()    { echo -e "${HALO}  ▸${RESET} ${BONE}$1${RESET}"; }
ok()      { echo -e "${GILT}  ✓${RESET} ${BONE}$1${RESET}"; }
warn()    { echo -e "${SANCTUS}  ✘${RESET} ${BONE}$1${RESET}"; }
info()    { echo -e "${LINEN}    $1${RESET}"; }

# Track failures so we can report them at the end.
FAILED_PKGS=()
FAILED_AUR=()
FAILED_STEPS=()

banner

# ---- Sanity checks ----------------------------------------------------------
if ! command -v pacman >/dev/null 2>&1; then
    warn "this script is for Arch. abort."
    exit 1
fi

if [[ "$EUID" == 0 ]]; then
    warn "do not run as root. run as your user; sudo will be invoked when needed."
    exit 1
fi

# ---- AUR helper detection ---------------------------------------------------
AUR=""
if command -v paru >/dev/null 2>&1; then
    AUR="paru"
elif command -v yay >/dev/null 2>&1; then
    AUR="yay"
else
    step "no AUR helper found — installing paru"
    sudo pacman -S --needed --noconfirm base-devel git
    if [ ! -d /tmp/paru ]; then
        git clone https://aur.archlinux.org/paru.git /tmp/paru
    fi
    if (cd /tmp/paru && makepkg -si --noconfirm); then
        AUR="paru"
        ok "paru installed"
    else
        warn "paru install failed — AUR packages will be skipped"
        FAILED_STEPS+=("paru install")
    fi
fi

if [ -n "$AUR" ]; then
    step "AUR helper: $AUR"
fi

# ---- Pacman: install one at a time -----------------------------------------
# Why individual? If even one package isn't in repos, a batch install aborts the
# whole thing. Per-package, a missing one is logged and the rest continue.
step "installing core packages (this may take a while)"
echo

PACMAN_PKGS=(
    # Compositor + ecosystem
    hyprland hyprlock hypridle hyprpicker hyprpolkitagent
    xdg-desktop-portal-hyprland
    polkit-gnome
    # Bar / launcher / notifications
    waybar rofi-wayland swaync
    # Wallpaper
    swww
    # Terminal + shell
    ghostty zsh starship fastfetch
    # Tools
    yazi neovim git stow
    eza bat ripgrep fd duf dust
    btop fzf
    # Audio
    pipewire pipewire-pulse wireplumber pavucontrol
    # Wayland utils
    wl-clipboard cliphist grim slurp
    brightnessctl playerctl
    # Fonts available in repos
    ttf-jetbrains-mono-nerd
    ttf-firacode-nerd
    terminus-font
    noto-fonts noto-fonts-emoji
    # Theming dependencies
    qt5ct qt6ct kvantum nwg-look
    # Python (for the roman_clock script)
    python
    # Optional but nice
    zsh-autosuggestions zsh-syntax-highlighting
    unzip curl
)

# Refresh pacman db once
sudo pacman -Sy --noconfirm >/dev/null 2>&1 || true

for pkg in "${PACMAN_PKGS[@]}"; do
    # Skip if already installed
    if pacman -Qi "$pkg" >/dev/null 2>&1; then
        info "$pkg (already installed)"
        continue
    fi
    if sudo pacman -S --needed --noconfirm "$pkg" >/dev/null 2>&1; then
        ok "$pkg"
    else
        warn "$pkg failed (not in repos, or conflict)"
        FAILED_PKGS+=("$pkg")
    fi
done

echo

# ---- AUR: optional packages, also one at a time ----------------------------
# These are decorative or convenience packages that the rice can live without.
# Picks the first provider non-interactively so paru doesn't stall.
if [ -n "$AUR" ]; then
    step "installing AUR packages (decorative — failures are non-fatal)"
    echo

    AUR_PKGS=(
        hyprshot
        bibata-cursor-theme-bin
        wlogout
    )

    for pkg in "${AUR_PKGS[@]}"; do
        if pacman -Qi "$pkg" >/dev/null 2>&1; then
            info "$pkg (already installed)"
            continue
        fi
        if $AUR -S --needed --skipreview --noconfirm "$pkg" >/dev/null 2>&1; then
            ok "$pkg"
        else
            warn "$pkg failed (not in AUR right now, or build error)"
            FAILED_AUR+=("$pkg")
        fi
    done
    echo
fi

# ---- Fonts: install directly from Google Fonts -----------------------------
# Cinzel and Cormorant Garamond are required by the rice. AUR package names
# for these change frequently (ttf-cinzel, otf-cinzel-ofl, etc.), so we just
# fetch them directly. Installed per-user under ~/.local/share/fonts.
step "installing display fonts from Google Fonts"
echo

FONT_DIR="$HOME/.local/share/fonts/sheol"
mkdir -p "$FONT_DIR"

install_google_font() {
    local family="$1"
    local url_family="${family// /%20}"
    local zipfile="/tmp/sheol-font-${family// /-}.zip"

    if fc-list 2>/dev/null | grep -qi "$family"; then
        info "$family (already installed)"
        return 0
    fi

    info "downloading $family"
    if curl -sL -o "$zipfile" "https://fonts.google.com/download?family=$url_family"; then
        # Sanity check: must be a real zip, not an HTML error page
        if file "$zipfile" 2>/dev/null | grep -q "Zip archive"; then
            unzip -qo "$zipfile" -d "$FONT_DIR/${family// /-}"
            ok "$family installed"
        else
            warn "$family download was not a valid zip (Google Fonts changed?)"
            FAILED_STEPS+=("font: $family")
        fi
        rm -f "$zipfile"
    else
        warn "$family download failed (network?)"
        FAILED_STEPS+=("font: $family")
    fi
}

install_google_font "Cinzel"
install_google_font "Cinzel Decorative"
install_google_font "Cormorant Garamond"

# Refresh font cache so apps see the new fonts immediately
fc-cache -f >/dev/null 2>&1
echo

# ---- Stow the dotfiles ------------------------------------------------------
step "stowing dotfiles"
echo

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$DOTS_DIR/pkgs"

if [ ! -d "$PKG_DIR" ]; then
    warn "no pkgs/ directory found at $PKG_DIR"
    warn "the repo may be incomplete — stop and check git status"
    FAILED_STEPS+=("stow: pkgs/ missing")
else
    cd "$PKG_DIR" || exit 1
    for pkg in hypr waybar rofi swaync starship ghostty fastfetch zsh; do
        if [ ! -d "$pkg" ]; then
            warn "stow $pkg: directory missing in pkgs/"
            FAILED_STEPS+=("stow: $pkg missing")
            continue
        fi
        # -R for restow (handles pre-existing symlinks gracefully).
        if stow -t "$HOME" -R "$pkg" 2>/dev/null; then
            ok "stow $pkg"
        else
            # Try regular stow (first-time, no -R)
            if stow -t "$HOME" "$pkg" 2>/dev/null; then
                ok "stow $pkg"
            else
                warn "stow $pkg failed (conflict with existing file?)"
                info "  fix: rm any conflicting files in ~ and re-run, or stow --adopt manually"
                FAILED_STEPS+=("stow: $pkg conflict")
            fi
        fi
    done
fi
echo

# ---- Wallpaper --------------------------------------------------------------
step "installing wallpaper assets"
WALLPAPER_TARGET="$HOME/.config/hypr/wallpaper.png"
if [ -f "$DOTS_DIR/assets/wallpaper.png" ]; then
    cp "$DOTS_DIR/assets/wallpaper.png" "$WALLPAPER_TARGET"
    ok "wallpaper.png installed"
else
    info "no wallpaper at assets/wallpaper.png — drop yours there and re-run, or:"
    info "  cp /path/to/wallpaper.png ~/.config/hypr/wallpaper.png"
    mkdir -p "$(dirname "$WALLPAPER_TARGET")"
    if command -v convert >/dev/null 2>&1; then
        convert -size 1920x1080 xc:'#050507' "$WALLPAPER_TARGET" 2>/dev/null && \
            ok "fallback solid-black wallpaper generated"
    else
        # 1x1 black PNG as last-resort placeholder so swww doesn't fail
        echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=" | \
            base64 -d > "$WALLPAPER_TARGET" 2>/dev/null && \
            ok "1x1 fallback wallpaper generated (replace with your real one)"
    fi
fi

SPADE_TARGET="$HOME/.config/hypr/spade.png"
if [ -f "$DOTS_DIR/assets/spade.png" ]; then
    cp "$DOTS_DIR/assets/spade.png" "$SPADE_TARGET"
    ok "spade.png installed"
else
    info "no spade.png — hyprlock will skip the centerpiece image"
fi
echo

# ---- Scripts ----------------------------------------------------------------
step "installing scripts"
SCRIPTS_TARGET="$HOME/.config/hypr/scripts"
mkdir -p "$SCRIPTS_TARGET"
if [ -f "$DOTS_DIR/scripts/roman_clock.py" ]; then
    cp "$DOTS_DIR/scripts/roman_clock.py" "$SCRIPTS_TARGET/roman_clock.py"
    chmod +x "$SCRIPTS_TARGET/roman_clock.py"
    ok "roman_clock.py installed"
else
    warn "scripts/roman_clock.py not found"
    FAILED_STEPS+=("scripts: roman_clock.py missing")
fi
echo

# ---- TTY palette ------------------------------------------------------------
step "installing TTY palette and console font"
sudo mkdir -p /etc/sheol
if [ -f "$DOTS_DIR/system/setvtrgb-palette.txt" ]; then
    sudo cp "$DOTS_DIR/system/setvtrgb-palette.txt" /etc/sheol/
    ok "TTY palette file installed at /etc/sheol/"
fi
if [ -f "$DOTS_DIR/system/vconsole.conf" ]; then
    sudo cp "$DOTS_DIR/system/vconsole.conf" /etc/vconsole.conf
    ok "vconsole.conf installed"
fi
if [ -f "$DOTS_DIR/system/sheol-tty-palette.service" ]; then
    sudo cp "$DOTS_DIR/system/sheol-tty-palette.service" /etc/systemd/system/
    sudo systemctl daemon-reload
    ok "sheol-tty-palette.service installed"

    echo
    read -r -p "    enable sheol-tty-palette.service for boot? [Y/n] " enable_tty
    if [[ ! "$enable_tty" =~ ^[Nn]$ ]]; then
        sudo systemctl enable sheol-tty-palette.service >/dev/null 2>&1
        sudo systemctl start sheol-tty-palette.service 2>/dev/null || \
            info "  service start deferred to next boot"
        ok "service enabled"
    fi
fi
echo

# ---- Default shell ----------------------------------------------------------
if [[ "$SHELL" != *"zsh"* ]]; then
    read -r -p "    set zsh as default shell? [Y/n] " set_zsh
    if [[ ! "$set_zsh" =~ ^[Nn]$ ]]; then
        chsh -s "$(which zsh)" && ok "default shell set to zsh"
    fi
else
    info "zsh already the default shell"
fi

# ---- Boot target ------------------------------------------------------------
echo
read -r -p "    set boot target to multi-user (TTY by default, GUI on demand)? [Y/n] " set_target
if [[ ! "$set_target" =~ ^[Nn]$ ]]; then
    sudo systemctl set-default multi-user.target >/dev/null 2>&1
    ok "default target = multi-user"
    info "Hyprland launches via .zprofile prompt on TTY1"
    info "to revert: sudo systemctl set-default graphical.target"
fi
echo

# ---- Summary ----------------------------------------------------------------
echo -e "${GILT}  ◆${RESET}  ${BONE}installation complete${RESET}"
echo

if [ ${#FAILED_PKGS[@]} -gt 0 ]; then
    warn "pacman packages that failed (${#FAILED_PKGS[@]}):"
    for p in "${FAILED_PKGS[@]}"; do
        info "  - $p"
    done
    echo
fi

if [ ${#FAILED_AUR[@]} -gt 0 ]; then
    warn "AUR packages that failed (${#FAILED_AUR[@]}):"
    for p in "${FAILED_AUR[@]}"; do
        info "  - $p"
    done
    info "these are decorative — the rice will work without them"
    echo
fi

if [ ${#FAILED_STEPS[@]} -gt 0 ]; then
    warn "other steps that had issues (${#FAILED_STEPS[@]}):"
    for s in "${FAILED_STEPS[@]}"; do
        info "  - $s"
    done
    echo
fi

if [ ${#FAILED_PKGS[@]} -eq 0 ] && [ ${#FAILED_AUR[@]} -eq 0 ] && [ ${#FAILED_STEPS[@]} -eq 0 ]; then
    echo -e "${HALO}  ♠${RESET}  ${BONE}no failures — clean install${RESET}"
    echo
fi

echo -e "${BONE}  next steps:${RESET}"
echo -e "${LINEN}  · log out / reboot${RESET}"
echo -e "${LINEN}  · drop your wallpaper at ~/.config/hypr/wallpaper.png${RESET}"
echo -e "${LINEN}  · drop your spade.png at ~/.config/hypr/spade.png (optional)${RESET}"
echo -e "${LINEN}  · log into TTY1, follow the prompt to launch Hyprland${RESET}"
echo
echo -e "${HALO}  ♠${RESET}  ${BONE}memento ludere${RESET}"
echo
