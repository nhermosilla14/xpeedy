# 0035. Finishing a race and stage progress

- Status: Accepted
- Date: 2026-11-07
- Owner: agent
- Intents: 0009
- ADRs: 0024, 0025
- Depends on: slice 0034

## Scope
Finish detection and event, the finish line and the black fade, the carried score, `StageProgress` saved on the device.

## End-to-end test
- Unit tests: the race finishes at the run length and stops, the score carries and resets on a crash, unlocking, next race, restart, best only if higher, a corrupt file; scene test: the finish flash and the stop.

## Out of scope
- Menus.
