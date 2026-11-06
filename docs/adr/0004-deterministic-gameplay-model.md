# 0004. Deterministic, fixed-step gameplay model

- Status: Proposed
- Date: 2026-11-05
- Deciders: Nicolás Hermosilla P., agent
- Intent: 0001

## Context
The reference (doc 17) points out frame-rate dependencies in the original, and says seeded runs need a
portable generator with a fixed order of random draws. Godot's built-in RNG isn't guaranteed to give
the same sequence across engine versions. Gameplay rules should also be testable without rendering.

## Decision
- **Model/view split**: track, path, shape and ship state live in plain GDScript classes
  (`RefCounted`) with no scene dependencies. Nodes only read the model to draw it.
- **Fixed timestep**: game logic runs in `_physics_process` at 60 Hz on a game clock that is capped
  at 200 ms per frame and can be scaled (for Time Dilation later).
- **Own PRNG**: a PCG32 generator implemented in GDScript. Gameplay generation uses one instance
  with a fixed draw order. Decoration (shake, particles) uses a separate instance.
- Headless unit tests exercise the model with Godot's `--headless` mode.

## Alternatives considered
- Godot `RandomNumberGenerator` — not guaranteed stable across versions.
- Logic in `_process` with variable delta — reproduces the original's frame-rate quirks.

## Consequences
- Seeded runs are reproducible across platforms, which enables ghost challenges later.
- A bit more code up front (PRNG, clock).
