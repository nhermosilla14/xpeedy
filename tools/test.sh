#!/usr/bin/env bash
# Imports the project, runs the headless unit tests, then every end-to-end script in tests/e2e_*.gd.
# Exit code is non-zero on any failure, and also when Godot prints a script or shader error
# (the headless renderer parses shaders, so shader mistakes show up here).
set -uo pipefail

TOOLS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$TOOLS/.."
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT
status=0

run() {
	"$TOOLS/godot.sh" "$@" 2>&1 | tee -a "$LOG"
	[ "${PIPESTATUS[0]}" -eq 0 ] || status=1
}

"$TOOLS/godot.sh" --headless --import >/dev/null 2>&1 || true
run --headless --script res://tests/run_tests.gd
for e2e in "$REPO"/tests/e2e_*.gd; do
	run --headless --script "res://tests/$(basename "$e2e")"
done

if grep -qE '^(SCRIPT ERROR|SHADER ERROR|ERROR:)' "$LOG"; then
	echo "FAILED: Godot reported script or shader errors:" >&2
	grep -E -A2 '^(SCRIPT ERROR|SHADER ERROR|ERROR:)' "$LOG" >&2
	status=1
fi
exit $status
