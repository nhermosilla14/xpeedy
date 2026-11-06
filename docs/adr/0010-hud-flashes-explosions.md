# 0010. HUD, flashes and explosions

- Status: Proposed
- Date: 2026-11-06
- Deciders: Nicolás Hermosilla P., agent
- Intent: 0003

## Context
Intent 0003 asks for a score and shield display, full-screen flashes (doc 15) and an explosion of
fragments when an obstacle is smashed. All of it must be cheap on the RK3326 and must not influence
gameplay.

## Decision
- **Events, not polling**: views react to the `RunEvent`s that `SurvivalRun` emits each tick
  (ADR 0008). Nothing in this layer writes back to the model.
- **HUD**: one `Control` (`Hud`) in the existing `CanvasLayer`. The score is a `Label` bottom left. The
  shield slots are drawn with `_draw()` bottom right: one slot per possible unit, the filled slots show
  the remaining decay time as a fill level, and a lost unit animates (scale up and fade, 250 ms). Default
  font; a themed font is out of scope.
- **Flashes**: one full-screen `ColorRect` per blend mode (additive and mix) in the `CanvasLayer`,
  driven by a small `ScreenFlash` helper with the doc 15 colours and durations: shield pick-up (1.0,
  0.7, 0.2) at 75 % for 300 ms additive; smash (1.0, 0.5, 0.5) at 75 % for 300 ms additive; crash white
  for 1000 ms additive. A new flash replaces the current one.
- **Explosions**: a pool of 96 small fragments in one `MultiMeshInstance3D` with a shader
  (`fragments.gdshader`). A smash writes ~12 instances: origin in the instance transform, and
  (spawn time, colour, seed) in custom data. The vertex shader derives each fragment's direction,
  spin and speed from the seed, moves it ballistically for 0.8 s of game time, shrinks it to nothing
  and hides it afterwards. The CPU only writes on smash events. Particles beyond this pool are out
  of scope.
- **Timebase**: shader effects use a `game_time` uniform from the run clock, so they respect the clock
  scale and stop when the clock stops.
- Sound and vibration are out of scope for this target.

## Alternatives considered
- `GPUParticles3D` / `CPUParticles3D` — extra node types and renderer-specific behaviour on the
  Compatibility path; the pooled shader is simpler and its cost fixed.
- Per-fragment `Node3D` meshes — scene-tree churn on every smash.
- Polling model state each frame in views — hides what caused a change and risks double triggers.

## Consequences
- Adding feedback for a new event (bonuses, zones) means handling one more `RunEvent` kind.
- Explosion visuals are basic; polishing them (particles, sound) can come later without touching rules.
