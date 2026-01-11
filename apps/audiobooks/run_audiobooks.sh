#!/bin/bash
# Audiobooks app launcher

SCRIPT_DIR="$(dirname "$0")"
QML_FILE="${SCRIPT_DIR}/main.qml"
LOG_FILE="${HOME}/.local/state/flick/audiobooks.log"

# FlickBackend library path
FLICK_LIB_DIR="${SCRIPT_DIR}/../../Flick/lib"

mkdir -p "${HOME}/.local/state/flick"
mkdir -p "${HOME}/Audiobooks"

> "$LOG_FILE"
echo "Starting Audiobooks" >> "$LOG_FILE"

export QT_LOGGING_RULES="qt.qpa.*=false;qt.accessibility.*=false"
export QML_XHR_ALLOW_FILE_READ=1
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QT_WAYLAND_CLIENT_BUFFER_INTEGRATION=wayland-egl
export QT_AUTO_SCREEN_SCALE_FACTOR=0

# Add FlickBackend library to QML import path
export QML2_IMPORT_PATH="${FLICK_LIB_DIR}:${QML2_IMPORT_PATH}"

DISPLAY_CONFIG="${HOME}/.local/state/flick/display_config.json"
TEXT_SCALE="1.0"
if [ -f "$DISPLAY_CONFIG" ]; then
    SAVED_SCALE=$(cat "$DISPLAY_CONFIG" | grep -o '"text_scale"[[:space:]]*:[[:space:]]*[0-9.]*' | grep -o '[0-9.]*$')
    if [ -n "$SAVED_SCALE" ]; then
        TEXT_SCALE="$SAVED_SCALE"
    fi
fi
export QT_SCALE_FACTOR="$TEXT_SCALE"

/usr/lib/qt5/bin/qmlscene "$QML_FILE" 2>> "$LOG_FILE"
