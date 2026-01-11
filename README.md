# Pholish

**Polish for Phosh** - A collection of tools, tweaks, and beautiful apps to refine the phosh mobile experience.

## What is Pholish?

Pholish brings a polished, cohesive experience to phosh (the GNOME phone shell). It combines:

- **Beautiful Apps** - Themed, touch-friendly applications with consistent design
- **Phosh Tweaks** - Visual enhancements like touch effects and animations
- **MPRIS Integration** - Media controls on lockscreen and dropdown
- **Unified Backend** - Shared components for scaling, haptics, and theming

## Features

### Apps
| App | Description |
|-----|-------------|
| Music | Clean, elegant music player |
| Audiobooks | Audiobook player with position memory |
| Calculator | Beautiful calculator with history |
| Distract | Focus timer for productivity |
| Weather | Location-based weather |
| Notes | Quick note-taking |
| Photos | Gallery viewer |
| And more... | 16+ polished apps |

### Phosh Integration
- **MPRIS Media Controls** - Control music/audiobooks from phosh lockscreen and dropdown
- **Haptic Feedback** - Touch feedback throughout the UI
- **Adaptive Scaling** - UI scales properly across different screen sizes

### Visual Polish
- Consistent accent colors across all apps
- Smooth animations and transitions
- Touch-optimized controls
- Dark theme throughout

### Touch Effects
- **Water ripples** - Concentric rings on touch
- **Snow/Frost** - Snowflake patterns
- **CRT** - Retro scanline effect
- **Living Pixels** - Stars, fireflies, dust particles

## Installation

```bash
# Clone the repository
git clone --recursive https://github.com/ruapotato/pholish.git
cd pholish

# Run the installer
./install.sh
```

### Enable MPRIS Media Controls

To get media controls in phosh's lockscreen and notification dropdown:

```bash
# Install dependencies
sudo apt install python3-gi python3-dbus gir1.2-glib-2.0

# Copy and enable the systemd service
mkdir -p ~/.config/systemd/user
cp services/mpris-bridge/pholish-mpris.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable pholish-mpris
systemctl --user start pholish-mpris
```

Now when you play music or audiobooks, controls will appear on phosh's lockscreen!

## Directory Structure

```
pholish/
├── apps/                    # Pholish themed apps
│   ├── music/              # Music player
│   ├── audiobooks/         # Audiobook player
│   ├── distract/           # Focus timer
│   └── flick/              # App launcher/settings
├── lib/                    # PholishBackend QML library
│   └── PholishBackend/     # Scaling, Haptic, MediaController
├── services/               # Background services
│   └── mpris-bridge/       # MPRIS daemon for phosh
├── tweaks/                 # Phosh enhancements
│   ├── effects/            # Touch effects
│   └── config/             # Configuration
├── themes/                 # Icons, wallpapers
├── scripts/                # Helper scripts
└── Flick/                  # Core components (submodule)
```

## PholishBackend Library

Apps use the shared PholishBackend QML library:

```qml
import PholishBackend 1.0

// Proportional scaling - UI adapts to screen size
width: Scaling.sp(100)
font.pixelSize: Scaling.fontLarge
spacing: Scaling.spacingNormal

// Haptic feedback
Haptic.tap()     // Light tap for selections
Haptic.click()   // Medium click for toggles
Haptic.heavy()   // Strong for important actions
Haptic.success() // Double tap for success
Haptic.error()   // Long buzz for errors

// Media controls (for player apps)
MediaController.reportStatus({
    title: "Song Name",
    artist: "Artist",
    app: "music",
    playing: true,
    position: 120000,
    duration: 300000
})
```

## Configuration

Settings are stored in `~/.local/state/flick/`:

| File | Purpose |
|------|---------|
| `display_config.json` | Theme (accent color, text scale) |
| `media_status.json` | Current media playback |
| `effects_config.json` | Touch effects settings |

### Display Config Example
```json
{
    "accent_color": "#e94560",
    "text_scale": 1.0,
    "wallpaper": "/path/to/wallpaper.png"
}
```

### Effects Config Example
```json
{
    "touch_effect_style": 0,
    "ripple_size": 0.30,
    "ripple_duration": 0.5,
    "living_pixels": false,
    "lp_stars": true,
    "lp_fireflies": true
}
```

## Commands

### App Management
```bash
# Sync apps to phosh
./scripts/phosh-icon-manager sync

# List apps
./scripts/phosh-icon-manager list

# Hide/show apps
./scripts/phosh-icon-manager hide <app_id>
./scripts/phosh-icon-manager show <app_id>
```

### Effects
```bash
# Enable effects service
systemctl --user enable flick-effects
systemctl --user start flick-effects
```

## Requirements

- Phosh shell (Droidian, Mobian, postmarketOS, etc.)
- Qt5 with QML support
- Python 3 with gi and dbus modules
- PulseAudio or PipeWire

## Contributing

Contributions welcome! Areas to help:

- New polished apps
- Phosh tweaks and enhancements
- Bug fixes and improvements
- Documentation
- Translations

## License

GPL-3.0 - See LICENSE file for details.

## Credits

- Built for [phosh](https://gitlab.gnome.org/World/Phosh/phosh)
- Evolved from the [Flick](https://github.com/ruapotato/Flick) project
