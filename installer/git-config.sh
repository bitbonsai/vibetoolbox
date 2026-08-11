# =============================================================================
# GIT IDENTITY
# =============================================================================

ensure_git_identity() {
    local git_name
    local git_email

    git_name="$(git config --global --get user.name 2>/dev/null || true)"
    git_email="$(git config --global --get user.email 2>/dev/null || true)"

    if [[ -z "$git_name" ]]; then
        while [[ -z "$git_name" ]]; do
            echo -e -n "${DIM}Enter your name for Git commits:${NC} "
            if ! read_input git_name; then
                print_error "Could not read Git name"
                return 1
            fi
        done
        git config --global user.name "$git_name"
        print_success "Git name configured"
    else
        print_success "Git name ${DIM}already configured${NC}"
    fi

    if [[ -z "$git_email" ]]; then
        while [[ -z "$git_email" ]]; do
            echo -e -n "${DIM}Enter your email for Git commits:${NC} "
            if ! read_input git_email; then
                print_error "Could not read Git email"
                return 1
            fi
        done
        git config --global user.email "$git_email"
        print_success "Git email configured"
    else
        print_success "Git email ${DIM}already configured${NC}"
    fi
}
