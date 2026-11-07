# 0023. Moving obstacles model: rollers

- Status: Done
- Date: 2026-11-07
- Owner: agent
- Intents: 0006
- ADRs: 0020
- Depends on: slice 0022

## Scope
The `ROLLER` kind: step, rest, direction, wrap and reflect, danger lanes by progress, trail lanes refreshed
each tick, the stomp event, and the roller alternatives of patterns 0, 2, 3, 4, 6 and 8.

## Layers touched
- Model: `MovingMath`, `Obstacle`, `TrailMap.set_lanes`, `PatternLibrary` formations, `SurvivalRun`
  (roller registry, trail refresh, stomp events), `RunEvent`.

## End-to-end test
- Unit tests: step time per shape and TPS, the lane sequence on a tube (wrap) and a ribbon (reflect), danger
  lanes at 20 %, 50 %, 80 % and at rest, trail lanes follow, collision during a step, the stomp event near
  the ship only, the formation table (sizes, directions, phases, segments).
- Scene test: a roller crossing the ship's lane crashes it at the right moment and is smashed with a shield
  for +200.

## Out of scope
- Drawing, the camera shake (slice 0024).
