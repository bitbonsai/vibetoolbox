#!/bin/bash
# Vibe Toolbox installer
# https://vibetoolbox.dev

# Note: we intentionally do NOT use 'set -e' here. Brew and other tools can
# return non-zero for non-fatal reasons (warnings, already-installed, etc.).
# Each critical step has explicit error handling instead.

# Baked-in selection. The vibetoolbox.dev server replaces this line when the
# script is served from a /i/<slug> share URL. Leave empty in the source.
VTB_SELECTION="${VTB_SELECTION:-}"
