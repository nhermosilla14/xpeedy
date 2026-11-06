# 0010. Pattern catalogue and difficulty progression

- Status: Proposed
- Date: 2026-11-06
- Owner: agent
- Intents: 0003
- ADRs: 0008, 0009
- Depends on: slice 0009

## Scope
All static patterns of doc 04 (indexes 0–15) with their spike and wall variants, the pattern level
growing with distance (a new tier every 150 segments, single cubes disappearing after level 5), and
spikes as a third obstacle type (1 shield, +100).

## Layers touched
- Model: `PatternLibrary` completed (all indexes, variants, colour rules, fit-in-part rule, flat-part
  lane fitting), spike obstacles and `RunConfig` toggle, level and spacing progression.
- View: spike mesh instances (already planned in the shader), nothing else.

## End-to-end test
- Unit tests: for every level and many seeds, patterns generate only the documented formations
  (counts, lane offsets, segment offsets, colours), stay inside lanes 0–15 on flat parts, never extend
  past the end of their part for wall variants, index selection follows `min(level, 15)` with the shift
  above level 5, spikes appear in about 1 in 3 placements where a spike formation exists, same seed
  gives the same track, no pattern leaves an impassable gap (at least one lane column is free in every
  segment of a ring).
- Scene test: a long seeded run at 3000 segments shows rising density and tier unlocks; the ship
  smashes spikes with one shield for +100.
- Desktop visual check of every formation class.

## Out of scope
- Rollers, bouncers and the moving variants (next target).
