# 0035. Finishing a race and stage progress

- Status: Done
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

## Results
- `SurvivalRun.finished` and `RACE_FINISHED`, the finish line (trail code 11; the alpha step became 20), the
  `finish_segment` global uniform and the black fade in the tunnel shader, `StageProgress`
  (`tests/unit/test_stage_progress.gd`, 10 tests), `Main.start_race`, progress saved on finish and reset on a
  crash, and `--race=S-R`. `tests/e2e_races.gd` covers the finish, flash, stop, saved progress and the crash reset.
- The capture `build/look/finish.png` shows the fade towards black but not the green line itself; the finish
  line colour is untested on screen.
