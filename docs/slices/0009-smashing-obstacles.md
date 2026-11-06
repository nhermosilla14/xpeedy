# 0009. Smashing obstacles

- Status: Done
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

## Results (2026-11-06)
- 133 unit tests and 6 end-to-end tests pass. New unit tests: costs and points per kind; a cube or spike
  smashed with one shield (−1, +100); a beam with two (−2, +300) and on its opposite lane in a tube; a
  beam with one shield is a crash that keeps the shield; any obstacle with no shields is a crash;
  several smashes in one tick; with one shield the second obstacle crashes; segment order; the decay
  timer restarts on a smash; the smashed obstacle loses its trail and the farther trail shows again; the
  obstacle version changes; events for smashes and for a single wall crash; the score never decreases;
  the autopilot's choices.
- `tests/e2e_smashing.gd`, through the real scene: with two shields flying into a cube leaves the run
  alive with one shield and +100, the cube's instance and trail are gone, the texture is up to date, an
  explosion starts at the cube in its colour, the pink flash shows and the HUD bar animates the loss;
  without shields the same cube crashes with the white flash.
- Desktop visual check (real GPU, 480×320, `-- --shields=4 --autopilot=plough --timescale=0.2`): the
  pink-white flash, tumbling fragments in the obstacle's colour and the faded lost compartment were
  captured mid-smash. The fragments were large because the ship is on top of them, so their size was
  reduced from 0.16 to 0.1.
- Desktop, 480×320 with `opengl3_es`, autopilot smashing: 113–118 fps average, 65–96 fps 1 % low.
- Found by the scene test, fixed in the test: a teleport must be followed by a step before obstacles are
  added (the trail ring rejects tiles beyond its window), and path frames behind the ship are gone.
- Debug launch options added: `--autopilot=plough` and `--timescale=N` (documented in the README).
