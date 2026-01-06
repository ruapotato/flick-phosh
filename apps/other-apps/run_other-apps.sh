#!/bin/bash
# Other Apps Folder - Shows curated non-Flick apps

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOME/.local/state/flick"
LOG_FILE="${STATE_DIR}/other-apps.log"

mkdir -p "$STATE_DIR"

echo "=== Other Apps folder opened at $(date) ===" >> "$LOG_FILE"

# Set Wayland environment
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QT_AUTO_SCREEN_SCALE_FACTOR=1

# Run the folder app
exec qmlscene "$SCRIPT_DIR/main.qml" 2>> "$LOG_FILE"
