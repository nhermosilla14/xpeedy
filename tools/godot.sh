#!/usr/bin/env bash
# Runs Godot 4.4.1 (with export templates) from a container, with the repo mounted at /src.
set -euo pipefail

IMAGE="${GODOT_IMAGE:-docker.io/barichello/godot-ci:4.4.1}"
# Hard limit in seconds, so a script that never quits can't hang the caller.
TIMEOUT="${GODOT_TIMEOUT:-300}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

exec podman run --rm --timeout "$TIMEOUT" -v "$REPO_ROOT":/src:Z -w /src "$IMAGE" godot "$@"
