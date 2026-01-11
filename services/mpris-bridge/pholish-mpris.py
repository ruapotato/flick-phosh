#!/usr/bin/env python3
"""
Pholish MPRIS Bridge - Exposes Pholish media players to phosh via MPRIS

This daemon reads media status from ~/.local/state/flick/media_status.json
and exposes it via the MPRIS D-Bus interface, allowing phosh's lockscreen
and dropdown to display and control Pholish media apps.
"""

import os
import sys
import json
import time
import threading
from pathlib import Path

try:
    from gi.repository import GLib
    import dbus
    import dbus.service
    import dbus.mainloop.glib
except ImportError:
    print("Error: Required packages not found. Install with:")
    print("  sudo apt install python3-gi python3-dbus gir1.2-glib-2.0")
    sys.exit(1)

# Constants
STATE_DIR = Path(os.environ.get("HOME", "/home/droidian")) / ".local/state/flick"
MEDIA_STATUS_FILE = STATE_DIR / "media_status.json"
MEDIA_COMMAND_FILE = STATE_DIR / "media_command"

MPRIS_INTERFACE = "org.mpris.MediaPlayer2"
MPRIS_PLAYER_INTERFACE = "org.mpris.MediaPlayer2.Player"
MPRIS_PATH = "/org/mpris/MediaPlayer2"
BUS_NAME = "org.mpris.MediaPlayer2.pholish"


class MPRISInterface(dbus.service.Object):
    """MPRIS MediaPlayer2 root interface"""

    def __init__(self, bus, path):
        super().__init__(bus, path)
        self._properties = {
            "CanQuit": False,
            "CanRaise": False,
            "HasTrackList": False,
            "Identity": "Pholish Media",
            "DesktopEntry": "pholish",
            "SupportedUriSchemes": dbus.Array([], signature="s"),
            "SupportedMimeTypes": dbus.Array([], signature="s"),
        }

    @dbus.service.method(MPRIS_INTERFACE, in_signature="", out_signature="")
    def Raise(self):
        pass

    @dbus.service.method(MPRIS_INTERFACE, in_signature="", out_signature="")
    def Quit(self):
        pass

    @dbus.service.method(dbus.PROPERTIES_IFACE, in_signature="ss", out_signature="v")
    def Get(self, interface, prop):
        return self._properties.get(prop, "")

    @dbus.service.method(dbus.PROPERTIES_IFACE, in_signature="s", out_signature="a{sv}")
    def GetAll(self, interface):
        if interface == MPRIS_INTERFACE:
            return self._properties
        return {}


class MPRISPlayerInterface(dbus.service.Object):
    """MPRIS MediaPlayer2.Player interface"""

    def __init__(self, bus, path):
        super().__init__(bus, path)
        self._media_status = {}
        self._last_check = 0

    def _send_command(self, cmd):
        """Send command to media player via file"""
        try:
            timestamp = int(time.time() * 1000)
            MEDIA_COMMAND_FILE.write_text(f"{cmd}:{timestamp}")
            print(f"MPRIS: Sent command: {cmd}")
        except Exception as e:
            print(f"MPRIS: Failed to send command: {e}")

    def _load_status(self):
        """Load media status from JSON file"""
        try:
            if MEDIA_STATUS_FILE.exists():
                content = MEDIA_STATUS_FILE.read_text()
                if content.strip():
                    status = json.loads(content)
                    # Check if status is fresh (within 60s for paused, 10s for playing)
                    now = int(time.time() * 1000)
                    age = now - status.get("timestamp", 0)
                    max_age = 10000 if status.get("playing", False) else 60000
                    if age < max_age and status.get("title"):
                        self._media_status = status
                        return True
            self._media_status = {}
            return False
        except Exception as e:
            print(f"MPRIS: Failed to load status: {e}")
            self._media_status = {}
            return False

    @property
    def _playback_status(self):
        if not self._media_status:
            return "Stopped"
        return "Playing" if self._media_status.get("playing", False) else "Paused"

    @property
    def _metadata(self):
        if not self._media_status:
            return dbus.Dictionary({}, signature="sv")

        title = self._media_status.get("title", "")
        artist = self._media_status.get("artist", "")
        duration = self._media_status.get("duration", 0) * 1000  # Convert to microseconds
        app = self._media_status.get("app", "music")

        # Create track ID based on title
        track_id = f"/org/pholish/{app}/track/{hash(title) & 0xFFFFFFFF}"

        metadata = {
            "mpris:trackid": dbus.ObjectPath(track_id),
            "mpris:length": dbus.Int64(duration),
            "xesam:title": title,
            "xesam:artist": dbus.Array([artist], signature="s"),
            "xesam:album": app.capitalize(),
        }
        return dbus.Dictionary(metadata, signature="sv")

    @property
    def _position(self):
        return dbus.Int64(self._media_status.get("position", 0) * 1000)  # microseconds

    # MPRIS Player Methods
    @dbus.service.method(MPRIS_PLAYER_INTERFACE, in_signature="", out_signature="")
    def Next(self):
        app = self._media_status.get("app", "music")
        if app == "music":
            self._send_command("next")
        else:
            self._send_command("seek:30000")

    @dbus.service.method(MPRIS_PLAYER_INTERFACE, in_signature="", out_signature="")
    def Previous(self):
        app = self._media_status.get("app", "music")
        if app == "music":
            self._send_command("prev")
        else:
            self._send_command("seek:-30000")

    @dbus.service.method(MPRIS_PLAYER_INTERFACE, in_signature="", out_signature="")
    def Pause(self):
        self._send_command("pause")

    @dbus.service.method(MPRIS_PLAYER_INTERFACE, in_signature="", out_signature="")
    def PlayPause(self):
        if self._media_status.get("playing", False):
            self._send_command("pause")
        else:
            self._send_command("play")

    @dbus.service.method(MPRIS_PLAYER_INTERFACE, in_signature="", out_signature="")
    def Stop(self):
        self._send_command("pause")

    @dbus.service.method(MPRIS_PLAYER_INTERFACE, in_signature="", out_signature="")
    def Play(self):
        self._send_command("play")

    @dbus.service.method(MPRIS_PLAYER_INTERFACE, in_signature="x", out_signature="")
    def Seek(self, offset):
        # offset is in microseconds, convert to milliseconds
        offset_ms = offset // 1000
        self._send_command(f"seek:{offset_ms}")

    @dbus.service.method(MPRIS_PLAYER_INTERFACE, in_signature="ox", out_signature="")
    def SetPosition(self, track_id, position):
        # position is in microseconds, convert to milliseconds
        pos_ms = position // 1000
        self._send_command(f"seek_to:{pos_ms}")

    @dbus.service.method(MPRIS_PLAYER_INTERFACE, in_signature="s", out_signature="")
    def OpenUri(self, uri):
        pass  # Not supported

    # Properties
    @dbus.service.method(dbus.PROPERTIES_IFACE, in_signature="ss", out_signature="v")
    def Get(self, interface, prop):
        self._load_status()

        if interface == MPRIS_PLAYER_INTERFACE:
            props = {
                "PlaybackStatus": self._playback_status,
                "LoopStatus": "None",
                "Rate": dbus.Double(1.0),
                "Shuffle": False,
                "Metadata": self._metadata,
                "Volume": dbus.Double(1.0),
                "Position": self._position,
                "MinimumRate": dbus.Double(1.0),
                "MaximumRate": dbus.Double(1.0),
                "CanGoNext": True,
                "CanGoPrevious": True,
                "CanPlay": True,
                "CanPause": True,
                "CanSeek": True,
                "CanControl": True,
            }
            return props.get(prop, "")
        return ""

    @dbus.service.method(dbus.PROPERTIES_IFACE, in_signature="s", out_signature="a{sv}")
    def GetAll(self, interface):
        self._load_status()

        if interface == MPRIS_PLAYER_INTERFACE:
            return dbus.Dictionary({
                "PlaybackStatus": self._playback_status,
                "LoopStatus": "None",
                "Rate": dbus.Double(1.0),
                "Shuffle": False,
                "Metadata": self._metadata,
                "Volume": dbus.Double(1.0),
                "Position": self._position,
                "MinimumRate": dbus.Double(1.0),
                "MaximumRate": dbus.Double(1.0),
                "CanGoNext": True,
                "CanGoPrevious": True,
                "CanPlay": True,
                "CanPause": True,
                "CanSeek": True,
                "CanControl": True,
            }, signature="sv")
        return dbus.Dictionary({}, signature="sv")

    @dbus.service.method(dbus.PROPERTIES_IFACE, in_signature="ssv", out_signature="")
    def Set(self, interface, prop, value):
        pass  # Read-only properties

    @dbus.service.signal(dbus.PROPERTIES_IFACE, signature="sa{sv}as")
    def PropertiesChanged(self, interface, changed, invalidated):
        pass

    def emit_properties_changed(self):
        """Emit signal when properties change"""
        self._load_status()
        changed = {
            "PlaybackStatus": self._playback_status,
            "Metadata": self._metadata,
            "Position": self._position,
        }
        self.PropertiesChanged(MPRIS_PLAYER_INTERFACE, changed, [])


class PholishMPRISService:
    """Main MPRIS service that monitors media status and exposes D-Bus interface"""

    def __init__(self):
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

        self.bus = dbus.SessionBus()
        self.bus_name = dbus.service.BusName(BUS_NAME, self.bus)

        self.root = MPRISInterface(self.bus, MPRIS_PATH)
        self.player = MPRISPlayerInterface(self.bus, MPRIS_PATH)

        self.last_status = {}
        self.loop = GLib.MainLoop()

    def check_status_changes(self):
        """Check for media status changes and emit signals"""
        try:
            if MEDIA_STATUS_FILE.exists():
                content = MEDIA_STATUS_FILE.read_text()
                if content.strip():
                    status = json.loads(content)
                    # Check if status changed
                    if status != self.last_status:
                        self.last_status = status.copy()
                        self.player.emit_properties_changed()
                        print(f"MPRIS: Status changed - {status.get('title', 'Unknown')}")
        except Exception as e:
            pass  # Ignore errors, just try again later

        return True  # Continue timer

    def run(self):
        """Run the MPRIS service"""
        print(f"Pholish MPRIS Bridge started")
        print(f"  Bus name: {BUS_NAME}")
        print(f"  Watching: {MEDIA_STATUS_FILE}")

        # Check for status changes every second
        GLib.timeout_add(1000, self.check_status_changes)

        try:
            self.loop.run()
        except KeyboardInterrupt:
            print("\nPholish MPRIS Bridge stopped")


def main():
    # Ensure state directory exists
    STATE_DIR.mkdir(parents=True, exist_ok=True)

    service = PholishMPRISService()
    service.run()


if __name__ == "__main__":
    main()
