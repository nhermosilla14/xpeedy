# 0024. Drawing rollers and bouncers

- Status: Done
- Date: 2026-11-07
- Owner: agent, Nicolás Hermosilla P. (look review)
- Intents: 0006
- ADRs: 0021
- Depends on: slice 0023

## Scope
Two more instanced meshes, the instance code, the shader motion with `game_time` and `target_tps`, the camera
shake on a stomp, and the explosion position of a smashed moving obstacle.

## Layers touched
- View: `obstacle.gdshader`, `ObstacleView`, `ShipCamera`, `main.gd`.

## End-to-end test
- Unit tests: instance data of moving kinds (code, phase, hidden flag); the shader compiles (the test
  runner fails on shader errors); the shake is bounded and ends.
- On a real GPU: screenshots at several times of a roller mid-step and a bouncer high and low, and a
  `--difficulty` run through them; no pixel check, the user reviews them.

## Out of scope
- New colours or edge styles; sound.

## Results
- Captures `build/look/r-*.png` (rollers mid-step on a flat part) and `b-*.png` (bouncers in a tube). The
  roller tips about its edge and lands square. The shader reserves `flat` as a keyword, so the variable is
  named `is_flat`.
