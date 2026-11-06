#!/usr/bin/env bash
# Imports the project, runs the headless unit tests, then every end-to-end script in tests/e2e_*.gd.
# Exit code is non-zero on any failure.
set -euo pipefail

TOOLS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$TOOLS/.."

"$TOOLS/godot.sh" --headless --import >/dev/null 2>&1 || true
"$TOOLS/godot.sh" --headless --script res://tests/run_tests.gd

for e2e in "$REPO"/tests/e2e_*.gd; do
	"$TOOLS/godot.sh" --headless --script "res://tests/$(basename "$e2e")"
done
