#!/usr/bin/env bash
# =============================================================================
#  SHEOL // install.sh
#  Builds the rice on Arch Linux. Resilient: per-package installs (one bad
#  apple doesn't kill the run), fonts via Google Fonts (avoids AUR churn),
#  AUR packages opt-in.
# =============================================================================

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

[ -n "$AUR" ] && step "AUR helper: $AUR"

# ---- Pacman packages: one at a time ----------------------------------------
step "installing core packages"
echo

PACMAN_PKGS=(
    # Compositor + ecosystem
    hyprland hyprlock hypridle hyprpicker hyprpolkitagent
    xdg-desktop-portal-hyprland
    xorg-xwayland
    polkit-gnome
    # Bar / launcher / notifications
    waybar rofi-wayland swaync
    # Wallpaper (renamed from swww in Oct 2025)
    awww
    # Terminal + shell
    kitty zsh starship fastfetch
    # Tools
    yazi neovim git stow
    eza bat ripgrep fd duf dust
    btop fzf
    # Audio
    pipewire pipewire-pulse wireplumber pavucontrol
    # Wayland utils
    wl-clipboard cliphist grim slurp
    brightnessctl playerctl
    # Fonts in repos
    ttf-jetbrains-mono-nerd
    ttf-firacode-nerd
    terminus-font
    noto-fonts noto-fonts-emoji
    # Theming deps
    qt5ct qt6ct kvantum nwg-look
    # Python (roman_clock script)
    python
    # Convenience
    zsh-autosuggestions zsh-syntax-highlighting
    unzip curl
)

sudo pacman -Sy --noconfirm >/dev/null 2>&1 || true

for pkg in "${PACMAN_PKGS[@]}"; do
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

# ---- AUR packages: optional, non-fatal -------------------------------------
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
            warn "$pkg failed"
            FAILED_AUR+=("$pkg")
        fi
    done
    echo
fi

# ---- Display fonts via Google Fonts GitHub mirror --------------------------
# fonts.google.com/download has gotten flaky with non-browser User-Agents.
# Pull from the official Google Fonts GitHub mirror instead.
step "installing display fonts (Cinzel, Cinzel Decorative, Cormorant Garamond)"
echo

FONT_DIR="$HOME/.local/share/fonts/sheol"
mkdir -p "$FONT_DIR/Cinzel" "$FONT_DIR/Cinzel-Decorative" "$FONT_DIR/Cormorant-Garamond"

# Cinzel (variable font, all weights in one file)
if ! fc-list 2>/dev/null | grep -q "Cinzel:"; then
    info "downloading Cinzel"
    if curl -fsSL -o "$FONT_DIR/Cinzel/Cinzel.ttf" \
        "https://github.com/google/fonts/raw/main/ofl/cinzel/Cinzel%5Bwght%5D.ttf" 2>/dev/null; then
        ok "Cinzel"
    else
        warn "Cinzel download failed"
        FAILED_STEPS+=("font: Cinzel")
    fi
else
    info "Cinzel (already installed)"
fi

# Cinzel Decorative — three discrete weights
if ! fc-list 2>/dev/null | grep -q "Cinzel Decorative"; then
    info "downloading Cinzel Decorative"
    failed=0
    for weight in Regular Bold Black; do
        curl -fsSL -o "$FONT_DIR/Cinzel-Decorative/CinzelDecorative-${weight}.ttf" \
            "https://github.com/google/fonts/raw/main/ofl/cinzeldecorative/CinzelDecorative-${weight}.ttf" \
            2>/dev/null || failed=1
    done
    [ $failed -eq 0 ] && ok "Cinzel Decorative" || \
        { warn "Cinzel Decorative: some weights failed"; FAILED_STEPS+=("font: Cinzel Decorative"); }
else
    info "Cinzel Decorative (already installed)"
fi

# Cormorant Garamond — 5 weights × 2 styles
if ! fc-list 2>/dev/null | grep -q "Cormorant Garamond"; then
    info "downloading Cormorant Garamond"
    failed=0
    for weight in Light Regular Medium SemiBold Bold; do
        for style in "" "Italic"; do
            fname="CormorantGaramond-${weight}${style}.ttf"
            curl -fsSL -o "$FONT_DIR/Cormorant-Garamond/$fname" \
                "https://github.com/google/fonts/raw/main/ofl/cormorantgaramond/$fname" \
                2>/dev/null || failed=$((failed + 1))
        done
    done
    [ $failed -lt 3 ] && ok "Cormorant Garamond" || \
        { warn "Cormorant Garamond: many weights failed"; FAILED_STEPS+=("font: Cormorant Garamond"); }
else
    info "Cormorant Garamond (already installed)"
fi

fc-cache -f >/dev/null 2>&1
echo

# ---- Stow dotfiles ----------------------------------------------------------
step "stowing dotfiles"
echo

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$DOTS_DIR/pkgs"

if [ ! -d "$PKG_DIR" ]; then
    warn "no pkgs/ directory — repo incomplete"
    FAILED_STEPS+=("stow: pkgs/ missing")
else
    cd "$PKG_DIR" || exit 1

    # Pre-clean: useradd deploys skel files (.zshrc, .zprofile, .bashrc, etc)
    # that block stow. Backup any non-symlink defaults so stow can deploy fresh.
    SKEL_FILES=(
        "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.zlogin" "$HOME/.zlogout"
        "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.bash_logout"
        "$HOME/.profile"
    )
    for f in "${SKEL_FILES[@]}"; do
        if [ -f "$f" ] && [ ! -L "$f" ]; then
            mv "$f" "$f.skel-backup-$(date +%s)"
        fi
    done

    for pkg in hypr waybar rofi swaync starship kitty ghostty fastfetch zsh nvim; do
        if [ ! -d "$pkg" ]; then
            info "$pkg (no source dir, skipping)"
            continue
        fi

        # Try restow first (idempotent)
        if stow -t "$HOME" -R "$pkg" 2>/dev/null; then
            ok "stow $pkg"
            continue
        fi

        # Conflict — try to identify what's in the way
        STOW_ERR=$(stow -t "$HOME" -n "$pkg" 2>&1)
        CONFLICT_FILES=$(echo "$STOW_ERR" | grep -oE '\* existing target is.+: \S+' | awk '{print $NF}')

        # If there are conflicts, check if they're identical to repo files (safe to replace)
        # or different (back them up before overwriting)
        if [ -n "$CONFLICT_FILES" ]; then
            for cf in $CONFLICT_FILES; do
                target="$HOME/$cf"
                source="$PKG_DIR/$pkg/$cf"
                if [ -f "$target" ] && [ -f "$source" ]; then
                    if ! cmp -s "$target" "$source"; then
                        # Different — back up
                        mv "$target" "$target.before-stow-$(date +%s)"
                        info "  backed up $target (different from repo version)"
                    else
                        # Same content — just remove so stow can symlink
                        rm "$target"
                    fi
                fi
            done

            # Retry stow now that conflicts are resolved
            if stow -t "$HOME" -R "$pkg" 2>/dev/null; then
                ok "stow $pkg (after backing up $(echo "$CONFLICT_FILES" | wc -w) conflict(s))"
                continue
            fi
        fi

        # Last resort: --adopt then restow (pulls existing files into the repo,
        # then symlinks back). We don't actually want to modify the repo, so
        # we copy the package files directly instead.
        warn "stow $pkg conflict — falling back to direct copy"
        find "$pkg" -type f -not -path '*/\.git/*' | while read -r srcfile; do
            relpath="${srcfile#$pkg/}"
            destfile="$HOME/$relpath"
            mkdir -p "$(dirname "$destfile")"
            cp "$srcfile" "$destfile"
        done
        ok "$pkg (copied directly)"
    done
fi
echo

# ---- Wallpaper --------------------------------------------------------------
step "installing wallpaper"
WALLPAPER_TARGET="$HOME/.config/hypr/wallpaper.png"
mkdir -p "$(dirname "$WALLPAPER_TARGET")"

if [ -f "$DOTS_DIR/assets/wallpaper.png" ]; then
    SRC_SIZE=$(stat -c%s "$DOTS_DIR/assets/wallpaper.png" 2>/dev/null || echo 0)
    if cp "$DOTS_DIR/assets/wallpaper.png" "$WALLPAPER_TARGET"; then
        DST_SIZE=$(stat -c%s "$WALLPAPER_TARGET" 2>/dev/null || echo 0)
        if [ "$SRC_SIZE" -eq "$DST_SIZE" ] && [ "$DST_SIZE" -gt 1000 ]; then
            ok "wallpaper.png installed (${DST_SIZE} bytes)"
        else
            warn "wallpaper copy size mismatch (src=$SRC_SIZE dst=$DST_SIZE)"
            FAILED_STEPS+=("wallpaper: size mismatch")
        fi
    else
        warn "wallpaper.png copy failed"
        FAILED_STEPS+=("wallpaper: cp failed")
    fi
else
    info "no wallpaper at assets/wallpaper.png — generating fallback"
    if command -v convert >/dev/null 2>&1; then
        convert -size 1920x1080 xc:'#050507' "$WALLPAPER_TARGET" 2>/dev/null && \
            ok "fallback solid-black wallpaper"
    else
        # 1x1 black PNG as last-resort placeholder so awww doesn't fail
        echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=" | \
            base64 -d > "$WALLPAPER_TARGET" 2>/dev/null && \
            ok "1x1 fallback wallpaper (replace with real one)"
    fi
fi

if [ -f "$DOTS_DIR/assets/spade.png" ]; then
    cp "$DOTS_DIR/assets/spade.png" "$HOME/.config/hypr/spade.png"
    ok "spade.png installed"
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
fi
echo

# ---- TTY palette + console font --------------------------------------------
step "installing TTY palette"
sudo mkdir -p /etc/sheol
[ -f "$DOTS_DIR/system/setvtrgb-palette.txt" ] && \
    sudo cp "$DOTS_DIR/system/setvtrgb-palette.txt" /etc/sheol/ && ok "palette file"
[ -f "$DOTS_DIR/system/vconsole.conf" ] && \
    sudo cp "$DOTS_DIR/system/vconsole.conf" /etc/vconsole.conf && ok "vconsole.conf"
if [ -f "$DOTS_DIR/system/sheol-tty-palette.service" ]; then
    sudo cp "$DOTS_DIR/system/sheol-tty-palette.service" /etc/systemd/system/
    sudo systemctl daemon-reload
    ok "sheol-tty-palette.service"

    echo
    read -r -p "    enable sheol-tty-palette.service for boot? [Y/n] " enable_tty
    if [[ ! "$enable_tty" =~ ^[Nn]$ ]]; then
        sudo systemctl enable sheol-tty-palette.service >/dev/null 2>&1
        sudo systemctl start sheol-tty-palette.service 2>/dev/null || true
        ok "service enabled"
    fi
fi
echo

# ---- Default shell ----------------------------------------------------------
if [[ "$SHELL" != *"zsh"* ]]; then
    read -r -p "    set zsh as default shell? [Y/n] " set_zsh
    if [[ ! "$set_zsh" =~ ^[Nn]$ ]]; then
        chsh -s "$(which zsh)" && ok "default shell: zsh"
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
fi
echo

# ---- Verification — make sure critical files actually landed --------------
step "verification"
VERIFY_FAILED=0
verify() {
    local label="$1" path="$2"
    if [ -f "$path" ] || [ -L "$path" ]; then
        ok "$label"
    else
        warn "$label MISSING ($path)"
        VERIFY_FAILED=1
        FAILED_STEPS+=("missing: $path")
    fi
}
verify ".zshrc"           "$HOME/.zshrc"
verify ".zprofile"        "$HOME/.zprofile"
verify "hyprland.conf"    "$HOME/.config/hypr/hyprland.conf"
verify "hypr/colors.conf" "$HOME/.config/hypr/colors.conf"
verify "wallpaper.png"    "$HOME/.config/hypr/wallpaper.png"
verify "waybar/top.jsonc" "$HOME/.config/waybar/top.jsonc"
verify "waybar/style.css" "$HOME/.config/waybar/style.css"
verify "kitty.conf"       "$HOME/.config/kitty/kitty.conf"
verify "fastfetch config" "$HOME/.config/fastfetch/config.jsonc"

# Verify .zshrc has the fastfetch greeting
if [ -f "$HOME/.zshrc" ] && ! grep -q "fastfetch" "$HOME/.zshrc"; then
    warn ".zshrc missing fastfetch greeting (might be skel default)"
    info "  fix: rm ~/.zshrc && cd $DOTS_DIR/pkgs && stow -t \$HOME zsh"
    VERIFY_FAILED=1
fi
echo

# ---- Summary ----------------------------------------------------------------
echo -e "${GILT}  ◆${RESET}  ${BONE}installation complete${RESET}"
echo

[ ${#FAILED_PKGS[@]} -gt 0 ] && {
    warn "pacman failures (${#FAILED_PKGS[@]}):"
    printf '    - %s\n' "${FAILED_PKGS[@]}"
    echo
}

[ ${#FAILED_AUR[@]} -gt 0 ] && {
    warn "AUR failures (${#FAILED_AUR[@]}) — decorative, non-fatal:"
    printf '    - %s\n' "${FAILED_AUR[@]}"
    echo
}

[ ${#FAILED_STEPS[@]} -gt 0 ] && {
    warn "other issues (${#FAILED_STEPS[@]}):"
    printf '    - %s\n' "${FAILED_STEPS[@]}"
    echo
}

if [ ${#FAILED_PKGS[@]} -eq 0 ] && [ ${#FAILED_AUR[@]} -eq 0 ] && [ ${#FAILED_STEPS[@]} -eq 0 ]; then
    echo -e "${HALO}  ♠${RESET}  ${BONE}no failures — clean install${RESET}"
    echo
fi

echo -e "${BONE}  next steps:${RESET}"
echo -e "${LINEN}  · log out / reboot${RESET}"
echo -e "${LINEN}  · drop your wallpaper at ~/.config/hypr/wallpaper.png${RESET}"
echo -e "${LINEN}  · log into TTY1 and follow the prompt to enter Hyprland${RESET}"
echo
echo -e "${HALO}  ♠${RESET}  ${BONE}memento ludere${RESET}"
echo
