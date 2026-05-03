#!/usr/bin/env bash
# =============================================================================
#  SHEOL // install.sh
#  Build the rice. Calibrated for Arch Linux.
# =============================================================================

set -euo pipefail

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

step() { echo -e "${HALO}  ▸${RESET} ${BONE}$1${RESET}"; }
warn() { echo -e "${SANCTUS}  ✘${RESET} ${BONE}$1${RESET}"; }
info() { echo -e "${LINEN}    $1${RESET}"; }

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
    (cd /tmp/paru && makepkg -si --noconfirm)
    AUR="paru"
fi

step "using AUR helper: $AUR"

# ---- Package installation ---------------------------------------------------
step "installing core packages"

PACMAN_PKGS=(
    # Compositor
    hyprland hyprlock hypridle hyprpicker hyprpolkitagent
    xdg-desktop-portal-hyprland
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
    # Fonts
    ttf-jetbrains-mono-nerd
    ttf-firacode-nerd
    terminus-font
    # Theming dependencies
    qt5ct qt6ct kvantum nwg-look
    # Python (for the roman_clock script)
    python
    # Optional but nice
    zsh-autosuggestions zsh-syntax-highlighting
)

sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

# ---- AUR packages ------------------------------------------------------------
step "installing AUR packages"

AUR_PKGS=(
    hyprshot
    ttf-cinzel
    ttf-cormorant
    bibata-cursor-theme
    catppuccin-gtk-theme-mocha     # base; we override with our CSS
    wlogout
)

$AUR -S --needed --noconfirm "${AUR_PKGS[@]}" || warn "some AUR packages failed — continuing"

# ---- Stow the dotfiles -------------------------------------------------------
step "stowing dotfiles"

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$DOTS_DIR/pkgs"

cd "$PKG_DIR"
for pkg in hypr waybar rofi swaync starship ghostty fastfetch zsh nvim; do
    info "stow $pkg"
    stow -t "$HOME" -R "$pkg" 2>/dev/null || stow -t "$HOME" "$pkg"
done

# ---- Wallpaper ---------------------------------------------------------------
WALLPAPER_TARGET="$HOME/.config/hypr/wallpaper.png"
if [ -f "$DOTS_DIR/assets/wallpaper.png" ]; then
    cp "$DOTS_DIR/assets/wallpaper.png" "$WALLPAPER_TARGET"
    info "wallpaper installed"
else
    warn "no wallpaper at assets/wallpaper.png — generating placeholder"
    # Generate a 1920x1080 abyss-black placeholder so swww doesn't fail on first boot
    if command -v magick >/dev/null 2>&1; then
        magick -size 1920x1080 xc:'#050507' "$WALLPAPER_TARGET"
    elif command -v convert >/dev/null 2>&1; then
        convert -size 1920x1080 xc:'#050507' "$WALLPAPER_TARGET"
    else
        # Fallback: a 1x1 PNG of pure abyss color, swww will tile/scale it
        printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0fIDATx\x9cc\x60\x60\x68\x05\xff\x0f\x00\x00\x12\x00\x05\xa1\x4a\xc8\xea\x00\x00\x00\x00IEND\xaeB\x60\x82' > "$WALLPAPER_TARGET" 2>/dev/null
    fi
    info "placeholder created — replace with your wallpaper at any time"
fi

# Same for spade.png used by hyprlock
SPADE_TARGET="$HOME/.config/hypr/spade.png"
if [ -f "$DOTS_DIR/assets/spade.png" ]; then
    cp "$DOTS_DIR/assets/spade.png" "$SPADE_TARGET"
    info "spade pip installed"
else
    warn "no spade.png — hyprlock will run without the centerpiece image"
fi

# ---- Make scripts executable -------------------------------------------------
SCRIPTS_TARGET="$HOME/.config/hypr/scripts"
mkdir -p "$SCRIPTS_TARGET"
cp "$DOTS_DIR/scripts/roman_clock.py" "$SCRIPTS_TARGET/roman_clock.py"
chmod +x "$SCRIPTS_TARGET/roman_clock.py"
info "scripts installed"

# ---- Console (TTY) palette ---------------------------------------------------
step "installing TTY palette and console font"

sudo mkdir -p /etc/sheol
sudo cp "$DOTS_DIR/system/setvtrgb-palette.txt" /etc/sheol/
sudo cp "$DOTS_DIR/system/vconsole.conf" /etc/vconsole.conf
sudo cp "$DOTS_DIR/system/sheol-tty-palette.service" /etc/systemd/system/

read -r -p "    enable sheol-tty-palette.service for boot? [y/N] " enable_tty
if [[ "$enable_tty" =~ ^[Yy]$ ]]; then
    sudo systemctl enable sheol-tty-palette.service
    sudo systemctl start sheol-tty-palette.service || warn "service start failed (will work on next boot)"
fi

# ---- Default shell -----------------------------------------------------------
if [[ "$SHELL" != *"zsh"* ]]; then
    read -r -p "    set zsh as default shell? [y/N] " set_zsh
    if [[ "$set_zsh" =~ ^[Yy]$ ]]; then
        chsh -s "$(which zsh)"
    fi
fi

# ---- Boot target -------------------------------------------------------------
echo
read -r -p "    set boot target to multi-user (TTY by default, GUI on demand)? [y/N] " set_target
if [[ "$set_target" =~ ^[Yy]$ ]]; then
    sudo systemctl set-default multi-user.target
    info "default target = multi-user. Hyprland launches via .zprofile prompt on TTY1."
    info "to revert: sudo systemctl set-default graphical.target"
fi

# ---- Final notes -------------------------------------------------------------
echo
echo -e "${GILT}  ◆  installation complete${RESET}"
echo
echo -e "${BONE}  next steps:${RESET}"
echo -e "${LINEN}  · log out / reboot${RESET}"
echo -e "${LINEN}  · drop your wallpaper at ~/.config/hypr/wallpaper.png${RESET}"
echo -e "${LINEN}  · drop your spade.png at ~/.config/hypr/spade.png (optional)${RESET}"
echo -e "${LINEN}  · log into TTY1, follow the prompt to launch Hyprland${RESET}"
echo -e "${LINEN}  · or stay in TTY for clean shell work${RESET}"
echo
echo -e "${HALO}  ♠  memento ludere${RESET}"
echo
