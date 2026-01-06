#!/bin/bash
# Flick-Phosh Installer
# Installs Flick apps and icons on phosh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "================================"
echo "  Flick-Phosh Installer"
echo "================================"
echo ""

# Check for required tools
echo "Checking dependencies..."
command -v qmlscene >/dev/null 2>&1 || { echo "Error: qmlscene not found. Install qt5-qmlscene."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Error: python3 not found."; exit 1; }
echo "  Dependencies OK"

# Initialize submodules if needed
if [ ! -f "Flick/apps/calculator/main.qml" ]; then
    echo ""
    echo "Initializing Flick submodule..."
    git submodule update --init --recursive
fi

# Apply patches to Flick run scripts
echo ""
echo "Applying patches to Flick apps..."
for script in Flick/apps/*/run_*.sh; do
    if [ -f "$script" ]; then
        # Fix BASH_SOURCE for proper path detection
        sed -i 's|SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE\[0\]}")" \&\& pwd)"|SCRIPT_DIR="\$(cd "\$(dirname "\$0")" \&\& pwd)"|' "$script"

        # Add QT_SCALE_FACTOR if not present
        if ! grep -q "QT_SCALE_FACTOR" "$script"; then
            sed -i '/QT_WAYLAND_DISABLE_WINDOWDECORATION=1/a export QT_SCALE_FACTOR=0.6\nexport QT_AUTO_SCREEN_SCALE_FACTOR=0' "$script"
        fi
    fi
done
echo "  Patches applied"

# Create phosh-compatible config
echo ""
echo "Creating phosh configuration..."
mkdir -p "$HOME/.local/state/flick"
cat > "$HOME/.local/state/flick/display_config.json" << 'EOF'
{
    "text_scale": 0.7,
    "accent_color": "#3584e4"
}
EOF
echo "  Config created"

# Sync Flick apps to phosh
echo ""
echo "Syncing Flick apps to phosh..."
./scripts/phosh-icon-manager sync

# Set up default curated apps
echo ""
echo "Setting up Other Apps folder..."
./scripts/phosh-icon-manager curate org.gnome.Calls org.gnome.Contacts sm.puri.Chatty 2>/dev/null || true
./scripts/phosh-icon-manager curate firefox org.gnome.Console org.gnome.Geary Andromeda 2>/dev/null || true

# Apply curation
./scripts/phosh-icon-manager apply-curation

# Refresh
./scripts/phosh-icon-manager refresh

echo ""
echo "================================"
echo "  Installation Complete!"
echo "================================"
echo ""
echo "Flick apps are now available in phosh."
echo "Non-Flick apps are in the 'Other Apps' folder."
echo ""
echo "You may need to restart phosh to see all changes:"
echo "  systemctl --user restart phosh"
echo ""
echo "To manage apps:"
echo "  ./scripts/phosh-icon-manager list"
echo "  ./scripts/phosh-icon-manager curate <app_id>"
echo "  ./scripts/phosh-icon-manager apply-curation"
echo ""
