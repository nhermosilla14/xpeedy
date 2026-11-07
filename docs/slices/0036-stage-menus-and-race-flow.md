# 0036. Mode and stage menus, and the race flow

- Status: Accepted
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
