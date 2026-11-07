# 0039. Active upgrades: the model

- Status: Done
- Date: 2026-11-07
- Owner: agent
- Intents: 0010
- ADRs: 0028, 0029
- Depends on: slice 0038

## Scope
Shield Recharger, Tachyon Torpedo and Phase Shift in `SurvivalRun` with their events.

## End-to-end test
- Unit tests: the recharger adds, caps and restarts the timer and is used once; torpedo count, flight, kills (also tube beam opposite lane and moving obstacles), no points, reload in travel segments, the 25-segment limit; Phase Shift duration, warnings, ignoring obstacles and plasma, spots still collected; pause and Time Dilation freeze or slow the timers.

## Out of scope
- Buttons and input.

## Results
- `SurvivalRun` has the Recharger, the Torpedo (a `Torpedo` list, reload in travel segments) and Phase Shift,
  plus `can_continue` and `continue_run` for slice 0041; `tests/unit/test_active_upgrades.gd` (18 tests).
- A torpedo that flies until it is 25 segments ahead of the ship reaches farther into the world than 25 from
  where it was fired, because it moves at twice the ship's speed. A bouncer is hit on its own lane whatever its
  height; rollers and tube beams use the lanes they are dangerous on.
