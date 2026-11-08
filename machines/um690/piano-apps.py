#!/usr/bin/env python3
"""Runs before PianoBooster or Neothesia starts (piano.nix wraps both), and
points it at the MicroLab and, for PianoBooster, at the piano.

Both apps keep the MIDI ports in their settings by name, and the name carries
the port's ALSA client number: "MicroLab mk3:MicroLab mk3 28:0". PianoBooster
also puts the port's position in its list in front, "1 - ...". The keyboard's
number follows its sound card's, which follows the order cards come up in, and
the piano's is whatever client number was free when it last started. So a name
saved once goes stale, and the app then starts with no keyboard. This writes
the names ALSA has right now, for the ports that are ours: a port picked by
hand in the app, that is neither of these two, stays picked.

How each app is set up, and why, is in piano.nix.

Usage: piano-apps.py pianobooster|neothesia PATH-TO-midi-ports
"""
import configparser
import json
import os
import re
import subprocess
import sys
from pathlib import Path

KEYBOARD = "MicroLab mk3"
PIANO = "FLUID Synth (piano)"


def ports(midi_ports):
    out = subprocess.run([midi_ports], capture_output=True, text=True).stdout
    return [line.split("\t") for line in out.splitlines()]


def find(listed, direction, client):
    """Position and name of the first port of `client` in that direction."""
    for d, index, c, name in listed:
        if d == direction and c == client:
            return int(index), name
    return None


def pianobooster(listed, config):
    path = config / "PianoBooster" / "Piano Booster.ini"
    ini = configparser.RawConfigParser(strict=False)
    ini.optionxform = str  # QSettings keys are case-sensitive
    ini.read(path)
    for section in ("Midi", "Keyboard"):
        if not ini.has_section(section):
            ini.add_section(section)

    def follow(key, port, client):
        old = ini.get("Midi", key, fallback="")
        if port and (not old or client in old):
            ini.set("Midi", key, f"{port[0]} - {port[1]}")

    follow("Input", find(listed, "in", KEYBOARD), KEYBOARD)
    follow("Output", find(listed, "out", PIANO), PIANO)
    # PianoBooster plays each key you press back out, as a "right note" or
    # "wrong note" sound. The piano already hears the keyboard, so that would
    # be every note twice. 0 is "None" for both; set once, then left alone.
    for key in ("RightSound", "WrongSound"):
        if not ini.has_option("Keyboard", key):
            ini.set("Keyboard", key, "0")

    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w") as f:
        ini.write(f, space_around_delimiters=False)


def neothesia(listed, config):
    path = config / "neothesia" / "settings.ron"
    keyboard = find(listed, "in", KEYBOARD)
    name = f"Some({json.dumps(keyboard[1])})" if keyboard else "None"
    if not path.exists():
        # Only the devices; Neothesia defaults the rest and writes them out.
        # No Output: see piano.nix.
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f"(\n    devices: V1(\n        output: None,\n        input: {name},\n    ),\n)\n")
        return
    if not keyboard:
        return
    text = path.read_text()
    at = text.find("devices:")
    if at < 0:
        return
    pattern = r'(\binput:\s*)(None|Some\("' + re.escape(KEYBOARD) + r'[^"]*"\))'
    head, tail = text[:at], text[at:]
    tail = re.sub(pattern, lambda m: m.group(1) + name, tail, count=1)
    path.write_text(head + tail)


def main():
    app, midi_ports = sys.argv[1], sys.argv[2]
    config = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    {"pianobooster": pianobooster, "neothesia": neothesia}[app](ports(midi_ports), config)


if __name__ == "__main__":
    main()
