# 0007. Warning trails

- Status: Proposed
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
