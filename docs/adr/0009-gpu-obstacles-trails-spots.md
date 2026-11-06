# 0009. Obstacles, trails and spots drawn on the GPU

- Status: Accepted
- Date: 2026-11-06
- Deciders: Nicolás Hermosilla P., agent
- Intent: 0003

## Context
Intent 0003 must draw up to ~100 obstacles, their warning trails and the shield spots without losing
the locked 60 fps on the RG351P that ADR 0007 achieved. Placing each obstacle from GDScript every tick
(they all move relative to the camera, and during a morph they all move on the surface) would bring
back CPU costs of the order that ADR 0007 removed. Trails alter the colour of up to ~800 tunnel tiles
with distance-dependent fades.

## Decision

### Shared track data
- A `TrackShaderBinding` helper owns the uniform upload (51 frames, 17-point cross-section, 16 face
  normals, first segment, ship segment, ship lane position, tube-ness) and applies it to every
  `ShaderMaterial` that needs it (tunnel, the three obstacle materials). Global shader uniforms are
  not used because they do not support arrays.

### Obstacles
- Three `MultiMeshInstance3D` nodes (cube, beam, spike) share one shader, `obstacle.gdshader`.
- Each mesh vertex stores tile-local coordinates (u across the lane, v along the segment, h height in
  lane widths) and a fixed face brightness. Cube: h = 1. Beam: h = 1.96 / lane width ≈ 5.02. Spike: a
  pyramid with its apex at (0.5, 0.5, 1.25).
- Per instance, `INSTANCE_CUSTOM` carries (lane, absolute segment, colour index, alive flag). The
  vertex shader computes the base point from the frames and cross-section as the tunnel shader does,
  then adds `face_normal · h · lane width`. Instance transforms stay identity.
- Obstacles outside the window (relative segment < 0 or > 49) or dead collapse to a point, so they
  draw nothing. The instance buffer is rewritten only when the set of obstacles changes (a pattern
  enters the horizon, an obstacle is removed), with active instances first and
  `visible_instance_count` set to the active count. A large custom AABB prevents culling.
- Unshaded, flat colours from the palette (doc 15: amber, green, lime, teal, mauve) times the face
  brightness; built-in fog applies.

### Trails and spots
- A `TrailMap` (model layer) holds a ring buffer of 64 rows (segment & 63) × 16 lanes of RGBAF texels:
  R = palette colour index or −1 for none, G = absolute segment of the obstacle the trail leads to,
  B = 1 if the texel is an opposite-lane beam trail, A = 1 if the tile is part of a shield spot.
- Writing happens only when something changes: when a pattern enters the horizon its trails (25
  segments before each obstacle, nearest obstacle wins on overlap) and spots are written once; a
  row is cleared when its segment enters the window; smashed obstacles and collected spots clear
  their texels. An `ImageTexture` is updated only when the map is dirty.
- The tunnel vertex shader fetches the tile's texel with `texelFetch` and computes the doc 04
  colour: nothing beyond 25 segments ahead; linear fade from track colour to obstacle colour over the
  next 10 segments of approach (a function of the obstacle's distance to the ship, so the whole trail
  fades together); within 15 segments, a red-orange shift growing from 0 at 15 to 1 at 5 segments,
  times √(1.5 − d) with d the ship's lateral distance in lanes (wrapped when the seam is open).
  Opposite-lane texels are weighted by tube-ness. Spots paint the tile orange.
- The same formulas exist in GDScript (`TrailMath`) and are unit-tested against the doc's numbers.
  The shader copies them; visual desktop checks and the RG351P run verify the match, since headless
  runs use a dummy renderer that never compiles shaders.
- Texel format: `Image.FORMAT_RGBAF`. If the Mali-G31 or the PortMaster build cannot fetch it in a vertex shader,
  the fallback is RGBA8 with the segment encoded in two channels.

## Alternatives considered
- CPU-placed `Node3D` meshes per obstacle — per-tick transforms for every obstacle, plus scene-tree
  cost.
- Painting trails into the tunnel mesh's vertex colours from GDScript — a per-segment rebuild of up to
  ~800 tiles, the cost ADR 0007 removed.
- Uniform arrays for trails instead of a texture — a gather per tile cannot be done with arrays.
- Decals or projected textures — not supported well in the Compatibility renderer.

## Consequences
- Per-tick CPU cost stays small: uniform updates and rare buffer writes.
- Shader and GDScript hold the same formulas twice; tests cover only the GDScript side.
- Risk: vertex texture fetch and RGBAF on the RG351P. Check on the device after slice 0007.
