# =============================================================================
#  SHEOL // .zshrc
# =============================================================================

# ---- History -----------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY

# ---- Completion --------------------------------------------------------------
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ---- Vi mode -----------------------------------------------------------------
bindkey -v
export KEYTIMEOUT=1

# ---- Aliases -----------------------------------------------------------------
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first --git'
alias la='eza -la --icons --group-directories-first --git'
alias lt='eza -T --icons --level=2'
alias cat='bat --style=plain --paging=never'
alias grep='rg'
alias find='fd'
alias top='btop'
alias df='duf'
alias du='dust'
alias vim='nvim'
alias vi='nvim'
alias ff='fastfetch'
alias g='git'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'

# Sheol-specific
alias sheol-edit='cd ~/sheol-dots && $EDITOR'
alias sheol-pull='cd ~/sheol-dots && git pull'
alias roman='~/.config/hypr/scripts/roman_clock.py'

# ---- Starship ----------------------------------------------------------------
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# ---- Greeting (TTY only, suppresses on Hyprland launch) ---------------------
if [[ "$TERM" == "linux" || -z "$WAYLAND_DISPLAY" ]]; then
    if command -v fastfetch >/dev/null 2>&1; then
        fastfetch
    fi
fi

# ---- Plugins (optional — install via paru/yay) ------------------------------
# zsh-syntax-highlighting must be sourced LAST
[[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Color the autosuggestion in tarnish so it doesn't shout
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#4a3a1f'
