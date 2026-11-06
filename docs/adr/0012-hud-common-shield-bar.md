# 0012. HUD with a common shield bar, flashes and explosions

- Replaces: 0010-hud-flashes-explosions
- Status: Accepted
- Date: 2026-11-06
- Deciders: Nicolás Hermosilla P., agent
- Intent: 0003

## Context
ADR 0010 drew the shields as one slot per possible unit, each filled slot showing the decay level. With
a single decay timer for the whole stack, every filled slot drained at the same time, so the HUD read as
four separate shields with four timers. The user sketched what is wanted: one frame split into four
compartments, filled from the left, whose fill shrinks from the right at one compartment per 20 s (the
sketch shows the last compartment half drained after 10 s and gone after 20 s). The rules for picking
up and spending shields (doc 05, ADR 0008) are unchanged.

## Decision
Everything in ADR 0010 stands, restated here, except the shield display.

- **Events, not polling**: views react to the `RunEvent`s that `SurvivalRun` emits each tick
  (ADR 0008). Nothing in this layer writes back to the model.
- **Shield bar**: `ShieldStack.level()` gives the bar's charge in segments, 0 to the maximum:
  `count − 1 + time_left / decay` while there are shields, else 0. It falls continuously at 1 segment per
  decay period, including across the moment a unit expires. The HUD draws one frame with `max` equal
  compartments separated by thin dividers, and one fill from the left of width `level / max`. A pick-up
  makes the bar jump up by the units it adds; units lost to a smash make the bar fall, and the lost part
  fades out over 250 ms (slice 0009).
- **Score** is a `Label` bottom left; both are sized by screen height / 320. Default font; a themed
  font is out of scope.
- **Flashes**: one full-screen `ColorRect` per blend mode in the `CanvasLayer`, driven by `ScreenFlash`
  with the doc 15 colours and durations: shield pick-up (1.0, 0.7, 0.2) at 75 % for 300 ms additive;
  smash (1.0, 0.5, 0.5) at 75 % for 300 ms additive; crash white for 1000 ms additive. A new flash
  replaces the current one.
- **Explosions**: a pool of 96 small fragments in one `MultiMeshInstance3D` with a shader
  (`fragments.gdshader`). A smash writes ~12 instances: origin in the instance transform and (spawn
  time, colour, seed) in custom data. The vertex shader derives direction, spin and speed from the
  seed, moves the fragment ballistically for 0.8 s of game time, shrinks it to nothing and hides it.
  The CPU only writes on smash events.
- **Timebase**: shader effects use a `game_time` uniform from the run clock.
- Sound and vibration are out of scope for this target.

## Alternatives considered
- Keep separate slots but fill only the draining one — still reads as separate pieces.
- A continuous model for shields (pick-ups adding exactly one segment without restarting the timer) —
  a rules change the user did not ask for; the doc 05 rules stay.
- `GPUParticles3D` / `CPUParticles3D` for explosions — extra node types and renderer-specific
  behaviour on the Compatibility path.

## Consequences
- The HUD matches the user's sketch, and one number (`level()`) drives it.
- Pick-up behaviour can still be changed later in `ShieldStack` without touching the HUD.
