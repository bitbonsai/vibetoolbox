# =============================================================================
# SELECTION
# =============================================================================
# CATALOG is generated from catalog.json by scripts/build.sh (catalog.sh).
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
