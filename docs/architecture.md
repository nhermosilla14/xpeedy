# Architecture

> Status: slices 0001–0003 implemented: curving inside-shape tunnel, steering, speed ramp, PortMaster
> package. Shapes and morphs arrive with slice 0004.

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
   seed          │  ├ PathModel    │  centre line: one frame (pos, fwd, up) per segment
                 │  └ TunnelGeometry│ (segment, lane position) → world
                 └────────┬────────┘
                          ▼ read-only
          ┌───────────────┴───────────────┐
          ▼                               ▼
 ┌─────────────────┐             ┌─────────────────┐
 │  TunnelView     │             │  ShipCamera     │  (src/view)
 │  50×16 tile mesh│             │  eye, look-ahead│
 └─────────────────┘             │  fog env        │
                                 └─────────────────┘
```

| Path | Role |
|---|---|
| `src/main.tscn`, `src/main.gd` | Entry scene; steps the model in `_physics_process` (60 Hz) and refreshes views |
| `src/core/` | Engine-agnostic helpers: `XRandom`, `RunClock`, `Steering` |
| `src/model/` | Gameplay state (`TrackModel`), centre line (`PathModel`), track-to-world mapping (`TunnelGeometry`) |
| `src/view/` | Nodes that draw the model: `TunnelView`, `ShipCamera` |
| `tests/` | Unit tests (`tests/unit/`) and end-to-end scene scripts (`tests/e2e_*.gd`) |
| `tools/` | Container wrapper, test, export and packaging scripts |
| `packaging/portmaster/` | PortMaster port: launch script (Godot 4.4.1 runtime under Weston), metadata, gptk |

## Key rules
- **Model / view split**: the model never touches nodes; views only read it (ADR 0004).
- **Fixed timestep**: game logic advances only in `_physics_process` at 60 Hz through `RunClock`.
- **Deterministic randomness**: gameplay draws from an own xoshiro128** generator, decoration from a
  separate instance (ADR 0004).
- **Coordinates**: lane position grows to the left; positive steer moves right (to lower lanes).
  The path starts at the origin heading −Z with +Y up; one segment = 2·sin(π/16) units.
- **Path**: control points 10–20 segments apart joined by cubic Hermite pieces, resampled at equal arc
  length into one frame per segment. "Up" is parallel-transported (minimal rotation, no twist).
  Frames are generated lazily on request and dropped once behind the ship. Random draws per control
  point, in order: spacing, straight chance, then per attempt: limit, yaw, pitch.
- The tunnel mesh is rebuilt only when the ship crosses a segment boundary, from one 17-vertex ring
  per segment.
- The root node runs with process mode Always (works around the Godot 4.3+ idle bug on handhelds),
  and stdout is flushed on every print so `[bench]` lines survive the port being killed.
- Handheld input: gptokeyb maps D-pad/left stick to arrow keys; Godot's native gamepad input stays on
  (both drive the same actions, so a double input just saturates the axis).
