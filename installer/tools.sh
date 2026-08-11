# =============================================================================
# TOOL INSTALLATION (catalog-driven)
# =============================================================================
# Installs whatever is in SELECTED_IDS, phase by phase so dependencies land
# first: brew formulas (incl. runtimes) → casks → curl installers → bun
# globals → Claude Code plugins.

_tool_installed() {
    local id="$1"
    local kind target app bin
    kind="$(catalog_field "$id" 2)"
    target="$(catalog_field "$id" 3)"
    app="$(catalog_field "$id" 4)"
    bin="$(catalog_field "$id" 5)"

    case "$kind" in
        brew)   check_tool "$target" || { [[ -n "$bin" ]] && check_bin "$bin"; } ;;
        cask)   check_cask_app "$target" "$app" ;;
        bun)    check_bin "${bin:-$target}" ;;
        curl)   [[ -n "$bin" ]] && check_bin "$bin" ;;
        plugin) check_claude_plugin "$id" ;;
        *)      return 1 ;;
    esac
}

# brew tap for targets like "user/tap/formula"; trusts it on Homebrew 6
_ensure_tap() {
    local target="$1"
    [[ "$target" == */*/* ]] || return 0
    local tap="${target%/*}"
    brew tap "$tap" </dev/null &>/dev/null || true
    # Homebrew 6 requires third-party taps to be trusted; older versions
    # don't have the command, hence the guard
    brew trust "$tap" </dev/null &>/dev/null || true
}

_install_tool() {
    local id="$1"
    local kind target bin name
    kind="$(catalog_field "$id" 2)"
    target="$(catalog_field "$id" 3)"
    bin="$(catalog_field "$id" 5)"
    name="$(catalog_field "$id" 6)"

    print_step "Installing ${name}..."

    case "$kind" in
        brew)
            _ensure_tap "$target"
            brew install "$target" --quiet </dev/null 2>/dev/null || true
            ;;
        cask)
            _ensure_tap "$target"
            brew install --cask "$target" --quiet </dev/null 2>/dev/null || true
            ;;
        bun)
            bun install -g "$target" </dev/null &>/dev/null || true
            export PATH="$HOME/.bun/bin:$PATH"
            ;;
        curl)
            local tmp_installer
            tmp_installer="$(mktemp)"
            VTB_TMPFILES+=("$tmp_installer")
            if download_with_retries "$target" "$tmp_installer" "$name installer"; then
                bash "$tmp_installer" </dev/null >/dev/null 2>&1 || true
            fi
            export PATH="$HOME/.local/bin:$PATH"
            ;;
        plugin)
            if check_claude_code; then
                claude plugin marketplace add "$target" </dev/null &>/dev/null || true
                claude plugin install "${id}@${id}" </dev/null &>/dev/null || true
            fi
            ;;
    esac

    if _tool_installed "$id"; then
        print_success "$name"
        log "OK: $name installed"
        track_ok "$name"
    else
        log "SOFT_FAIL: $name install verification failed"
        print_warning "$name may not have installed correctly"
        case "$kind" in
            brew)   track_warn "$name" "run: brew install $target" ;;
            cask)   track_warn "$name" "run: brew install --cask $target" ;;
            bun)    track_warn "$name" "run: bun install -g $target" ;;
            curl)   track_warn "$name" "run: curl -fsSL $target | bash" ;;
            plugin) track_warn "$name" "run: claude plugin install ${id}@${id}" ;;
        esac
    fi
}

do_install_tools() {
    ensure_brew || { print_error "Homebrew required, cannot install tools"; return 1; }

    # Determine what needs installing (selected and missing)
    local _needs=()
    local _needs_brew=false
    local id kind
    for id in "${SELECTED_IDS[@]}"; do
        if _tool_installed "$id"; then
            track_ok "$(catalog_field "$id" 6)"
        else
            _needs+=("$id")
            kind="$(catalog_field "$id" 2)"
            [[ "$kind" == "brew" || "$kind" == "cask" ]] && _needs_brew=true
        fi
    done

    # Brew update (only if needed)
    if [[ "$_needs_brew" == true ]]; then
        print_step "Updating Homebrew..."
        brew update --quiet </dev/null &>/dev/null &
        if spinner $! "Updating Homebrew..."; then
            print_success "Homebrew updated"
        else
            print_warning "Homebrew update failed; continuing with current package metadata"
            track_warn "Homebrew update" "run: brew update"
        fi
        echo ""
    fi

    if [[ ${#_needs[@]} -gt 0 ]]; then
        echo -e "${BOLD}Installing tools${NC}"
        echo ""
        # Phase order so dependencies exist before their dependents
        local phase
        for phase in brew cask curl bun plugin; do
            for id in "${_needs[@]}"; do
                [[ "$(catalog_field "$id" 2)" == "$phase" ]] || continue
                _install_tool "$id"
            done
        done
        echo ""
    fi

    do_write_configs
}

do_write_configs() {
    echo -e "${BOLD}Configuration${NC}"
    echo ""

    # Ghostty config (only when Ghostty is part of the selection; always
    # rewritten, 1 rolling backup)
    if selection_has "ghostty"; then
        print_step "Configuring Ghostty..."
        mkdir -p ~/.config/ghostty
        [[ -f ~/.config/ghostty/config ]] && cp ~/.config/ghostty/config ~/.config/ghostty/config.backup
        cat > ~/.config/ghostty/config << 'GHOSTTY_EOF'
theme = light:catppuccin latte,dark:catppuccin mocha
background-opacity = 0.9
macos-titlebar-style = transparent
window-colorspace = "display-p3"
keybind = cmd+s>r=reload_config
copy-on-select = true
background-blur-radius = 9
window-padding-x = 16
window-padding-y = 16
window-theme = system
keybind = global:cmd+grave_accent=toggle_quick_terminal
font-family = "JetBrainsMono Nerd Font"
font-size = 16
keybind = shift+enter=text:\x1b\r
GHOSTTY_EOF
        # Append working-directory setting
        echo '' >> ~/.config/ghostty/config
        echo '# Default working directory' >> ~/.config/ghostty/config
        echo "working-directory = $HOME/dev" >> ~/.config/ghostty/config
        print_success "Ghostty config"
        log "OK: Ghostty config written"
        track_ok "Ghostty config"
    fi

    # Starship config (only when Starship is selected; always rewritten,
    # 1 rolling backup)
    if selection_has "starship"; then
        print_step "Configuring Starship..."
        mkdir -p ~/.config
        [[ -f ~/.config/starship.toml ]] && cp ~/.config/starship.toml ~/.config/starship.toml.backup
        cat > ~/.config/starship.toml << 'STARSHIP_EOF'
format = """
$directory\
$git_branch\
$git_status\
$fill\
$cmd_duration\
$line_break\
$character"""

[directory]
style = "bold blue"
truncation_length = 3
truncate_to_repo = true

[git_branch]
style = "bold purple"
format = " [$branch]($style) "

[git_status]
style = "bold red"
format = "[$all_status$ahead_behind]($style)"

[fill]
symbol = " "

[cmd_duration]
min_time = 2000
style = "bold yellow"
format = "[$duration]($style)"

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
STARSHIP_EOF
        print_success "Starship config"
        log "OK: Starship config written"
        track_ok "Starship config"
    fi

    # Create ~/dev directory
    if [[ ! -d "$HOME/dev" ]]; then
        mkdir -p "$HOME/dev"
        print_success "Created ~/dev directory"
    fi

    ensure_editor_clis

    echo ""
    print_success "Tools and configuration complete"
}

# Symlink editor CLIs into ~/.local/bin (already on PATH via env.zsh) so
# `zed .` and `cursor .` work without the in-app Install CLI step.
ensure_editor_clis() {
    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"

    if selection_has "zed"; then
        local zed_cli=""
        [[ -x "/Applications/Zed.app/Contents/MacOS/cli" ]] && zed_cli="/Applications/Zed.app/Contents/MacOS/cli"
        [[ -z "$zed_cli" && -x "$HOME/Applications/Zed.app/Contents/MacOS/cli" ]] && zed_cli="$HOME/Applications/Zed.app/Contents/MacOS/cli"
        if [[ -n "$zed_cli" ]]; then
            if command -v zed &>/dev/null; then
                track_ok "Zed CLI"
            else
                ln -sf "$zed_cli" "$bin_dir/zed"
                print_success "Zed CLI ${DIM}(zed .)${NC}"
                log "OK: zed CLI symlinked to $bin_dir/zed"
                track_ok "Zed CLI"
            fi
        fi
    fi

    if selection_has "cursor"; then
        local cursor_cli=""
        [[ -x "/Applications/Cursor.app/Contents/Resources/app/bin/cursor" ]] && cursor_cli="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
        [[ -z "$cursor_cli" && -x "$HOME/Applications/Cursor.app/Contents/Resources/app/bin/cursor" ]] && cursor_cli="$HOME/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
        if [[ -n "$cursor_cli" ]]; then
            if command -v cursor &>/dev/null; then
                track_ok "Cursor CLI"
            else
                ln -sf "$cursor_cli" "$bin_dir/cursor"
                print_success "Cursor CLI ${DIM}(cursor .)${NC}"
                log "OK: cursor CLI symlinked to $bin_dir/cursor"
                track_ok "Cursor CLI"
            fi
        fi
    fi
}
