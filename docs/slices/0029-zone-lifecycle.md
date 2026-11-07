# 0029. Zone marks, lifecycle and Space Fold

- Status: In progress
- Date: 2026-11-07
- Owner: agent
- Intents: 0008
- ADRs: 0023
- Depends on: slice 0028

## Scope
`Zone`, `ZoneField` and the marks in the trail texture, the lifecycle (countdown, active, ended) and its
events, the banner and flashes, difficulty zone lists, Space Fold ending an active zone.

## Layers touched
- Model: `Zone`, `ZoneField`, `TrailMap` (alpha code × 25), `SurvivalRun`, `RunConfig`, `Difficulty`.
- View: shader mark colours, `ZoneBanner`, `main.gd`.

## End-to-end test
- Unit tests: mark spacing and re-rolls, no zones when none are enabled (older tracks unchanged), crossing a
  mark starts the countdown only when idle, 3 s then 7 s of game time, Time Dilation stretches both, Space
  Fold ends an active zone and is wasted otherwise, events in order.
- Scene test: cross a mark, the banner and flashes show, the zone starts and ends.

## Out of scope
- The effects of each zone (slices 0030-0032).
