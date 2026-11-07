# 0017. The original look on the RG351P

- Status: Proposed
- Date: 2026-11-07
- Owner: agent, Nicolás Hermosilla P. (on-device run and final review)
- Intents: 0004
- ADRs: 0015, 0016, 0017
- Depends on: slice 0016

## Scope
Verify that the new look holds the frame-rate budget on the RG351P, tune it if not, review the whole
look with the user, and close intent 0004.

## Layers touched
- Fixes found by the benchmark (the ADR 0015 fallbacks), recorded in the slice notes.

## End-to-end test
- RG351P: the `--benchmark` run; every 10 s window keeps an average of at least 58 fps and a 1 % low of at
  least 50 fps. A normal play session with the countdown, pause and Game Over.
- Desktop: the same benchmark for the record.
- Final review with the user of side-by-side screenshots; the user confirms the look is close, and the
  remaining differences are written down as new intents.

## Out of scope
- New features.
