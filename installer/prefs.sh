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
