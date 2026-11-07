# 0032. Plasma Cloud

- Status: Done
- Date: 2026-11-07
- Owner: agent, Nicolás Hermosilla P. (look review)
- Intents: 0008
- ADRs: 0023
- Depends on: slice 0031

## Scope
Vortex placement, the maximum alive by speed, touching (shield, held bonus, no crash), clearing at the end,
the vortex tile, the pale blue glow and the light camera shake.

## Layers touched
- Model: `SurvivalRun`, `TrailMap`. View: shader vortex tile, glow overlay, `ShipCamera`.

## End-to-end test
- Unit tests: spacing 5–9, the alive limits per target speed, determinism, a touch costs a shield and clears
  the hand and never crashes, none are placed outside the zone, all vanish at its end.
- Scene test: a vortex touched in the real scene shows the pale blue flash.

## Out of scope
- Particle fountains.
