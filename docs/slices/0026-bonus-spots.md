# 0026. Bonus spots and the held bonus

- Status: Done
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

## Results
- Slices 0026-0028 were built together: the model (`tests/unit/test_bonuses.gd`, 16 tests), the scene
  (`tests/e2e_bonuses.gd`: pick-up, ring, fire, Quake, Time Dilation) and the shader colours.
- The coloured spots were not confirmed on screen: the captures `build/look/spot-*.png` did not frame a
  bonus spot, so the colours are only checked through the texture tests and a clean shader compile.
