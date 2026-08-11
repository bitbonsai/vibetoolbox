#!/bin/bash
# Build script: generates installer/catalog.sh from catalog.json, then
# concatenates installer/*.sh modules into public/install.sh
# Usage: bash scripts/build.sh

set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INSTALLER_DIR="$ROOT_DIR/installer"
OUTPUT="$ROOT_DIR/public/install.sh"
CATALOG_JSON="$ROOT_DIR/catalog.json"
CATALOG_SH="$INSTALLER_DIR/catalog.sh"

command -v jq >/dev/null || { echo "ERROR: jq is required to build" >&2; exit 1; }

jq empty "$CATALOG_JSON" || { echo "ERROR: catalog.json is not valid JSON" >&2; exit 1; }

# --- Generate installer/catalog.sh from catalog.json ---
{
    echo "# ============================================================================="
    echo "# TOOL CATALOG (generated from catalog.json by scripts/build.sh — do not edit)"
    echo "# ============================================================================="
    echo "# Fields: id|kind|target|app|bin|name|requires"
    echo ""
    echo "CATALOG=("
    jq -r '.tools[] | "    \"" + ([.id, .kind, .target, (.app // ""), (.bin // ""), .name, ((.requires // []) | join(","))] | join("|")) + "\""' "$CATALOG_JSON"
    echo ")"
} > "$CATALOG_SH"

# Copy catalog.json into public/ so the picker can fetch it
cp "$CATALOG_JSON" "$ROOT_DIR/public/catalog.json"

# Module order matters — functions must be defined before use in main.sh
MODULES=(
    header.sh
    common.sh
    catalog.sh
    selection.sh
    uninstall.sh
    prefs.sh
    prereqs.sh
    tools.sh
    update.sh
    autoupdate.sh
    git-config.sh
    github-cli.sh
    shell.sh
    main.sh
)

# Verify all modules exist
for module in "${MODULES[@]}"; do
    if [[ ! -f "$INSTALLER_DIR/$module" ]]; then
        echo "ERROR: Missing module: $INSTALLER_DIR/$module" >&2
        exit 1
    fi
done

# Concatenate modules
{
    first=true
    for module in "${MODULES[@]}"; do
        if [[ "$first" == true ]]; then
            # First module (header.sh) — include the shebang line
            cat "$INSTALLER_DIR/$module"
            first=false
        else
            # Subsequent modules — add blank line separator
            echo ""
            cat "$INSTALLER_DIR/$module"
        fi
    done
} > "$OUTPUT"

echo "Built public/install.sh from ${#MODULES[@]} modules ($(jq '.tools | length' "$CATALOG_JSON") tools in catalog)"
