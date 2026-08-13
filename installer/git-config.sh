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

    ensure_git_aliases
}

# Short git aliases (git s, git ac "msg", git lg, ...). Each is written
# only when unset so existing user aliases are never overwritten.
ensure_git_aliases() {
    _git_alias s "status -sb"
    _git_alias p "push"
    _git_alias pl "pull"
    _git_alias b "branch"
    _git_alias d "diff"
    _git_alias ds "diff --staged"
    _git_alias lg "log --oneline --decorate --graph --color"
    _git_alias amend "commit --amend --no-edit"
    _git_alias ac '!f() { git add -A && git commit -m "$*"; }; f'
    print_success "Git aliases ${DIM}(git s, git ac \"msg\", git lg, ...)${NC}"
}

_git_alias() {
    git config --global --get "alias.$1" >/dev/null 2>&1 && return 0
    git config --global "alias.$1" "$2"
}
