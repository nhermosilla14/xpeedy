#!/usr/bin/env bash
# Exports a release build for the given preset (default: Linux) into build/.
set -euo pipefail

TOOLS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRESET="${1:-Linux}"

mkdir -p "$TOOLS/../build/linux"
"$TOOLS/godot.sh" --headless --import >/dev/null 2>&1 || true
"$TOOLS/godot.sh" --headless --export-release "$PRESET"
