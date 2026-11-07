# 0031. Gravity Well

- Status: Accepted
- Date: 2026-11-07
- Owner: agent
- Intents: 0008
- ADRs: 0023
- Depends on: slice 0030

## Scope
The force formula and its fade, adding it to the steering, the camera yaw, field of view, shake and the fog pulse.

## Layers touched
- Model: `SurvivalRun`. View: `ShipCamera`, `main.gd`.

## End-to-end test
- Unit tests: `g(t)` against the formula, the phases come from the seed, the fade over the last second, a run
  without steering drifts during the zone and not before or after, the camera values at known `g`.

## Out of scope
- Aspect wobble.
