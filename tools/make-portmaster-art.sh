#!/usr/bin/env bash
# Makes the PortMaster publishing art from the game itself: packaging/portmaster/screenshot.png, cover.png and
# preview.mp4 (ADR 0033). Needs the Linux build (tools/export.sh), a GPU or software GL, python3 with PIL and
# ffmpeg. The images and the video are our own captures; nothing of the original game is used.
set -euo pipefail

TOOLS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$TOOLS/.." && pwd)"
GAME="$REPO/build/linux/xpeedy.x86_64"
OUT="$REPO/packaging/portmaster"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

[ -x "$GAME" ] || { echo "Build the game first: tools/export.sh" >&2; exit 1; }

# A flat-out moment in a tube with obstacles and trails ahead.
"$GAME" --resolution 640x480 -- --seed=2024 --start-segment=395 --invulnerable --shields=3 --no-countdown \
	--screenshot="$OUT/screenshot.png,0.45" >/dev/null

# The cover: the screenshot dimmed, the title in the game's typeface.
PYTHONPATH=/usr/lib/python3/dist-packages python3 "$TOOLS/make_cover.py" \
	"$OUT/screenshot.png" "$REPO/assets/fonts/Orbitron.ttf" "$OUT/cover.png"

# Twelve seconds of an autopilot run with the music, recorded by Godot's movie writer.
"$GAME" --write-movie "$TMP/clip.avi" --fixed-fps 30 --resolution 640x480 --quit-after 360 -- \
	--seed=2024 --start-segment=300 --autopilot=plough --shields=4 --invulnerable --no-countdown >/dev/null 2>&1
ffmpeg -y -loglevel error -i "$TMP/clip.avi" -c:v libx264 -preset slow -crf 24 -pix_fmt yuv420p \
	-c:a aac -b:a 128k -movflags +faststart "$OUT/preview.mp4"
ls -la "$OUT/screenshot.png" "$OUT/cover.png" "$OUT/preview.mp4"
