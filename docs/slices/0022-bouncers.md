# 0022. Moving obstacles model: bouncers

- Status: Done
- Date: 2026-11-07
- Owner: agent
- Intents: 0006
- ADRs: 0020
- Depends on: slice 0021

## Scope
`MovingMath`, the `BOUNCER` kind, game time in `SurvivalRun`, collision with the danger lanes of bouncers,
smashing (+200), difficulty flags, and the moving formations of patterns 0, 2, 3 and 4 with bouncers (rollers
come in slice 0023, so the roller alternatives are not drawn yet; the table of the formations is complete in
the code once both exist).

## Layers touched
- Model: `Obstacle`, `MovingMath`, `PatternLibrary`, `ObstacleField` context, `RunConfig`, `Difficulty`,
  `SurvivalRun`.

## End-to-end test
- Unit tests: bouncer height and half-period per TPS, danger windows own lane and opposite lane (tube only),
  collision crashes in the danger window and passes in the safe window, smashing gives +200 and costs one
  shield, Pure generates exactly the old track, a deterministic moving track per seed.
- Scene test: a run with a bouncer in front of the ship is survived or crashed according to the time of
  arrival (tests set the game time).

## Out of scope
- Drawing (slice 0024), rollers.

## Results
- Slices 0022 and 0023 were built together: `MovingMath`, both kinds, patterns and trails are in
  `tests/unit/test_moving.gd` (20 tests). The scene-level checks are the unit tests that step a `SurvivalRun`
  (crash, pass and smash for bouncers and rollers).
