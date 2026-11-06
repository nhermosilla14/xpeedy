# 0011. Survival core on the RG351P

- Status: Proposed
- Date: 2026-11-06
- Owner: agent, Nicolás Hermosilla P. (on-device run)
- Intents: 0003
- ADRs: 0009, 0010
- Depends on: slice 0010

## Scope
Verify that the complete Survival core holds the frame-rate budget on the RG351P with obstacles, trails,
spots, explosions and the HUD on screen, fix what does not, and close intent 0003.

## Layers touched
- Foundation: a deterministic benchmark mode (a fixed seed and an autopilot that dodges or ploughs
  through) so runs are comparable; packaging of the new shaders.
- Fixes found by the benchmark, recorded in the slice notes (they may need a superseding ADR).

## End-to-end test
- Desktop profile of CPU per tick with obstacles on screen, explosions active and trails changing.
- RG351P: a 60 s run at full density (play past segment 2250, level 15) and a benchmark run; pass per
  intent 0003: every 10 s window averages ≥ 58 fps with a 1 % low ≥ 50 fps. Results recorded here.
- User confirmation that the game is playable and fun enough to continue.

## Out of scope
- New features. Anything found that needs new behaviour becomes a new intent.
