# 0026. Bonus spots and the held bonus

- Status: In progress
- Date: 2026-11-07
- Owner: agent, Nicolás Hermosilla P. (look review)
- Intents: 0007
- ADRs: 0022
- Depends on: slice 0025

## Scope
Spot kinds and their generation rules, the texture encoding and the coloured dotted spots, picking up and
holding one bonus, the pickup flash, the HUD ring, difficulty flags.

## Layers touched
- Model: `Spot`, `SpotField`, `TrailMap`, `SurvivalRun` (held bonus, pickup events), `RunConfig`, `Difficulty`.
- View: `tunnel.gdshader` (spot colours), `Hud` (ring), `main.gd` (flash).

## End-to-end test
- Unit tests: chance rules (before 300 only Quake or shield, Quake 1 in 10 and 1 in 5 beyond 750, disabled
  bonuses are shields, Pure has none), an unchanged stream with bonuses off, the texel kind, pick-up sets the
  hand, a second bonus spot changes nothing, a shield spot still gives a shield.
- Scene test: the HUD ring shows the held bonus.
- Screenshot of each coloured spot (user review).

## Out of scope
- Firing and the effects (slices 0027, 0028).
