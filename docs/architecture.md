# Architecture

> Status: slices 0001–0007 implemented (0007 awaits its device smoke test): curving tunnel with in/flat/out shapes and morphs, steering,
> wall crashes and restart, speed ramp, PortMaster package.

## Engine and runtime
- Godot 4.4.1, Compatibility (OpenGL ES 3 / OpenGL 3.3) renderer, GDScript only (ADR 0002, 0003).
- One Godot project at the repository root, exported to desktop, Android and a PortMaster `.pck`.
- Development uses Godot from a container image; see `README.md`.

## Components

```
   keys / gamepad ──► input map (steer_left / steer_right)
                          │  Input.get_axis
                          ▼
                 ┌─────────────────┐
                 │  Steering       │  response curve |x|^0.66, invert  (src/core)
                 └────────┬────────┘
                          ▼
┌──────────┐     ┌─────────────────┐     ┌──────────────────┐
│ XRandom  │────►│  TrackModel     │◄────│  RunClock         │ 200 ms cap, scale
│(xoshiro) │     │  segment, p,    │     └──────────────────┘
└──────────┘     │  speed ramp     │  (src/model)
   seed          │  ├ PartSequence │  in / flat / out parts (own stream: seed ^ 0x5EED0001)
                 │  ├ PathModel    │  centre line: one frame (pos, fwd, up) per segment (stream: seed)
                 │  └ TunnelGeometry│ (segment, lane position) → world, via the face chain
                 └────────┬────────┘
                          ▼ read-only
          ┌───────────────┴───────────────┐
          ▼                               ▼
 ┌─────────────────┐             ┌─────────────────┐
 │  TunnelView     │             │  ShipCamera     │  (src/view)
 │  static mesh +  │             │  eye, look-ahead│
 │  vertex shader  │             │                 │
 └─────────────────┘             │  fog env        │
                                 └─────────────────┘
```

| Path | Role |
|---|---|
| `src/main.tscn`, `src/main.gd` | Entry scene; steps the model in `_physics_process` (60 Hz) and refreshes views |
| `src/core/` | Engine-agnostic helpers: `XRandom`, `RunClock`, `Steering` |
| `src/model/` | Gameplay state (`TrackModel`), parts (`PartSequence`), centre line (`PathModel`), track-to-world mapping (`TunnelGeometry`), the Survival run (`SurvivalRun`, `RunConfig`, `RunEvent`) and obstacles (`Obstacle`, `ObstacleField`, `PatternLibrary`), warning trails (`TrailMap`, `TrailMath`) |
| `src/view/` | Nodes that draw the model: `TunnelView`, `ObstacleView`, `ShipCamera`; `TrackShaderBinding` uploads the data they share; `TrailTexture` uploads the trail map; `Palette` holds the obstacle colours |
| `tests/` | Unit tests (`tests/unit/`) and end-to-end scene scripts (`tests/e2e_*.gd`) |
| `tools/` | Container wrapper, test, export and packaging scripts |
| `packaging/portmaster/` | PortMaster port: launch script (Godot 4.4.1 runtime under Weston), metadata, gptk |

## Key rules
- **Model / view split**: the model never touches nodes; views only read it (ADR 0004).
- **Fixed timestep**: game logic advances only in `_physics_process` at 60 Hz through `RunClock`.
- **Deterministic randomness** (ADR 0005): each gameplay subsystem owns an xoshiro128** stream
  derived from the run seed, so request order never changes the track. Decoration (camera shake)
  uses its own stream.

  | Subsystem | Seed | Draw order |
  |---|---|---|
  | PathModel | `seed` | per control point: spacing, straight chance, then per attempt: limit, yaw, pitch |
  | PartSequence | `seed ^ 0x5EED0001` | after in: 50 % extend draws until one fails; after flat: tube choice |
  | ShipCamera shake | `0xDEC0` | one draw per axis per tick while morphing |
- **Coordinates**: lane position grows to the left; positive steer moves right (to lower lanes).
  The path starts at the origin heading −Z with +Y up; one segment = 2·sin(π/16) units.
- **Path**: control points 10–20 segments apart joined by cubic Hermite pieces, resampled at equal arc
  length into one frame per segment. "Up" is parallel-transported (minimal rotation, no twist).
  Frames are generated lazily on request and dropped once behind the ship. The bend limit at each
  control point comes from the part there (30° flat, 50° tube).
- **Shapes** (ADR 0006): the cross-section is a chain of 16 faces anchored at lane vertex 8 below the
  centre line, each turned by τ from its neighbour (+22.5° in, 0 flat, −22.5° out). The whole
  visible tunnel shares one τ; during the 30-segment transition after a part boundary,
  τ = lerp(τ_old, τ_new, progress) by the ship's progress. Seam crossing, banking and shake use the
  same progress. Crossing the seam where it isn't allowed sets `crashed`; the run stops and
  "restart" starts a new one.
- **Survival run** (ADR 0008): `SurvivalRun` owns the `TrackModel`, a `RunConfig` and an `ObstacleField`.
  Each tick: track step, generate obstacles up to the horizon (`window_start + 50`), resolve collisions
  over the swept segment and lane range, forget obstacles behind. Obstacles are `(segment, lane, kind,
  colour)` on one tile and are generated only as the horizon advances, from the stream
  `seed ^ 0x0B57AC1E`. Patterns are placed at 55, then every `max(8, 12 − ⌊d/300⌋)` segments; only the
  level-0 pattern (one cube or beam: kind, lane, colour draws) exists so far. A tube beam (shape IN)
  also hits lane + 8 while `flatness ≤ 0.2`; seam wrap applies on tube parts when not morphing.
  `RunConfig.collisions_enabled` is off with `-- --ghost` for visual debugging.
- **Warning trails** (ADR 0009): `SurvivalRun.trails` is a `TrailMap`, a ring buffer of 64 segment
  rows × 16 lanes of RGBA float texels (R colour index or −1, G obstacle segment, B opposite-lane flag,
  A spot flag; row `seg & 63`). Every obstacle added to the field paints the 25 tiles before it
  (nearest obstacle ahead wins; a tube beam also paints lane + 8 with B = 1). A row is cleared when a
  different segment claims it, either on a write or when the window advances, so scrolling rewrites
  nothing. `TrailTexture` uploads the map as a 16 × 64 `FORMAT_RGBAF` texture only when its version
  changes. `tunnel.gdshader` fetches the tile's texel per vertex and applies the fade (invisible at 25
  segments, full at 15), the red-orange highlight (0 at 15, full at 5, × √(1.5 − lateral lanes), the
  lateral distance wrapping when the seam is open) and the tube-ness weight for opposite-lane trails,
  from per-tick uniforms (`ship_segment`, `ship_lane`, `wrap_seam`, `tube_weight`). `TrailMath` holds
  the same formulas in GDScript for the tests.
- **Obstacle drawing** (ADR 0009): `ObstacleView` has three `MultiMeshInstance3D`s (cube, beam, spike)
  sharing `obstacle.gdshader`. Mesh vertices are tile-local `(u, v, height)`; per instance custom data
  is `(lane, absolute segment, colour, alive)`. The shader positions each vertex from the same frames
  and cross-section as the tunnel and lifts it along the face normal. The buffers are rewritten only
  when `ObstacleField.version` changes. Face brightness is in UV.x, because instancing overrides the
  vertex colour. `TrackShaderBinding` uploads frames, cross-section and face normals to every
  registered material.
- **Tunnel drawing** (ADR 0007): `TunnelView` builds a static 50×16-tile mesh once. Each vertex stores
  its lane vertex index (x) and segment offset (y); `tunnel.gdshader` computes its position as
  `frame_pos[s] + frame_right[s]·section[k].x + frame_up[s]·section[k].y`. The view uploads the 51
  visible frames when the ship enters a new segment (≈ 12 times per second), and the 17-point
  cross-section (`TunnelGeometry.section()`) only when the turn angle changes. Checker parity is
  computed in the shader from the first visible segment's parity. The mesh has a custom AABB around
  the first visible segment so it is never culled by its untransformed bounds. Headless runs use a
  dummy renderer, so shaders are only verified on a real GPU.
- The root node runs with process mode Always (works around the Godot 4.3+ idle bug on handhelds),
  and stdout is flushed on every print so `[bench]` lines survive the port being killed.
- Handheld input: gptokeyb maps D-pad/left stick to arrow keys; Godot's native gamepad input stays on
  (both drive the same actions, so a double input just saturates the axis).
