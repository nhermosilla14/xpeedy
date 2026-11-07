# 0024. Race files and race-driven generation

- Status: Accepted
- Date: 2026-11-07
- Deciders: Nicolás Hermosilla P. (instruction to go on), agent
- Intent: 0009

## Context
Stage races (doc 11) are described by small text files and need a finite run, explicit track shapes and
generation rules different from Survival's (spacing ranges, a fixed level, bonus rolls, fixed zones). The
generators (`PartSequence`, `ObstacleField`, `SpotField`, `ZoneField`) take Survival's rules today.

## Decision
- **`RaceSpec`** (`src/model/race_spec.gd`) holds a parsed race: `speed`, the track (`random_length` or a list
  of `(shape, length)`), the obstacle settings (type flags, spacing range, level), the optional spot settings
  (kinds, spacing range, group range), the zone settings (random with a list and a spacing range, or fixed
  `(zone, segment)` marks) and the optional `seed`; `run_length()` is the random length or the sum of the parts;
  `target_tps()` is `speed × 0.87`. **`RaceParser`** (`src/model/race_parser.gd`) reads the text of doc 11
  (`#` comments, blank lines, case-insensitive keywords, ranges `a-b` with an exclusive upper bound, a property
  at most once) and returns the spec or an error string; `define` and `constructs` lines are skipped with no
  effect. Ranges are stored as `[from, to]` and drawn with `XRandom.range_int(from, to)` (exactly `from`
  when equal).
- **`StageCatalogue`** (`src/model/stage_catalogue.gd`) loads `res://data/stages/stage_<S>_<R>.txt` for
  S = 1…4, R = 1…12, stopping a stage at the first missing or malformed file. The 48 files are our own data,
  written from the catalogue table of doc 11 (without the hand-made patterns). The export presets include
  `data/*`.
- **Explicit tracks**: `PartSequence.new(seed, fixed)` with a list of `(shape, length)` uses it as the
  sequence and, past the last part, repeats the last shape in parts of 120 segments. Without a list it is
  unchanged. `random:<n>` uses the random generator and just sets the run length.
- **Rules objects** keep Survival the default. `ObstacleField` takes optional stage rules (`first_point =
  spacing + 25`, per-placement spacing drawn from the range, a constant level, beams off → generated beams
  become cubes). `SpotField` takes optional stage rules (first group `spacing + 50`, group size and spacing
  ranges, skip 1 in 8, per spot a 50 % bonus roll then 10 % per bonus; a non-bonus spot is a shield only if
  shields are enabled, else it is not placed). `ZoneField` takes optional stage rules (random list with
  `spacing + 50` first and `spacing + 3000/TPS + 1` after, or fixed marks). Each keeps its own PRNG stream, so a
  Survival run is bit-for-bit what it was.
- **`RunConfig`** gets `run_length` (0 = endless), `start_score` and the stage rule objects; a
  **`RaceConfig.from_spec(spec)`** builds the config (target speed, enabled types, zones list, rules) used with
  `SurvivalRun`.
- **Finishing**: `SurvivalRun` emits `RACE_FINISHED` when `track.segment ≥ run_length`, then stops stepping
  (`finished = true`); the score includes the carried `start_score`. A finish mark (code 11 in the trail
  texture, a full ring of light green) is painted at `run_length − 2`, and the tunnel shader fades the tiles to
  black from `run_length − 15` (black from `run_length − 5`) using a global uniform `finish_segment` (−1 when
  there is none).

## Alternatives considered
- Rewriting the generators around one rules interface — would risk changing Survival's deterministic tracks.
- Loading race files from `user://` — the original data is fixed; a modding path can come later.
- Implementing `define` — the catalogue's patterns are not documented, so there would be nothing to load.

## Consequences
- A race is a normal `SurvivalRun` with different generators, so everything downstream (collision, trails,
  bonuses, zones) is shared.
- Races with `define` patterns in the original play without them for now.
