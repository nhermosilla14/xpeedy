# 0034. Race-driven generation

- Status: Done
- Date: 2026-11-07
- Owner: agent
- Intents: 0009
- ADRs: 0024, 0025
- Depends on: slice 0033

## Scope
Explicit track parts, stage rules for obstacles, spots and zones, `RaceConfig`, the speed factor and the run length; a stage race runs through `SurvivalRun`.

## End-to-end test
- Unit tests: explicit parts and their continuation, spacing and first points (+25, +50), the fixed level, beams become cubes, spot and bonus rolls, shields off, random and fixed zones, a fixed seed gives identical races, Survival tracks unchanged.

## Out of scope
- Finishing and menus.

## Results
- `PartSequence` takes an explicit list; `ObstacleField`, `SpotField` and `ZoneField` take the race as optional
  rules; `RaceConfig.from_spec`; `tests/unit/test_race_generation.gd` (16 tests, including that every one of the
  48 races builds and generates). "a-b" ranges have an exclusive upper bound, so "2-3" is exactly 2 spots.
