# 0007. Tunnel geometry evaluated on the GPU

- Status: Proposed
- Date: 2026-11-06
- Deciders: Nicolás Hermosilla P., agent
- Intent: 0002

## Context
The tunnel view rebuilds a 3,200-vertex `ArrayMesh` in GDScript every time the ship crosses a
segment (about 12 times per second) and every tick during the 2.4 s of a morph. On the desktop that's
about 2.2 ms per tick while morphing; on the RK3326 it overruns the 16.7 ms frame budget, which shows as
1 % lows of 27–34 fps and hitches on shape changes (slice 0004 results).

The geometry only depends on two small inputs: one frame (position, right, up) per visible segment,
and the 17-point cross-section that the face chain (ADR 0006) produces for the current turn angle.

## Decision
- Build the tunnel mesh **once**: 50 segments × 16 lanes of tiles (separate vertices per tile, as now).
  Each vertex stores only its lane vertex index (0–16) and its segment offset in the window (0–50).
- A spatial **vertex shader** computes the world position:
  `frame_pos[i] + frame_right[i] · section[k].x + frame_up[i] · section[k].y`.
- The CPU passes, as shader uniforms:
  - per segment change: the 51 visible frames (`vec3` arrays) and the checker parity of the window's
    first segment;
  - per tick, only while the turn angle changes: the 17 cross-section points (`vec2` array).
- The cross-section keeps being computed by `TunnelGeometry` in GDScript, so gameplay (camera,
  seam rules, tests) and drawing share one source of truth.
- The shader stays unshaded with vertex-colour checker tiles and keeps the built-in fog. The mesh gets
  a large custom AABB so Godot never frustum-culls it by its untransformed bounds.

## Alternatives considered
- Cross-section in closed form in the shader — duplicates ADR 0006's maths in two languages.
- Data texture for frames — more moving parts than uniform arrays for 153 vectors.
- Optimising the GDScript rebuild (packed arrays, partial updates) — still O(mesh) work on the CPU
  per segment and per morph tick; it only shrinks the problem.
- GDExtension in native code — rejected by ADR 0003.

## Consequences
- Per-segment CPU work drops from rebuilding and uploading a mesh to uploading ~160 vectors; morph ticks
  upload 17 points.
- Uniform array limits: 153 `vec3` + 17 `vec2` fit within the GLES 3 vertex uniform budget of the
  Mali-G31; to be verified on the device in slice 0005.
- Tests that inspect the mesh must read the shader inputs instead of vertex positions.
