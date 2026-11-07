# 0027. Firing, Quake and Space Fold

- Status: Done
- Date: 2026-11-07
- Owner: agent
- Intents: 0007
- ADRs: 0022
- Depends on: slice 0026

## Scope
The `fire` action (keyboard, gamepad, tap outside the pause button), `SurvivalRun.fire`, Quake (destroy the
horizon, up to 8 explosions, warm flash) and Space Fold (used up).

## Layers touched
- Model: `SurvivalRun`, `RunEvent`. View/app: `Hud` tap, `main.gd`, input map.

## End-to-end test
- Unit tests: firing with nothing does nothing; Quake destroys every obstacle in the horizon with no score and
  no shield cost, clears their trails, spares later ones, reports at most 8 nearest; Space Fold empties the
  hand; firing empties the hand.
- Scene test: pick up, fire through the input action, the obstacles ahead vanish and the flash plays.

## Out of scope
- Time Dilation (slice 0028).
