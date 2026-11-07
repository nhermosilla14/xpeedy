#!/usr/bin/env bash
# Captures the tunnel in the inside, flat and outside shapes on a real GPU (needs build/linux from
# tools/export.sh) and checks the pixels. Output: build/look/{in,flat,out}.png
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT/build/look"
for s in in flat out; do
	"$ROOT/build/linux/xpeedy.x86_64" --resolution 960x540 -- --clean --seed=2024 \
		--start-shape=$s --screenshot="$ROOT/build/look/$s.png,3" >/dev/null
done
PYTHONPATH=/usr/lib/python3/dist-packages python3 - "$ROOT/build/look" <<'PY'
import sys
from PIL import Image
d = sys.argv[1]
ok = True
for s in ("in", "flat", "out"):
	im = Image.open(f"{d}/{s}.png").convert("RGB")
	w, h = im.size
	wall = im.getpixel((w // 2, h - 30))
	rails = max(im.getpixel((x, h - 60)) for x in range(0, w, 4))
	centre = im.getpixel((w // 2, h // 2 - 40))
	checks = {
		"wall blue-violet": wall[2] > wall[0] > wall[1],
		"rail bright": min(rails) > 150,
		"centre darker": sum(centre) < sum(wall),
	}
	for k, v in checks.items():
		print(("ok   " if v else "FAIL ") + f"{s}: {k}")
		ok &= v
sys.exit(0 if ok else 1)
PY
