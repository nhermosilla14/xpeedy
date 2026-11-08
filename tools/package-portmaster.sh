#!/usr/bin/env bash
# Builds the PortMaster port (ADR 0035, 0037): exports the ARM64 .pck and assembles two folders.
#   build/portmaster/xpeedy.zip     what a tester installs: Xpeedy.sh and the xpeedy/ game folder.
#   build/portmaster/submission/    the layout of a PortMaster pull request: the port folder with metadata and art.
set -euo pipefail

TOOLS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$TOOLS/.." && pwd)"
PM="$REPO/packaging/portmaster"
OUT="$REPO/build/portmaster"
STAGE="$OUT/stage"

rm -rf "$OUT"
mkdir -p "$STAGE/xpeedy/gamedata" "$STAGE/xpeedy/licenses"

"$TOOLS/godot.sh" --headless --import >/dev/null 2>&1 || true
"$TOOLS/godot.sh" --headless --export-pack "PortMaster" build/portmaster/xpeedy.pck

cp "$OUT/xpeedy.pck" "$STAGE/xpeedy/gamedata/"
cp "$PM/Xpeedy.sh" "$STAGE/"
cp "$PM/cover.png" "$STAGE/xpeedy/"
cp "$REPO/LICENSE" "$STAGE/xpeedy/licenses/LICENSE.xpeedy.txt"
cp "$REPO/assets/fonts/OFL.txt" "$STAGE/xpeedy/licenses/LICENSE.orbitron.txt"

(cd "$STAGE" && zip -qr "$OUT/xpeedy.zip" Xpeedy.sh xpeedy)

SUB="$OUT/submission"
mkdir -p "$SUB"
cp -r "$STAGE/Xpeedy.sh" "$STAGE/xpeedy" "$SUB/"
cp "$PM/port.json" "$PM/gameinfo.xml" "$PM/README.md" "$PM/cover.png" "$PM/screenshot.png" "$SUB/"

echo "Built $OUT/xpeedy.zip and $SUB"
