# 0025. Rollers and bouncers on the RG351P

- Status: Accepted
- Date: 2026-11-07
- Owner: agent, Nicolás Hermosilla P. (on-device run and final review)
- Intents: 0006
- ADRs: 0020, 0021
- Depends on: slice 0024

## Scope
Verify the frame rate with the moving obstacles in the benchmark, tune if needed, and close intent 0006 with
the user's review.

## End-to-end test
- RG351P: `--benchmark` keeps an average of at least 58 fps and a 1 % low of at least 50 fps in every 10 s
  window; a play session on Standard and Extreme.
- Desktop: the same benchmark for the record.

## Out of scope
- New features.
