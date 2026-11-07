# 0028. Time Dilation

- Status: Accepted
- Date: 2026-11-07
- Owner: agent, Nicolás Hermosilla P. (look review)
- Intents: 0007
- ADRs: 0022
- Depends on: slice 0027

## Scope
The 75 % game clock for 7 game seconds, rollers and bouncers frozen, restart on a second fire, the blue tint
and flashes.

## Layers touched
- Model: `SurvivalRun`, `RunEvent`. App/view: `main.gd` (clock scale), `Tint` node.

## End-to-end test
- Unit tests: 7 game seconds last about 9.33 real seconds at scale 0.75; `game_time` does not advance while it
  is active; shield decay slows with the clock; a second fire restarts it; it ends with an event.
- Scene test: fire, the clock scale is 0.75 and the tint shows, then both return to normal.

## Out of scope
- Zones, upgrades.
