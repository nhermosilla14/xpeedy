# 0003. Curving path

- Status: Done
- Date: 2026-11-05
- Owner: agent
- Intents: 0001
- ADRs: 0004
- Depends on: slice 0001

## Scope
The tube's centre line curves following doc 02, the camera follows the curve without twisting, and
seeded runs produce the same path.

## Layers touched
- Model: `PathModel` (control points, smooth cubic with continuous direction, constant speed per
  segment, turn acceptance rules, minimal-rotation "up" frame), driven by the gameplay PCG32.
- View: tunnel mesh and camera use the path frames.

## End-to-end test
- Headless tests: first ~30 segments straight; control-point spacing within 10–20; every accepted turn is
  between 10° and the tube limit (50°); after 6 rejections the path continues straight; two
  generations with the same seed match exactly; frame "up" has no roll drift (twist ≈ 0).
- Running the project: the tunnel visibly curves and the view stays steady.

## Out of scope
- Flat/out shapes and their 30° limit (slice 0004).
