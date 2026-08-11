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
