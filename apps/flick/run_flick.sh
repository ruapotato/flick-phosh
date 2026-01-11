#!/bin/bash
# Flick Control Center - Unified settings and app creation

SCRIPT_DIR="$(dirname "$0")"
QML_FILE="${SCRIPT_DIR}/main.qml"
LOG_FILE="${HOME}/.local/state/flick/flick_app.log"

# Ensure state directories exist
mkdir -p "${HOME}/.local/state/flick"
mkdir -p "${HOME}/.local/state/flick-phosh"

# Clear old log
> "$LOG_FILE"

echo "Starting Flick Control Center" >> "$LOG_FILE"

# Scan installed apps for the app manager
SCANNER="${HOME}/flick-phosh/scripts/scan-apps"
if [ -x "$SCANNER" ]; then
    echo "Scanning installed apps..." >> "$LOG_FILE"
    python3 "$SCANNER" >> "$LOG_FILE" 2>&1
fi

# Qt environment
export QT_LOGGING_RULES="qt.qpa.*=false;qt.accessibility.*=false;qml=true"
export QT_MESSAGE_PATTERN=""
export QML_XHR_ALLOW_FILE_READ=1
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QT_WAYLAND_CLIENT_BUFFER_INTEGRATION=wayland-egl
export QT_AUTO_SCREEN_SCALE_FACTOR=0

# Apply text scale if configured
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

echo "Using text scale: $TEXT_SCALE" >> "$LOG_FILE"

# State directories
STATE_DIR="${HOME}/.local/state/flick-phosh"
EFFECTS_STATE_DIR="${HOME}/.local/state/flick"

# Function to process QML output commands
process_qml_output() {
    while IFS= read -r line; do
        echo "$line" >> "$LOG_FILE"

        # Check for save commands
        if [[ "$line" == *"SAVE_EXCLUDED:"* ]]; then
            json="${line#*SAVE_EXCLUDED:}"
            echo "$json" > "${STATE_DIR}/excluded_apps.json"
            echo "Saved excluded apps" >> "$LOG_FILE"
        elif [[ "$line" == *"SAVE_OTHER_APPS:"* ]]; then
            json="${line#*SAVE_OTHER_APPS:}"
            echo "$json" > "${STATE_DIR}/curated_other_apps.json"
            echo "Saved other apps" >> "$LOG_FILE"
            # Sync to phosh dconf folder (updates live without restart)
            dconf_apps=$(python3 -c "import json; apps=json.loads('$json'); print('[' + ', '.join([\"'\" + a + \".desktop'\" for a in apps]) + ']')" 2>/dev/null)
            if [ -n "$dconf_apps" ]; then
                dconf write /org/gnome/desktop/app-folders/folders/d6b319c0-2f3e-4200-9d7c-c72a17431b53/apps "$dconf_apps"
                echo "Synced phosh Other Apps folder" >> "$LOG_FILE"
            fi
        elif [[ "$line" == *"SAVE_EFFECTS:"* ]]; then
            json="${line#*SAVE_EFFECTS:}"
            echo "$json" > "${EFFECTS_STATE_DIR}/effects_config.json"
            echo "Saved effects config" >> "$LOG_FILE"
            # Restart effects service to apply changes immediately
            systemctl --user restart flick-effects 2>/dev/null &
            echo "Restarted flick-effects service" >> "$LOG_FILE"
        elif [[ "$line" == *"SAVE_THEME:"* ]]; then
            json="${line#*SAVE_THEME:}"
            # Merge with existing display config
            if [ -f "${EFFECTS_STATE_DIR}/display_config.json" ]; then
                existing=$(cat "${EFFECTS_STATE_DIR}/display_config.json")
                # Extract accent_color from json
                accent=$(echo "$json" | grep -o '"accent_color"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"#[^"]*"' | tr -d '"')
                if [ -n "$accent" ]; then
                    # Update or add accent_color in existing config
                    if echo "$existing" | grep -q '"accent_color"'; then
                        updated=$(echo "$existing" | sed "s/\"accent_color\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"accent_color\": \"$accent\"/")
                    else
                        updated=$(echo "$existing" | sed "s/}$/, \"accent_color\": \"$accent\"}/")
                    fi
                    echo "$updated" > "${EFFECTS_STATE_DIR}/display_config.json"
                fi
            else
                echo "{\"accent_color\": \"#e94560\", \"text_scale\": 2.0}" > "${EFFECTS_STATE_DIR}/display_config.json"
            fi
            echo "Saved theme config" >> "$LOG_FILE"
        elif [[ "$line" == *"CLAUDE_REQUEST:"* ]]; then
            request="${line#*CLAUDE_REQUEST:}"
            echo "$request" > /tmp/flick_claude_request
            echo "Claude request saved" >> "$LOG_FILE"
            # Trigger Claude Code in background
            (
                cd "${HOME}/flick-phosh"
                echo "Processing..." > /tmp/flick_claude_status
                # This would be where Claude Code is invoked
                # For now, just log it
                echo "DONE: Request logged. Run Claude Code manually in ${HOME}/flick-phosh" > /tmp/flick_claude_status
            ) &
        elif [[ "$line" == *"HAPTIC:"* ]]; then
            cmd="${line#*HAPTIC:}"
            echo "$cmd" > /tmp/flick_haptic 2>/dev/null || true
        fi
    done
}

# Run qmlscene and process output
/usr/lib/qt5/bin/qmlscene "$QML_FILE" 2>&1 | process_qml_output

echo "Flick exited" >> "$LOG_FILE"
