# =============================================================================
# COLORS & SYMBOLS
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Symbols
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
ARROW="${BLUE}→${NC}"
WARN="${YELLOW}!${NC}"
BULLET="${GRAY}•${NC}"
SPARKLE="${MAGENTA}✦${NC}"

SITE_URL="${SITE_URL:-https://vibetoolbox.dev}"
VERSION="1.0.0" # overridden at build time from package.json
PROMPT_FD=0
VTB_CONFIG="$HOME/.config/vibetoolbox/config"
VTB_TMPFILES=()
LOG_FILE="$HOME/.vibetoolbox-install.log"

# Install outcome tracking — used for dynamic completion summary
RESULT_OK=()
RESULT_WARN=()

# Install log — timestamped entries for debugging
log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE" 2>/dev/null
}

# Clean up temp files on exit
cleanup_tmpfiles() {
    for f in "${VTB_TMPFILES[@]}"; do
        rm -f "$f" 2>/dev/null
    done
}
trap cleanup_tmpfiles EXIT

# Suppress noisy brew output
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_NO_ENV_HINTS=1

# =============================================================================
# HELPERS
# =============================================================================

print_step() {
    echo -e "${ARROW} $1"
}

print_success() {
    echo -e "${CHECK} $1"
}

print_warning() {
    echo -e "${WARN} $1"
    log "WARN: $1"
}

print_error() {
    echo -e "${CROSS} $1"
    log "ERROR: $1"
}

print_item() {
    echo -e "  ${BULLET} $1"
}

track_ok() {
    # Dedupe: steps like ensure_editor_clis run more than once per install
    local item
    for item in "${RESULT_OK[@]}"; do
        [[ "$item" == "$1" ]] && return 0
    done
    RESULT_OK+=("$1")
}

track_warn() {
    local name="$1"
    local hint="${2:-}"
    if [[ -n "$hint" ]]; then
        RESULT_WARN+=("${name}: ${hint}")
    else
        RESULT_WARN+=("${name}: may not have installed correctly")
    fi
}

init_prompt_input() {
    if [[ -n "${VTB_TEST:-}" ]]; then
        PROMPT_FD=0
        return
    fi
    if [[ ! -t 0 ]]; then
        # Brace group so a failed /dev/tty open is silenced (bash prints the
        # exec redirection error itself otherwise, e.g. under CI or pipes)
        if { exec 3</dev/tty; } 2>/dev/null; then
            PROMPT_FD=3
        else
            PROMPT_FD=0
        fi
    fi
}

read_input() {
    local __var_name="$1"
    IFS= read -r "$__var_name" <&${PROMPT_FD}
}

wait_for_enter() {
    local prompt="$1"
    local _discard
    echo -e -n "$prompt"
    IFS= read -r _discard <&${PROMPT_FD}
}

download_with_retries() {
    local url="$1"
    local dest="$2"
    local label="$3"
    local max_attempts="${4:-3}"
    local delay_seconds="${5:-1}"
    local attempt=1
    local tmp_file=""

    while [[ $attempt -le $max_attempts ]]; do
        tmp_file="$(mktemp)"
        if curl -fsSL "$url" -o "$tmp_file" && [[ -s "$tmp_file" ]]; then
            mv "$tmp_file" "$dest"
            log "OK: ${label} downloaded (attempt ${attempt}/${max_attempts})"
            return 0
        fi

        rm -f "$tmp_file" 2>/dev/null || true
        log "RETRY: ${label} download failed (attempt ${attempt}/${max_attempts})"

        if [[ $attempt -lt $max_attempts ]]; then
            sleep "$delay_seconds"
        fi
        attempt=$((attempt + 1))
    done

    log "SOFT_FAIL: ${label} download failed after ${max_attempts} attempts"
    return 1
}

# Animated spinner for background tasks
# Returns the exit code of the background process
spinner() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    local has_tput=false

    if [[ -t 1 ]] && command -v tput &>/dev/null; then
        has_tput=true
    fi

    # Restore cursor on interrupt
    if [[ "$has_tput" == true ]]; then
        trap 'tput cnorm' INT TERM
        tput civis  # Hide cursor
    fi

    while kill -0 $pid 2>/dev/null; do
        i=$(( (i + 1) % 10 ))
        printf "\r${BLUE}${spin:$i:1}${NC} %s" "${message}"
        sleep 0.1
    done
    wait $pid 2>/dev/null
    local exit_code=$?

    if [[ "$has_tput" == true ]]; then
        tput cnorm  # Show cursor
    fi
    printf "\r\033[K"  # Clear entire line

    # Remove trap
    trap - INT TERM

    return $exit_code
}

# Divider line
divider() {
    echo -e "${DIM}────────────────────────────────────────${NC}"
}

launch_next_steps_and_terminal() {
    if selection_has "ghostty" && check_cask_app ghostty "Ghostty"; then
        # `open -a` activates the running instance instead of spawning a second one
        local _ghostty_running=false
        pgrep -qix "Ghostty" 2>/dev/null || pgrep -qix "ghostty" 2>/dev/null && _ghostty_running=true

        if open -a Ghostty >/dev/null 2>&1; then
            if [[ "$_ghostty_running" == true ]]; then
                print_success "Ghostty focused ${DIM}already running${NC}"
            else
                print_success "Launched Ghostty"
            fi
        else
            print_warning "Could not launch Ghostty automatically"
            print_item "Open Ghostty from Applications"
        fi
        sleep 0.5
    fi

    if open "${SITE_URL}/next-steps.html" >/dev/null 2>&1; then
        print_success "Opened next steps in browser"
    else
        print_warning "Could not open browser automatically"
        print_item "Open manually: ${SITE_URL}/next-steps.html"
    fi
}

# =============================================================================
# CHECK FUNCTIONS
# =============================================================================

check_brew() {
    command -v brew &>/dev/null
}

check_tool() {
    local tool="$1"
    local brew_name="${tool##*/}"

    # Only check brew — avoids treating macOS system tools (e.g. Apple git) as installed
    brew list "$brew_name" &>/dev/null
}

check_cask_app() {
    local cask="$1"
    local app_name="$2"
    local cask_name="${cask##*/}"

    # Fonts don't have .app bundles — check font directories
    case "$cask_name" in
        font-*)
            ls "$HOME"/Library/Fonts/JetBrainsMonoNerd* &>/dev/null && return 0
            ls /Library/Fonts/JetBrainsMonoNerd* &>/dev/null && return 0
            brew list --cask "$cask_name" &>/dev/null && return 0
            return 1
            ;;
    esac

    # Check if app exists in /Applications or ~/Applications
    if [[ -n "$app_name" ]]; then
        if [[ -d "/Applications/${app_name}.app" ]] || [[ -d "$HOME/Applications/${app_name}.app" ]]; then
            return 0
        fi
    fi

    # Fallback to brew list
    brew list --cask "$cask_name" &>/dev/null
}

check_bin() {
    local bin="$1"
    command -v "$bin" &>/dev/null || [[ -x "$HOME/.bun/bin/$bin" ]] || [[ -x "$HOME/.local/bin/$bin" ]]
}

check_xcode_cli() {
    xcode-select -p &>/dev/null
}

check_rosetta() {
    [[ $(uname -m) != "arm64" ]] || /usr/bin/pgrep -q oahd
}

check_gh_auth() {
    gh auth status &>/dev/null
}

check_ghostty_config() {
    [[ -f "$HOME/.config/ghostty/config" ]]
}

check_starship_config() {
    [[ -f "$HOME/.config/starship.toml" ]]
}

check_zshrc_configured() {
    [[ -f "$HOME/.zshrc" ]] && grep -q 'vibetoolbox/env.zsh' "$HOME/.zshrc"
}

check_claude_code() {
    command -v claude &>/dev/null || [[ -x "$HOME/.local/bin/claude" ]]
}

check_claude_plugin() {
    local plugin="$1"
    check_claude_code || return 1
    claude plugin list 2>/dev/null | grep -qi "$plugin"
}

check_autoupdate_agent() {
    [[ -f "$HOME/Library/LaunchAgents/dev.vibetoolbox.update.plist" ]] \
        && [[ -f "$HOME/.config/vibetoolbox/update.sh" ]]
}
