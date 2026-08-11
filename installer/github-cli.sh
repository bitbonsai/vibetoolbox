# =============================================================================
# GITHUB CLI AUTH (runs only when gh is part of the selection)
# =============================================================================

do_configure_github_cli() {
    command -v gh &>/dev/null || return 0

    if check_gh_auth; then
        print_success "GitHub CLI ${DIM}already authenticated${NC}"
        track_ok "GitHub auth"
        return 0
    fi

    print_step "Authenticating with GitHub..."
    echo -e "${DIM}Your browser will open. Sign in to GitHub to continue.${NC}"
    echo ""
    # Route all fds through /dev/tty so gh output (one-time code,
    # "Press Enter" prompt, success message) is visible in curl|bash.
    # TERM=dumb prevents gh (termenv) from probing terminal colors
    # (OSC 11) and cursor position (DSR) — responses echo as garbage.
    # Trap INT so Ctrl+C kills only gh, not the entire script
    # (non-interactive bash exits via WCE when a child dies from SIGINT).
    trap 'true' INT
    TERM=dumb gh auth login --hostname github.com --web --git-protocol ssh --skip-ssh-key --clipboard </dev/tty >/dev/tty 2>&1
    local gh_exit=$?
    trap - INT
    if [[ $gh_exit -eq 0 ]]; then
        echo ""
        print_success "GitHub CLI authenticated"
        track_ok "GitHub auth"
    else
        log "SOFT_FAIL: GitHub auth canceled or failed (exit ${gh_exit})"
        echo ""
        print_warning "GitHub authentication was not completed"
        print_item "Run later: gh auth login"
        track_warn "GitHub auth" "run: gh auth login"
        return 1
    fi
}
