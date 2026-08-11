# --- MAIN ENTRY ---

# =============================================================================
# ARGUMENTS (--uninstall is handled in uninstall.sh before this point)
# =============================================================================

CLI_SELECTION=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --with)
            CLI_SELECTION="${2:-}"
            shift 2 || break
            ;;
        --with=*)
            CLI_SELECTION="${1#--with=}"
            shift
            ;;
        --all)
            CLI_SELECTION="all"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Write log header
{
    echo ""
    echo "=========================================="
    echo "Vibe Toolbox install v${VERSION}"
    echo "Date: $(date)"
    echo "macOS: $(sw_vers -productVersion 2>/dev/null || echo unknown)"
    echo "Arch: $(uname -m)"
    echo "=========================================="
} >> "$LOG_FILE" 2>/dev/null

# =============================================================================
# STATUS SCAN (doctor-style; re-running the installer IS the system check)
# =============================================================================

_status_row() {
    local label="$1"
    shift
    if "$@" &>/dev/null; then
        echo -e "  ${CHECK} ${label}"
    else
        echo -e "  ${ARROW} ${label}"
    fi
}

_check_gh_ready() {
    command -v gh &>/dev/null && check_gh_auth
}

print_status_scan() {
    echo -e "${BOLD}System check${NC} ${DIM}(${CHECK} installed  ${ARROW} will be set up)${NC}"
    echo ""

    _status_row "Xcode CLI Tools" check_xcode_cli
    if [[ $(uname -m) == "arm64" ]]; then
        _status_row "Rosetta 2" check_rosetta
    fi
    _status_row "Homebrew" check_brew

    local id
    for id in "${SELECTED_IDS[@]}"; do
        _status_row "$(catalog_field "$id" 6)" _tool_installed "$id"
    done

    selection_has "gh" && _status_row "GitHub auth" _check_gh_ready
    selection_has "ghostty" && _status_row "Ghostty config" check_ghostty_config
    selection_has "starship" && _status_row "Starship config" check_starship_config
    _status_row "Shell config" check_zshrc_configured
    _status_row "Auto-update agent" check_autoupdate_agent
    echo ""
}

# =============================================================================
# ENTRY POINT (linear, zero-decision flow)
# =============================================================================

# macOS version check
MACOS_VERSION="$(sw_vers -productVersion 2>/dev/null || echo "0")"
MACOS_MAJOR="${MACOS_VERSION%%.*}"

clear

# Set up PATH for this bash session so status checks find installed tools
# (Homebrew, bun globals, Claude Code are in paths not in default bash PATH)
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi
[[ -d "$HOME/.bun/bin" ]] && export PATH="$HOME/.bun/bin:$PATH"
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

init_prompt_input
load_config

echo ""
echo -e "${YELLOW}❯_${NC} ${BOLD}Vibe Toolbox${NC} ${DIM}v${VERSION}${NC}"
echo ""
echo -e "${DIM}One command to set up your Mac for AI-assisted coding.${NC}"
echo -e "${DIM}Re-run any time to check or repair your setup.${NC}"
echo ""

if [[ "$MACOS_MAJOR" -lt 13 ]] 2>/dev/null; then
    print_warning "macOS 13 (Ventura) or later is recommended"
    print_item "Some tools (Ghostty, Zed) may not work on older versions"
    echo ""
fi

# Selection priority: baked (share URL) > --with/--all > saved from last run
RAW_SELECTION="${VTB_SELECTION:-${CLI_SELECTION:-${SAVED_VTB_SELECTED:-}}}"

if [[ -z "$RAW_SELECTION" ]]; then
    echo -e "${WARN} ${BOLD}No tools selected.${NC}"
    echo ""
    echo -e "Pick your tools at ${BOLD}${SITE_URL}${NC} and paste the command it gives you."
    echo -e "${DIM}Or run with an explicit list:  install.sh --with ghostty,starship,claude-code${NC}"
    echo -e "${DIM}Or install everything:         install.sh --all${NC}"
    echo ""
    exit 0
fi

if ! resolve_selection "$RAW_SELECTION"; then
    print_error "Selection contained no known tools. Pick again at ${SITE_URL}"
    exit 1
fi

print_status_scan
divider
echo ""

# 1. Prerequisites (fatal if they fail)
ensure_xcode_cli || exit 1
ensure_rosetta
ensure_brew || exit 1

# 2. Selected tools + configs
do_install_tools

echo ""

# 3. Git identity (cheap pre-step so first commits just work)
if selection_has "git" || selection_has "gh"; then
    ensure_git_identity
    echo ""
fi

# 4. GitHub auth (browser login, only when gh is selected)
if selection_has "gh"; then
    do_configure_github_cli || true
    echo ""
fi

# 5. Shell aliases + .zshrc wiring
echo -e "${BOLD}Shell Configuration${NC}"
echo ""
do_configure_shell

echo ""

# 6. Weekly auto-update (launchd agent)
setup_autoupdate

echo ""
divider
echo ""
echo -e "${GREEN}${BOLD}Installation complete!${NC} ${SPARKLE}"
echo ""

# Dynamic summary based on actual outcomes
OK_COUNT=${#RESULT_OK[@]}
WARN_COUNT=${#RESULT_WARN[@]}

if [[ $OK_COUNT -gt 0 ]]; then
    echo -e "${DIM}Ready (${OK_COUNT}):${NC}"
    _summary_line=""
    for item in "${RESULT_OK[@]}"; do
        if [[ -z "$_summary_line" ]]; then
            _summary_line="$item"
        elif [[ $(( ${#_summary_line} + ${#item} + 2 )) -gt 60 ]]; then
            print_item "$_summary_line"
            _summary_line="$item"
        else
            _summary_line="$_summary_line, $item"
        fi
    done
    [[ -n "$_summary_line" ]] && print_item "$_summary_line"
fi

if [[ $WARN_COUNT -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}Warnings (${WARN_COUNT}):${NC}"
    for item in "${RESULT_WARN[@]}"; do
        echo -e "  ${WARN} $item"
    done
    echo ""
    echo -e "${DIM}Re-run your install command any time; it only fixes what is missing.${NC}"
fi

echo ""

save_config
log "OK: Installation complete"

echo -e "${DIM}Install log: ${LOG_FILE}${NC}"
echo ""

echo -e "✅ ${BOLD}You're all set.${NC}"
echo ""
if [[ -z "${VTB_TEST:-}" ]]; then
    wait_for_enter "Press ${BOLD}ENTER${NC} to open the next steps guide ${DIM}(Ctrl+C to skip)${NC} "
    echo ""
    launch_next_steps_and_terminal
    echo ""
    echo -e "${BOLD}Welcome to your new terminal!${NC}"
fi

echo ""
echo -e "Happy vibecoding! ${SPARKLE}"
echo ""

# Clean up prompt fd
[[ "$PROMPT_FD" -ne 0 ]] && exec 3<&- 2>/dev/null
exit 0
