# Flick-Phosh

Flick userland apps running on Phosh - unifying mobile Linux with beautiful, consistent apps.

## Overview

This project ports the Flick app ecosystem to work with Phosh instead of the custom Flick shell. It provides:

- **16 Flick Apps**: Calculator, Calendar, Clock, Files, Maps, Music, Notes, Photos, Store, Video, Weather, and more
- **Phosh Native Integration**: Uses native phosh apps for Phone (Calls), Messages (Chatty), Contacts, Terminal (Console), Email (Geary), and Browser (Firefox)
- **App Folder System**: Non-Flick apps organized into an "Other Apps" folder using native phosh folders
- **Flick Store**: Install apps from 255.one app store

## Structure

```
flick-phosh/
├── Flick/                  # Cloned Flick repo (apps, icons, store backend)
│   ├── apps/               # QML applications
│   ├── icons/              # App icons
│   ├── flick_forge/        # Store backend (submodule)
│   └── flick-pkg           # Package manager
├── scripts/
│   ├── phosh-icon-manager  # Manage phosh app visibility and folders
│   ├── flick-pkg           # Package manager (adapted for phosh)
│   └── flick-app-launcher  # QML app launcher with proper environment
├── apps/
│   └── other-apps/         # Other Apps folder (legacy QML version)
└── icons/
    ├── flick/              # Custom icons
    └── other-apps/         # Icons for curated apps
```

## Installation

```bash
# Clone the repo with submodules
git clone --recursive https://github.com/ruapotato/flick-phosh
cd flick-phosh

# Run the installer (does everything)
./install.sh
```

The installer will:
1. Apply patches to Flick apps for phosh compatibility
2. Install Flick icon pack
3. Create .desktop files for all Flick apps
4. Set up the "Other Apps" folder with native phosh apps
5. Configure proper UI scaling

## Commands

### phosh-icon-manager

```bash
# Sync Flick apps to phosh
./scripts/phosh-icon-manager sync

# List apps
./scripts/phosh-icon-manager list        # Show Flick + curated apps
./scripts/phosh-icon-manager list --all  # Show all apps including system

# Manage "Other Apps" folder
./scripts/phosh-icon-manager curate <app_id>    # Add app to folder
./scripts/phosh-icon-manager uncurate <app_id>  # Remove from folder

# Apply changes
./scripts/phosh-icon-manager apply-curation  # Create folder, hide clutter
./scripts/phosh-icon-manager refresh         # Update phosh app database

# Hide/show specific apps
./scripts/phosh-icon-manager hide <app_id>
./scripts/phosh-icon-manager show <app_id>
```

### flick-pkg (Package Manager)

```bash
# List available packages
./scripts/flick-pkg list

# Search packages
./scripts/flick-pkg search <query>

# Install/uninstall
./scripts/flick-pkg install <app_id>
./scripts/flick-pkg uninstall <app_id>

# Show installed apps
./scripts/flick-pkg installed
```

## App Layout

### Main Grid (Flick Apps)
- Calculator, Calendar, Clock
- Distract, Files, Lap Track
- Maps, Music, Notes
- Photos, Store, Video
- Voice Recorder, Weather
- Flick Audiobooks, Flick Ebooks

### Other Apps Folder (Native Phosh)
- Calls (GNOME Calls)
- Contacts (GNOME Contacts)
- Chats (Chatty)
- Console (GNOME Console/Terminal)
- Email (Geary)
- Firefox

## Phosh Native Apps Used

Instead of porting these Flick apps, we use phosh's native equivalents:

| Function | Phosh App | App ID |
|----------|-----------|--------|
| Phone | GNOME Calls | org.gnome.Calls |
| Messages | Chatty | sm.puri.Chatty |
| Contacts | GNOME Contacts | org.gnome.Contacts |
| Terminal | Console | org.gnome.Console |
| Email | Geary | org.gnome.Geary |
| Browser | Firefox | firefox |

## Configuration

App state is stored in `~/.local/state/flick-phosh/`:
- `curated_other_apps.json` - Apps in the "Other Apps" folder
- `hidden_apps.json` - Manually hidden apps
- `folders/` - Folder configuration

## Requirements

- Phosh shell
- Qt5 with QML support (`qmlscene`)
- Python 3

## Roadmap

### Planned Improvements

- **Responsive UI**: Convert all apps to use proportional sizing instead of hardcoded pixels
- **MPRIS Media Controls**: Music/Audiobooks/Recorder integration with phosh media controls
- **Phosh Integration**:
  - Read accent color from phosh/GNOME settings
  - Use GeoClue for Weather location
  - Proper notifications via D-Bus
- **Flick Library**: Central QML library for apps with:
  - Theme management (accent colors, dark/light mode)
  - Media player controls
  - Notification helpers
  - Responsive layout utilities
- **AI-Friendly Design**: Modular app structure for easy AI-assisted development

### Known Issues

- Some apps have oversized UI on certain screen resolutions
- Weather requires manual location configuration
- Media apps don't show playback controls in phosh

## License

GPL-3.0 (same as original Flick project)
