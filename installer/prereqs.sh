# =============================================================================
# PREREQUISITES
# =============================================================================

# Ensure Xcode CLI Tools are installed (fatal if fails)
ensure_xcode_cli() {
    if check_xcode_cli; then return 0; fi

    print_step "Installing Xcode Command Line Tools..."
    xcode-select --install 2>/dev/null || true

    echo ""
    echo -e "${WARN} ${YELLOW}A dialog will appear. Click 'Install' and wait for it to complete.${NC}"
    echo ""
    wait_for_enter "Press Enter when the installation is finished..."

    if ! check_xcode_cli; then
        print_error "Xcode Command Line Tools installation failed"
        log "FATAL: Xcode CLI Tools failed — aborting"
        return 1
    fi
    print_success "Xcode Command Line Tools"
    track_ok "Xcode CLI Tools"
}

# Ensure Rosetta 2 is installed (Apple Silicon only, soft failure)
ensure_rosetta() {
    [[ $(uname -m) != "arm64" ]] && return 0
    if check_rosetta; then return 0; fi

    print_step "Installing Rosetta 2..."
    softwareupdate --install-rosetta --agree-to-license &>/dev/null || true
    if check_rosetta; then
        print_success "Rosetta 2"
        track_ok "Rosetta 2"
    else
        print_warning "Rosetta 2 may not have installed correctly"
        track_warn "Rosetta 2" "run: softwareupdate --install-rosetta"
    fi
}

# Ensure Homebrew is installed (fatal if fails)
ensure_brew() {
    if check_brew; then return 0; fi

    ensure_xcode_cli || { log "FATAL: Xcode needed for Homebrew"; exit 1; }
    ensure_rosetta

    print_step "Installing Homebrew..."
    echo -e "${DIM}You may be prompted for your Mac password (sudo).${NC}"
    echo -e "${DIM}When typing your password, nothing will appear on screen. Just type it and press Enter.${NC}"
    echo ""
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/tty

    # Add to path for this session
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if ! check_brew; then
        print_error "Homebrew installation failed. Cannot continue."
        log "FATAL: Homebrew install failed — aborting"
        return 1
    fi
    print_success "Homebrew"
    track_ok "Homebrew"
}
