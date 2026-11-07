# 0039. Active upgrades: the model

- Status: In progress
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
