# =============================================================================
# UNINSTALL
# =============================================================================

# Shared cleanup logic for the --uninstall flag
# Sets $removed to the number of items removed
_do_uninstall_cleanup() {
    removed=0

    # Unload and remove the auto-update launchd agent
    local _agent_label="dev.vibetoolbox.update"
    local _agent_plist="$HOME/Library/LaunchAgents/${_agent_label}.plist"
    if [[ -f "$_agent_plist" ]]; then
        if command -v launchctl &>/dev/null; then
            launchctl bootout "gui/$(id -u)/${_agent_label}" &>/dev/null || true
        fi
        rm -f "$_agent_plist"
        echo -e "${CHECK} Removed auto-update agent"
        removed=$((removed + 1))
    fi

    # Remove update log
    if [[ -f "$HOME/.vibetoolbox-update.log" ]]; then
        rm -f "$HOME/.vibetoolbox-update.log"
        echo -e "${CHECK} Removed ~/.vibetoolbox-update.log"
        removed=$((removed + 1))
    fi

    # Remove config directory (config, env.zsh, aliases.zsh, update.sh)
    if [[ -d "$HOME/.config/vibetoolbox" ]]; then
        rm -rf "$HOME/.config/vibetoolbox"
        echo -e "${CHECK} Removed ~/.config/vibetoolbox/"
        removed=$((removed + 1))
    fi

    # Remove install log
    if [[ -f "$LOG_FILE" ]]; then
        rm -f "$LOG_FILE"
        echo -e "${CHECK} Removed ~/.vibetoolbox-install.log"
        removed=$((removed + 1))
    fi

    # Remove source lines from .zshrc
    ZSHRC="$HOME/.zshrc"
    if [[ -f "$ZSHRC" ]] && grep -qE 'vibetoolbox/(env|aliases)\.zsh' "$ZSHRC"; then
        cp "$ZSHRC" "${ZSHRC}.backup"
        sed -i '' '/vibetoolbox\/env\.zsh/d; /vibetoolbox\/aliases\.zsh/d; /^# Vibe Toolbox (managed - do not edit this block)$/d' "$ZSHRC"
        echo -e "${CHECK} Removed vibetoolbox source lines from ~/.zshrc"
        removed=$((removed + 1))
    fi
}

if [[ "${1:-}" == "--uninstall" ]]; then
    echo ""
    echo -e "${BOLD}Vibe Toolbox Uninstall${NC}"
    echo ""
    echo -e "${DIM}This removes Vibe Toolbox aliases, preferences, auto-update agent, and logs.${NC}"
    echo -e "${DIM}Ghostty and Starship configs are preserved.${NC}"
    echo -e "${DIM}Your tools (Ghostty, editors, brew packages, etc.) are untouched.${NC}"
    echo ""

    _do_uninstall_cleanup

    echo ""
    if [[ $removed -gt 0 ]]; then
        echo -e "${GREEN}${BOLD}Done.${NC} Removed $removed item(s)."
        echo -e "${DIM}Open a new terminal for changes to take effect.${NC}"
    else
        echo -e "${DIM}Nothing to remove. Vibe Toolbox was not configured.${NC}"
    fi
    echo ""
    exit 0
fi
