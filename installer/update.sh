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
