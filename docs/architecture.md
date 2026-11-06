# Architecture

> Status: planned. Nothing is implemented yet; this describes the intended shape from the accepted
> or proposed ADRs and will be updated as slices land.

## Engine and runtime
- Godot 4.4.x, Compatibility (OpenGL ES 3 / OpenGL 3.3) renderer, GDScript only (ADR 0002, 0003).
- One Godot project at the repository root, exported to desktop, Android and a PortMaster `.pck`.

## Components (planned)

```
            input devices (keys, gamepad, touch, tilt)
                          │
                          ▼
                 ┌─────────────────┐
                 │  SteerInput     │  any device ─► steer value (doc 03 pipeline)
                 └────────┬────────┘
                          ▼
┌──────────┐     ┌─────────────────┐     ┌──────────────────┐
│ XRandom  │────►│  TrackModel     │◄────│  RunClock         │ fixed 60 Hz game time
│ (PCG32)  │     │  path, parts,   │     └──────────────────┘
└──────────┘     │  morphs, ship   │
                 └────────┬────────┘
                          ▼ (read-only)
                 ┌─────────────────┐
                 │  TunnelView     │  ArrayMesh 51×17 grid, camera, fog
                 └─────────────────┘
```

- **Model / view split**: gameplay state (track, ship position, speed) lives in plain GDScript
  classes that don't depend on scene nodes, so they can be unit-tested headless. Views read it.
- **Fixed timestep**: game logic advances in `_physics_process` at 60 Hz, with the 200 ms frame
  cap from the reference.
- **Deterministic randomness**: gameplay draws from an own PCG32 generator, decoration from a
  separate one (ADR 0004).
