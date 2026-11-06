# 0009. Smashing obstacles

- Status: Accepted
- Date: 2026-11-06
- Owner: agent
- Intents: 0003
- ADRs: 0008, 0010
- Depends on: slice 0008

## Scope
Shields now smash obstacles: cubes cost 1 shield and give +100, beams cost 2 and give +300 (with one
shield a beam is still a crash), several smashes can happen in one tick. A smash plays the explosion
of fragments and the pink-white flash, and a crash plays the white flash.

## Layers touched
- Model: smash resolution in segment order with shield costs and points, `RunEvent`s for smashes,
  obstacle removal (its trail is cleared).
- View: `ExplosionView` (fragment pool, `fragments.gdshader`, `game_time` uniform), `ScreenFlash`
  colours for smash and crash, obstacle instances hidden on smash.

## End-to-end test
- Unit tests: cube with 1 shield is smashed (−1 shield, +100); beam with 2 is smashed (−2, +300); beam
  with 1 crashes and keeps its shield; cube with 0 crashes; two obstacles in one tick with enough
  shields are both smashed, with one shield the second one crashes; a smash restarts the decay timer;
  score never goes below 0.
- Scene test: with shields granted, flying through a cube leaves the run alive with the score up and
  the obstacle's instance and trail gone; without shields it crashes.
- Desktop visual check: fragments in the obstacle's colour fly out and disappear, flashes show.

## Out of scope
- Spikes and the other patterns (slice 0010), sound, vibration, keep going.
