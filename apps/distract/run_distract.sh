#!/bin/bash
# Distract app launcher - Focus timer and productivity

SCRIPT_DIR="$(dirname "$0")"
QML_FILE="${SCRIPT_DIR}/main.qml"
LOG_FILE="${HOME}/.local/state/flick/distract.log"

mkdir -p "${HOME}/.local/state/flick"

> "$LOG_FILE"
echo "Starting Distract" >> "$LOG_FILE"

export QT_LOGGING_RULES="qt.qpa.*=false;qt.accessibility.*=false"
export QML_XHR_ALLOW_FILE_READ=1
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QT_WAYLAND_CLIENT_BUFFER_INTEGRATION=wayland-egl
export QT_AUTO_SCREEN_SCALE_FACTOR=0

DISPLAY_CONFIG="${HOME}/.local/state/flick/display_config.json"
TEXT_SCALE="2.0"
if [ -f "$DISPLAY_CONFIG" ]; then
    SAVED_SCALE=$(cat "$DISPLAY_CONFIG" | grep -o '"text_scale"[[:space:]]*:[[:space:]]*[0-9.]*' | grep -o '[0-9.]*$')
    if [ -n "$SAVED_SCALE" ]; then
        TEXT_SCALE="$SAVED_SCALE"
    fi
fi
export QT_SCALE_FACTOR="$TEXT_SCALE"
export QT_FONT_DPI=$(echo "$TEXT_SCALE * 96" | bc)

/usr/lib/qt5/bin/qmlscene "$QML_FILE" 2>> "$LOG_FILE"
