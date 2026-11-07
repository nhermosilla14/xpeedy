# 0010. Pattern catalogue and difficulty progression

- Status: Done
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

## Results (2026-11-06)
- Design: ADR 0013 fixes how doc 04 is read where it is silent (index selection above level 5, the order
  of spike, wall and regular choices, pendulum and cross geometry, colours, lane fitting, draw order).
- 151 unit tests and 7 end-to-end tests pass. The new tests check, over many seeds and every shape: the
  index drawn per level (including that single cubes stop above level 5 and nothing exceeds index 15);
  that each index only produces its documented formations, and that every documented formation
  appears; the exact structure of every formation (counts, kinds, segment and lane offsets, colours,
  repeats of spreads); that fitting formations never wrap on flat parts while ring formations wrap on
  every shape; that cube and beam walls never appear in IN parts; the variant chances (spike 1/3, wall
  1/3 after the spike draw, 2/9 together); mixed and two-colour rules; that no pattern blocks more than
  12 lanes of a segment; determinism; the early singles, the later density, and that single cubes
  vanish from segment 900; the instance budget (at most 160 per kind in any window); and the spikes
  toggle.
- Mutation check: allowing walls in IN parts, and removing the flat-edge fitting, each made the right
  tests fail.
- `tests/e2e_patterns.gd`, through the real scene: jumping to segment 2300 generates 150+ patterns up to
  level 15 with cubes, beams and spikes, the instance buffers match the model, and the ship smashes a
  spike with one shield for +100 and one shield.
- Desktop visual check (real GPU, ghost mode at 6× speed, score 3000–4000): dense multi-colour trails,
  cube walls with spikes, diagonals and ring formations on tube, flat and outside parts.
- CPU per tick at segment 2300+ (`tests/profile_tunnel.gd`, now starting there): views 0.09–0.12 ms.
- The profile now starts at segment 2300 to measure full density.
