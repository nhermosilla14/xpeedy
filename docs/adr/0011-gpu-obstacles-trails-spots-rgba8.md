# 0011. Obstacles, trails and spots on the GPU, with an RGBA8 trail texture

- Replaces: 0009-gpu-obstacles-trails-spots
- Status: Accepted
- Date: 2026-11-06
- Deciders: Nicolás Hermosilla P., agent
- Intent: 0003

## Context
ADR 0009 chose a `FORMAT_RGBAF` data texture for the warning trails and spots, and named an RGBA8
fallback in case the handheld could not use it. The RG351P run of slice 0007 (AmberELEC, Mali-G31,
Godot 4.4.1 under Weston) showed that it cannot: the log has `RGBA32 float texture not supported,
converting to RGBA16` on every texture upload (1,269 times in 100 s). The data still reached the shader
as half-floats, which costs CPU on every upload and cannot hold whole segment numbers above 2048, so
trail timing would have drifted beyond ~2.5 minutes of play. Everything else in ADR 0009 worked on the
device (instanced obstacles, vertex texture fetch, uniform arrays).

## Decision
Everything in ADR 0009 stands, restated here so this record is complete, except the texel format.

### Shared track data
- `TrackShaderBinding` owns the uniform upload (51 frames, 17-point cross-section, 16 face normals,
  first segment, palette, ship segment, ship lane, seam-wrap flag, tube-ness) and applies it to every
  `ShaderMaterial` that needs it. Global shader uniforms are not used because they don't support arrays.

### Obstacles
- Three `MultiMeshInstance3D` nodes (cube, beam, spike) share `obstacle.gdshader`. Mesh vertices store
  tile-local (u, v, height in lane widths); face brightness is in UV.x, because instancing overrides the
  vertex colour. Per instance, `INSTANCE_CUSTOM` carries (lane, absolute segment, colour, alive).
  The vertex shader positions each vertex from the frames and cross-section as the tunnel does and lifts
  it along the face normal. Hidden obstacles collapse to a point. Buffers are rewritten only when the set
  of obstacles changes; a custom AABB prevents culling.

### Trails and spots
- `TrailMap` (model layer) is a ring buffer of 64 segment rows × 16 lanes (row `seg & 63`), uploaded as
  a 16 × 64 **`FORMAT_RGBA8`** texture, four bytes per tile:
  - R = palette colour index + 1, or 0 when the tile has no trail;
  - G = the obstacle's segment minus the tile's segment (0–25), so no absolute segment numbers are
    stored; the shader adds the tile's segment, which it knows from `first_segment` and the tile's
    position in the window;
  - B = 255 for the opposite-lane trail of a tube beam, else 0;
  - A = 255 when the tile is part of a shield spot, else 0. Removing or repainting a trail leaves A alone.
- Writing and clearing rules are as in ADR 0009: trails are written once when an obstacle is added
  (nearest obstacle ahead wins), a row is cleared when a different segment claims it, removal repaints
  the farther trails it was covering, and the texture is uploaded only when the map changes.
- The tunnel vertex shader fetches the tile's texel with `texelFetch` (nearest) and applies the doc 04
  colour: fade over 10 segments from 25 segments ahead, red-orange highlight from 15 to 5 segments ×
  √(1.5 − lateral lanes), opposite-lane trails weighted by tube-ness. The same formulas exist in
  GDScript (`TrailMath`) for the unit tests.

## Alternatives considered
- Keep RGBAF and accept half-float conversion — logs an error per upload, costs CPU, and breaks
  beyond segment 2048.
- Two 8-bit channels for an absolute segment — works, but the relative delta needs one channel and
  keeps the value tiny.
- `RGBAH` — also unsupported or converted on some drivers, and no better than RGBA8 for these values.

## Consequences
- Data textures on the handhelds must be RGBA8; float textures are not usable there (recorded in
  `docs/architecture.md`).
- The shader and `TrailMap` must agree on the byte layout; the scene tests compare the uploaded image
  bytes with the model's map.
