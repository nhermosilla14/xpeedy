# 0007. Warning trails

- Status: In progress
- Date: 2026-11-06
- Owner: agent, Nicolás Hermosilla P. (device smoke test)
- Intents: 0003
- ADRs: 0009
- Depends on: slice 0006

## Scope
Every obstacle paints its coloured warning trail on the track: fade-in over the approach, the red-orange
proximity highlight near the ship's lane, and the opposite-lane trail for tube beams.

## Layers touched
- Model: `TrailMap` ring buffer (row clearing on entering the window, writes when a pattern enters the
  horizon, nearest obstacle wins), `TrailMath` reference formulas.
- View: `TrailTexture` (ImageTexture updates when dirty), `tunnel.gdshader` reads the texel per tile
  and applies the fade, highlight and tube-ness weight, uniforms for ship segment and lane.

## End-to-end test
- Unit tests: `TrailMath` returns the doc 04 values (invisible beyond 25, 0 at 25, 1 at 15, highlight
  0 at 15 and 1 at 5, √(1.5 − d), none beyond 1.5 lanes, wrapped distance when the seam is open);
  `TrailMap` writes 25 tiles before an obstacle, a beam in a tube also writes the opposite lane,
  overlaps keep the nearer obstacle, rows are cleared when reused, a removed obstacle clears its trail.
- Desktop visual check: trails appear 25 segments ahead, fade in, turn red-orange as the ship
  approaches in the same lane, and tube beams mark two lanes.
- Device smoke test (recommended before slice 0008): confirm the tunnel and trails render on the RG351P
  and the frame rate holds. If vertex texture fetch fails, apply the RGBA8 fallback from ADR 0009.

## Out of scope
- Spot painting (slice 0008), blackout and phase shift trail variants (later targets).

## Results so far (2026-11-06)
- 83 unit tests and 4 end-to-end tests pass: the doc 04 numbers for fade, highlight and lateral falloff;
  trail extent, opposite-lane trails for tube beams only, nearest-obstacle ownership in either order,
  row reuse and clearing, writes behind or too far ahead ignored, removal re-exposing the farther
  trail; through the real scene, the uploaded texture equals the model's map and the shader's ship
  uniforms equal the model every tick.
- Desktop visual check (real GPU, vertex texture fetch of an RGBAF texture): coloured stripes appear on
  the lanes ahead of obstacles, fade in, and turn red-orange when the ship is in the lane close to the
  obstacle.
- CPU per tick: views 0.12–0.14 ms (unchanged). Desktop at 480×320 with `opengl3_es`: 98–114 fps
  average, 51–71 fps 1 % low.
- Pending: the device smoke test on the RG351P (tunnel and trails render; frame rate holds). If vertex
  texture fetch fails, apply the RGBA8 fallback from ADR 0009.

## RG351P smoke test (2026-11-06) and the fix
- Device: RG351P, AmberELEC, PortMaster 2026.06.23, ~120 s run. The user found the tunnel and trails
  render fine, with some stutter at the start.
- `log.txt`: 57.6 fps average / 48.0 fps 1 % low in the first 10 s window, then a locked 60.0 / 60.0 for
  the rest of the run. But the log also had 1,269 `RGBA32 float texture not supported, converting to
  RGBA16` errors: the Mali-G31 build of Godot cannot use float textures, so every upload converted to
  half-float. That costs CPU per upload (the likely cause of the early stutter) and half-floats lose
  whole numbers above 2048, so trail timing would have drifted after ~2.5 minutes.
- Fix (ADR 0011, replacing 0009): the trail texture is RGBA8; each tile stores the obstacle's distance
  from the tile (0–25) instead of an absolute segment. Regression tests cover trails at segments 2047,
  2049, 4097, 100000 and 16777000, and the byte layout. Desktop visual check repeated: same result, no
  errors in the log.
- Pending: a second device run to confirm the early stutter is gone and the log has no float-texture
  errors.
