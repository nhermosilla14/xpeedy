# 0036. Mode and stage menus, and the race flow

- Status: Done
- Date: 2026-11-07
- Owner: agent
- Intents: 0009
- ADRs: 0024, 0025
- Depends on: slice 0035

## Scope
Mode page, stage page with bars and padlocks, the restart dialog, race start and its label, run finished and stage finished panels, retry after Game Over.

## End-to-end test
- Scene test: play, single, stage 1 starts race 1; finishing opens the run finished panel and next run starts race 2; a crash retries the same race; a locked stage cannot be chosen; screenshots of the pages.

## Out of scope
- Upgrades, credits.

## Results
- Menu pages mode, stages (bars, counts, padlocks) and restart; `MenuScreen` draws progress items; the race
  label, "run finished" and "stage finished" panels, retry of the same race after Game Over, the best-score
  label per stage; `--screen=mode|stages`. `tests/e2e_stage_flow.gd` covers the whole flow; `tests/e2e_menus.gd`
  was updated for play, then the mode page. Captures `build/look/m-mode.png` and `m-stages.png`.
- Pause "restart" and the restart key retry the same race in a stage.
