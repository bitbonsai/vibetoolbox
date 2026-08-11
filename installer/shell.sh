# =============================================================================
# SHELL CONFIGURATION
# =============================================================================

do_configure_shell() {
    ZSHRC="$HOME/.zshrc"

    # Ensure file exists
    touch "$ZSHRC"

    SHELL_MODIFIED=false
    ZSHRC_BACKED_UP=false

    # Backup .zshrc once before first modification
    backup_zshrc() {
        if [[ "$ZSHRC_BACKED_UP" == false ]] && [[ -s "$ZSHRC" ]]; then
            cp "$ZSHRC" "${ZSHRC}.backup"
            ZSHRC_BACKED_UP=true
        fi
    }

    # Write env file (always overwritten so re-runs pick up changes)
    VTB_DIR="$HOME/.config/vibetoolbox"
    ENV_FILE="$VTB_DIR/env.zsh"
    ALIASES_FILE="$VTB_DIR/aliases.zsh"
    mkdir -p "$VTB_DIR"

    # Everything is guarded at shell-startup time, so a deselected or
    # uninstalled tool never breaks a new terminal.
    cat > "$ENV_FILE" << 'ENV_EOF'
# Vibe Toolbox environment - managed by install.sh
# Regenerated on each install run.

# Homebrew
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Bun
if [[ -d "$HOME/.bun" ]]; then
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi

# Local binaries (Claude Code, editor CLIs); prepended after Bun so
# ~/.local/bin wins over any stale bun/npm-global shim
export PATH="$HOME/.local/bin:$PATH"

# Starship prompt
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# Zoxide (smart cd)
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
ENV_EOF

    # Write aliases file (always overwritten so re-runs pick up new aliases
    # and drop stale ones). Each alias only activates when its tool exists.
    cat > "$ALIASES_FILE" << 'ALIASES_EOF'
# Vibe Toolbox aliases - managed by install.sh
# Regenerated on each install run. Aliases activate only when the tool exists.

alias g="git"
alias gs="git status"
alias gp="git push"
alias gl="git pull"
alias gco="git checkout"
alias gcm="git commit -m"
alias gaa="git add -A"
alias zreload="source ~/.zshrc"
alias ..="cd .."
alias ...="cd ../.."

[[ -x "$HOME/.config/vibetoolbox/update.sh" ]] && alias update="$HOME/.config/vibetoolbox/update.sh"

command -v claude >/dev/null 2>&1 && alias c="claude --permission-mode auto"

command -v lazygit >/dev/null 2>&1 && alias lg="lazygit"

if command -v eza >/dev/null 2>&1; then
    alias ls='eza -lh --group-directories-first --icons=auto'
    alias lsa='ls -a'
    alias lt='eza --tree --level=2 --long --git --icons=auto'
    alias lta='lt -a'
fi

if command -v fzf >/dev/null 2>&1 && command -v bat >/dev/null 2>&1; then
    alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
fi

command -v rg >/dev/null 2>&1 && alias grep='rg'
ALIASES_EOF

    # Source env + aliases from .zshrc (single block)
    if ! grep -q 'vibetoolbox/env.zsh' "$ZSHRC"; then
        backup_zshrc
        echo '' >> "$ZSHRC"
        echo '# Vibe Toolbox (managed - do not edit this block)' >> "$ZSHRC"
        echo '[ -f "$HOME/.config/vibetoolbox/env.zsh" ] && source "$HOME/.config/vibetoolbox/env.zsh"' >> "$ZSHRC"
        echo '[ -f "$HOME/.config/vibetoolbox/aliases.zsh" ] && source "$HOME/.config/vibetoolbox/aliases.zsh"' >> "$ZSHRC"
        SHELL_MODIFIED=true
    fi

    if [[ "$SHELL_MODIFIED" == true ]]; then
        print_success "Shell configured"
        track_ok "Shell config"
    else
        print_success "Shell ${DIM}already configured${NC}"
        track_ok "Shell config"
    fi

    # Check if zsh is default shell
    if [[ "$SHELL" != *"zsh"* ]]; then
        echo ""
        print_warning "Your default shell is not zsh"
        echo -e "  ${DIM}Run 'chsh -s /bin/zsh' to change it${NC}"
    fi

    # Do not source ~/.zshrc here; it can interrupt script flow in bash.
    echo -e "${DIM}Shell changes apply to new terminal sessions.${NC}"
}
