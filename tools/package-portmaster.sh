#!/usr/bin/env bash
# Builds the PortMaster port: exports the ARM64 .pck and assembles build/portmaster/xpeedy.zip
# (Xpeedy.sh + xpeedy/ folder, as listed in port.json) and build/portmaster/submission/, the layout of a
# PortMaster pull request (the port files plus cover.png, screenshot.png and preview.mp4).
set -euo pipefail

TOOLS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$TOOLS/.." && pwd)"
OUT="$REPO/build/portmaster"
STAGE="$OUT/stage"

rm -rf "$OUT"
mkdir -p "$STAGE/xpeedy/gamedata" "$STAGE/xpeedy/licenses"

"$TOOLS/godot.sh" --headless --import >/dev/null 2>&1 || true
"$TOOLS/godot.sh" --headless --export-pack "PortMaster" build/portmaster/xpeedy.pck

cp "$OUT/xpeedy.pck" "$STAGE/xpeedy/gamedata/"
cp "$REPO/packaging/portmaster/Xpeedy.sh" "$STAGE/"
chmod +x "$STAGE/Xpeedy.sh"
cp "$REPO/packaging/portmaster/xpeedy/xpeedy.gptk" "$STAGE/xpeedy/"
cp "$REPO/LICENSE" "$STAGE/xpeedy/licenses/LICENSE.xpeedy.txt"
cp "$REPO/assets/fonts/OFL.txt" "$STAGE/xpeedy/licenses/OFL.orbitron.txt"
cp "$REPO/packaging/portmaster/port.json" "$REPO/packaging/portmaster/gameinfo.xml" \
	"$REPO/packaging/portmaster/README.md" "$STAGE/xpeedy/"

(cd "$STAGE" && zip -qr "$OUT/xpeedy.zip" Xpeedy.sh xpeedy)
SUB="$OUT/submission"
mkdir -p "$SUB"
cp "$STAGE/Xpeedy.sh" "$SUB/"
cp -r "$STAGE/xpeedy" "$SUB/"
cp "$REPO/packaging/portmaster/port.json" "$REPO/packaging/portmaster/gameinfo.xml" \
	"$REPO/packaging/portmaster/README.md" "$SUB/"
for art in cover.png screenshot.png preview.mp4; do
	[ -f "$REPO/packaging/portmaster/$art" ] && cp "$REPO/packaging/portmaster/$art" "$SUB/"
done
echo "Built $OUT/xpeedy.zip and $SUB"
