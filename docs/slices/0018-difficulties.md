# 0018. Survival difficulties and per-difficulty bests

- Status: In progress
- Date: 2026-11-07
- Owner: agent
- Intents: 0005
- ADRs: 0019
- Depends on: slice 0017

## Scope
The five Survival difficulties as data, a run of each difficulty, personal bests per difficulty. A debug
option `--difficulty=KEY` selects one for a plain run (the menu uses the same path in slice 0019).

## Layers touched
- Model: `Difficulty` table and config builder; `PersonalBest.key`.
- View/app: `main.gd` current difficulty, used for the config, the best-score label and the Game Over panel.

## End-to-end test
- Unit tests: each difficulty's `target_tps`, Pure has no spikes, Standard equals `RunConfig.standard()`,
  unknown keys fall back to Standard; best keys differ per difficulty.
- Scene test: a plain run with `--difficulty=extreme` flies at the 67 ms target speed after the ramp, and
  its Game Over saves the best under its own key.

## Out of scope
- Menus (slice 0019), zones, bonuses, rollers, bouncers.
