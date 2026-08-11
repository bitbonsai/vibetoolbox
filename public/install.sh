#!/bin/bash
# Vibe Toolbox installer
# https://vibetoolbox.dev

# Note: we intentionally do NOT use 'set -e' here. Brew and other tools can
# return non-zero for non-fatal reasons (warnings, already-installed, etc.).
# Each critical step has explicit error handling instead.

# Baked-in selection. The vibetoolbox.dev server replaces this line when the
# script is served from a /i/<slug> share URL. Leave empty in the source.
VTB_SELECTION="${VTB_SELECTION:-}"

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
VERSION="1.0"
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

# =============================================================================
# TOOL CATALOG (generated from catalog.json by scripts/build.ts — do not edit)
# =============================================================================
# Fields: id|kind|target|app|bin|name|requires

CATALOG=(
    "ghostty|cask|ghostty|Ghostty||Ghostty|"
    "nerd-font|cask|font-jetbrains-mono-nerd-font|||JetBrains Mono Nerd Font|"
    "starship|brew|starship|||Starship|"
    "claude-code|curl|https://claude.ai/install.sh||claude|Claude Code|"
    "codex|brew|codex|||Codex CLI|"
    "pi|bun|@earendil-works/pi-coding-agent||pi|Pi|bun"
    "opencode|bun|opencode-ai||opencode|OpenCode|bun"
    "crush|bun|@charmland/crush||crush|Crush|bun"
    "herdr|brew|herdr|||Herdr|"
    "orca|cask|stablyai/orca/orca|Orca||Orca|"
    "ccpeek|brew|ahmedelgabri/tap/ccpeek||ccpeek|ccpeek|"
    "caveman|plugin|JuliusBrussee/caveman|||Caveman|claude-code"
    "zed|cask|zed|Zed||Zed|"
    "cursor|cask|cursor|Cursor||Cursor|"
    "vscode|cask|visual-studio-code|Visual Studio Code||Visual Studio Code|"
    "git|brew|git|||Git|"
    "gh|brew|gh|||GitHub CLI|"
    "lazygit|brew|lazygit|||lazygit|"
    "git-delta|brew|git-delta||delta|delta|"
    "eza|brew|eza|||eza|"
    "bat|brew|bat|||bat|"
    "zoxide|brew|zoxide|||zoxide|"
    "tree|brew|tree|||tree|"
    "fzf|brew|fzf|||fzf|"
    "ripgrep|brew|ripgrep||rg|ripgrep|"
    "jq|brew|jq|||jq|"
    "trash-cli|bun|trash-cli||trash|trash-cli|bun"
    "node|brew|node|||Node.js|"
    "bun|brew|bun|||Bun|"
)

# =============================================================================
# SELECTION
# =============================================================================
# CATALOG is generated from catalog.json by scripts/build.ts (catalog.sh).
# Each entry: "id|kind|target|app|bin|name|requires"
# Selection sources, in priority order:
#   1. VTB_SELECTION  — baked in by the vibetoolbox.dev server (/i/<slug> URLs)
#   2. --with a,b,c   — CLI flag (also --all)
#   3. saved config   — previous run's selection (re-run = system check)
# No selection at all: point at the picker and exit.

SELECTED_IDS=()

catalog_field() {
    # catalog_field <id> <field-number>  (1=id 2=kind 3=target 4=app 5=bin 6=name 7=requires)
    local id="$1"
    local n="$2"
    local entry
    for entry in "${CATALOG[@]}"; do
        if [[ "${entry%%|*}" == "$id" ]]; then
            echo "$entry" | cut -d'|' -f"$n"
            return 0
        fi
    done
    return 1
}

catalog_has() {
    catalog_field "$1" 1 >/dev/null
}

selection_has() {
    local id="$1"
    local sel
    for sel in "${SELECTED_IDS[@]}"; do
        [[ "$sel" == "$id" ]] && return 0
    done
    return 1
}

_selection_add() {
    selection_has "$1" || SELECTED_IDS+=("$1")
}

# Fill SELECTED_IDS from a comma-separated list, dropping unknown ids and
# pulling in required dependencies (transitively).
resolve_selection() {
    local raw="$1"
    local id req entry changed

    SELECTED_IDS=()

    if [[ "$raw" == "all" ]]; then
        for entry in "${CATALOG[@]}"; do
            SELECTED_IDS+=("${entry%%|*}")
        done
        return 0
    fi

    local IFS=','
    for id in $raw; do
        unset IFS
        id="$(echo "$id" | tr -d '[:space:]')"
        [[ -z "$id" ]] && continue
        if catalog_has "$id"; then
            _selection_add "$id"
        else
            print_warning "Unknown tool '${id}' in selection, skipping"
        fi
    done
    unset IFS

    # Pull in dependencies until stable
    changed=true
    while [[ "$changed" == true ]]; do
        changed=false
        for id in "${SELECTED_IDS[@]}"; do
            local reqs
            reqs="$(catalog_field "$id" 7)"
            [[ -z "$reqs" ]] && continue
            local IFS=','
            for req in $reqs; do
                unset IFS
                if ! selection_has "$req"; then
                    SELECTED_IDS+=("$req")
                    changed=true
                fi
            done
            unset IFS
        done
    done

    [[ ${#SELECTED_IDS[@]} -gt 0 ]]
}

selection_csv() {
    local out=""
    local id
    for id in "${SELECTED_IDS[@]}"; do
        out="${out:+${out},}${id}"
    done
    echo "$out"
}

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

# =============================================================================
# USER PREFERENCES
# =============================================================================

load_config() {
    SAVED_VTB_VERSION=""
    SAVED_VTB_INSTALLED_AT=""
    SAVED_VTB_SELECTED=""

    if [[ -f "$VTB_CONFIG" ]]; then
        # Parse only known keys to avoid arbitrary code execution
        while IFS='=' read -r key value; do
            # Skip comments and blank lines
            [[ -z "$key" || "$key" == \#* ]] && continue
            # Strip surrounding quotes (double or single)
            value="${value#\"}"
            value="${value%\"}"
            value="${value#\'}"
            value="${value%\'}"
            case "$key" in
                VTB_VERSION)      SAVED_VTB_VERSION="$value" ;;
                VTB_INSTALLED_AT) SAVED_VTB_INSTALLED_AT="$value" ;;
                VTB_SELECTED)     SAVED_VTB_SELECTED="$value" ;;
            esac
        done < "$VTB_CONFIG"
    fi
}

save_config() {
    mkdir -p "$(dirname "$VTB_CONFIG")"
    local installed_at="${SAVED_VTB_INSTALLED_AT:-$(date -u +%Y-%m-%dT%H:%M:%S)}"
    local last_run
    last_run="$(date -u +%Y-%m-%dT%H:%M:%S)"
    printf '%s\n' \
        "# Vibe Toolbox preferences" \
        "# Written by install.sh v${VERSION}, safe to edit manually" \
        "VTB_VERSION=\"${VERSION}\"" \
        "VTB_INSTALLED_AT=\"${installed_at}\"" \
        "VTB_LAST_RUN=\"${last_run}\"" \
        "VTB_SELECTED=\"$(selection_csv)\"" \
        > "$VTB_CONFIG"
    chmod 600 "$VTB_CONFIG"
}

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

# =============================================================================
# UPDATE SCRIPT GENERATION
# =============================================================================
# Writes ~/.config/vibetoolbox/update.sh, the payload run weekly by the
# launchd agent (see autoupdate.sh). Runs under `zsh -lc` so the user's login
# environment (brew shellenv) is loaded.

write_update_script() {
    local update_dir="$HOME/.config/vibetoolbox"
    local update_script="$update_dir/update.sh"
    mkdir -p "$update_dir"

    cat > "$update_script" << UPDATE_EOF
#!/bin/zsh
# Vibe Toolbox auto-update - managed by install.sh
# Regenerated on each install run. Logs to ~/.vibetoolbox-update.log

LOG="\$HOME/.vibetoolbox-update.log"
SITE_URL="${SITE_URL}"
INSTALLED_VERSION="${VERSION}"

run_updates() {
    echo ""
    echo "=== Vibe Toolbox update: \$(date) ==="

    # Homebrew packages and casks
    brew update && brew upgrade

    # Bun global packages (runtime itself is brew-managed, covered above)
    if command -v bun >/dev/null 2>&1; then
        bun update -g
    fi

    # npm global packages
    if command -v npm >/dev/null 2>&1; then
        npm update -g
    fi

    # Claude Code
    if command -v claude >/dev/null 2>&1; then
        claude update || echo "WARN: claude update failed (non-fatal)"
    fi

    # Toolkit self-version check (notify only when the remote version is newer)
    latest="\$(curl -fsSL "\${SITE_URL}/install.sh" 2>/dev/null | grep -m1 '^VERSION=' | cut -d'"' -f2)"
    if [[ -n "\$latest" && "\$latest" != "\$INSTALLED_VERSION" ]]; then
        newest="\$(printf '%s\n%s\n' "\$INSTALLED_VERSION" "\$latest" | sort -V | tail -1)"
        if [[ "\$newest" == "\$latest" ]]; then
            echo "NOTE: Vibe Toolbox v\$latest is available (installed: v\$INSTALLED_VERSION)."
            echo "NOTE: Re-run your install command from \${SITE_URL} to update."
        fi
    fi

    echo "=== Update finished: \$(date) ==="
}

# Interactive run: stream to the terminal and the log.
# launchd run (no tty): log only.
if [[ -t 1 ]]; then
    run_updates 2>&1 | tee -a "\$LOG"
else
    run_updates >> "\$LOG" 2>&1
fi
UPDATE_EOF

    chmod +x "$update_script"
}

# =============================================================================
# AUTO-UPDATE (launchd agent, weekly)
# =============================================================================

AUTOUPDATE_LABEL="dev.vibetoolbox.update"
AUTOUPDATE_PLIST="$HOME/Library/LaunchAgents/${AUTOUPDATE_LABEL}.plist"

setup_autoupdate() {
    print_step "Setting up weekly auto-update..."

    # (Re)write the update payload each run so it picks up changes
    write_update_script

    mkdir -p "$HOME/Library/LaunchAgents"

    # launchd does not source .zshrc; run the payload via a login shell so
    # brew shellenv is loaded. Monday 10:00.
    cat > "$AUTOUPDATE_PLIST" << PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${AUTOUPDATE_LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>-lc</string>
        <string>"$HOME/.config/vibetoolbox/update.sh"</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>1</integer>
        <key>Hour</key>
        <integer>10</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
PLIST_EOF

    # Idempotent (re)load: bootout is a no-op when the agent is not loaded.
    # Skipped in tests so runs never register agents on the host.
    if [[ -z "${VTB_TEST:-}" ]] && command -v launchctl &>/dev/null; then
        launchctl bootout "gui/$(id -u)/${AUTOUPDATE_LABEL}" &>/dev/null || true
        if launchctl bootstrap "gui/$(id -u)" "$AUTOUPDATE_PLIST" &>/dev/null; then
            print_success "Weekly auto-update enabled ${DIM}(Mondays 10:00)${NC}"
            track_ok "Auto-update"
        else
            print_warning "Could not load the auto-update agent"
            print_item "Run later: launchctl bootstrap gui/\$(id -u) $AUTOUPDATE_PLIST"
            track_warn "Auto-update" "run: launchctl bootstrap gui/\$(id -u) $AUTOUPDATE_PLIST"
        fi
    else
        print_success "Auto-update script and agent written"
        track_ok "Auto-update"
    fi

    log "OK: Auto-update agent written to $AUTOUPDATE_PLIST"
}

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
