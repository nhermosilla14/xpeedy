# 11 – Stage mode ("Single")

## Structure

- **4 stages** of **12 races** each, 48 races in total.
- Each race is a finite run defined by a **race description file** (format below): speed, track
  shapes, run length, obstacle mix, bonuses, zones, and optionally hand-made obstacle patterns and a fixed seed.
- Races are played **in order** within a stage.

## Progression

- **Stage 1** is always available. **Stage *n*** unlocks once every race of the stages before it has
  been completed. Internally, a counter of total races ever completed is compared with the cumulative
  race count.
- Selecting a stage starts its **next unfinished race**.
- If every race of the stage is done, a dialog offers to **restart the stage**, which resets its
  progress and running score to zero.
- **Finishing a race** (travelling its full run length):
  - a light-green flash;
  - the stage's progress advances, the stage's running score becomes the current score, and the
    "total races completed" counter rises if this is a new race;
  - new upgrade levels may unlock ([08](08-upgrades.md));
  - if more races remain: the **"Run finished"** menu (Next run · Upgrades · Main menu);
  - if it was the last race: the personal best for the stage is saved, then the **"Stage finished"**
    menu (Upgrades · Main menu).
- **Crashing** in a race resets the stage's running score to 0 but keeps progress. The same race is
  retried, starting from 0 points.
- The stage-select screen shows each stage's completion as a progress bar, and a padlock on locked stages.

### Run length and finish

A race ends successfully when the ship has travelled its **run length** in segments. A full-width
finish-line spot is drawn just before that point, and the last ~5 segments fade to black over 10 segments.

### Speed in stage races

The file's `speed` is the target TPS before the stage speed factor: 0.87 by default, 0.95 / 1.09 with
*Flow Control* ([03](03-movement-and-controls.md)). For example, `speed: 130` is really 113 ms per segment.

## Race description file format

Plain text, one `property: value` per line.

- Text after `#` is a comment. Blank lines are ignored. Keywords are case-insensitive.
- Each property may appear **once**, except `define`, which may appear many times.
- Lists are comma-separated. A **range** is written `a-b` and yields a random integer from *a* up to
  *b* − 1 (the upper bound is **exclusive**), or exactly *a* when *a* = *b*.
- Files are named `stage_<S>_<R>` (1-based) and loaded in order until a file is missing. A malformed
  file stops loading, so later races do not exist.

| Property | Required | Syntax | Meaning |
|---|---|---|---|
| `speed` | yes | integer | Target TPS (before the stage speed factor) |
| `track` | yes | `random:<length>` **or** `<shape>:<len>, <shape>:<len>, …` with shape `in`, `flat` or `out` | Random shape sequence with the given run length, **or** an explicit sequence. The first shape is the starting one. The run length is the sum of all lengths, and after the last part the shape stays the same. |
| `obstacles` | yes | `<types…>, <spacing range>, <level>` with types from `cubes`, `beams`, `rollers`, `bouncers`, `spikes`, or `all` | Enabled obstacle types (`cubes` is mandatory), spacing between patterns, and the fixed pattern complexity level ([04](04-obstacles.md)) |
| `bonuses` | no | `<kinds…>, <spacing range>, <group-size range>` with kinds `shields`, `bonuses`, or `all` | Spot groups: spacing between groups and number of spots per group. Omit for no spots at all. |
| `zones` | no | `random, <zone names… or all>, <spacing range>` **or** `<zone>@<segment>, …` | Random zone marks from the allowed list at the given spacing, or marks at fixed segments. Zone names: `blackout`, `gravity`, `nebula`, `hueshift`, `plasma`. |
| `define` | no | `<name>, <lock>, <single colour true/false>, <cells…> [, colormap, <colours…>]` | A hand-made pattern: cells are listed 16 per segment (lane 0 to 15), each 0 empty, 1 cube, 2 beam or 3 spike. *lock* reserves (*lock* × spacing) extra empty segments after it. With *single colour* the whole pattern shares one random colour, otherwise each cell is random. An optional `colormap` gives a palette index 0–4 per cell. |
| `constructs` | no | `<name>@<min segment>, …` (in ascending order) | Places each named pattern once, instead of the generated pattern at the first placement point after its minimum segment |
| `seed` | no | integer | Fixed random seed: the race is identical every time. Without it, races are seeded from the clock. |

### Generation inside a race

- **Obstacles**: the first pattern is at (spacing) + 25. Each later one is (spacing) × (*lock* + 1)
  further on, where *lock* is 0 for generated patterns. Moving patterns appear only if rollers or
  bouncers are enabled; wall variants only on flat or outside track before a shape change; spike variants only if spikes are enabled.
- **Spots**: the first group is at (spacing) + 50, and each group has a 1-in-8 chance of being skipped.
  - With `bonuses` (or `all`), each spot has a 50 % chance to roll for a bonus. That roll gives Quake,
    Time Dilation or Space Fold with 10 % each, so each bonus ends up on about 5 % of spots.
  - The remaining spots are shields if `shields` (or `all`) is enabled; otherwise they are left empty.
- **Random zones**: the first mark is at (spacing) + 50. The next comes (spacing) + 3000 ÷ TPS + 1
  segments later. The type is uniform over the allowed list.
- **Fixed zones**: a mark appears exactly at each listed segment.

## Race catalogue (original game data)

Columns are as written in the files. "Spacing" ranges have an exclusive upper bound, and effective
TPS = speed × 0.87 without Flow Control.

| Race | speed | track | obstacles | bonuses | zones | hand-made patterns |
|---|---|---|---|---|---|---|
| 1-1 | 130 | in:500 | cubes, 20-30, 4 | — | — | — |
| 1-2 | 120 | in:600 | cubes, 20-30, 4 | shields, 80-120, 1-1 | blackout@300 | — |
| 1-3 | 120 | in:200, flat:60, out:200, flat:100, in:200 | cubes, 10-30, 4 | shields, 60-100, 1-1 | gravity@500 | — |
| 1-4 | 120 | random:1400 | cubes, beams, spikes, 20-30, 4 | shields, 60-100, 1-2 | gravity@300, nebula@1000 | — |
| 1-5 | 110 | in:1000 | cubes, beams, spikes, 15-25, 5 | — | random, blackout, gravity, hueshift, 150-250 | 2 |
| 1-6 | 110 | flat:1000 | cubes, beams, spikes, rollers, 15-20, 6 | shields, 50-80, 1-2 | plasma@200, plasma@600 | — |
| 1-7 | 110 | in:300, flat:100, out:300, flat:100, in:300 | cubes, beams, spikes, rollers, 15-20, 6 | shields, 50-80, 1-3 | hueshift@250, nebula@500, nebula@750 | — |
| 1-8 | 110 | in:1800 | cubes, rollers, bouncers, 15-20, 6 | shields, 40-80, 1-2 | random, nebula, gravity, plasma, 250-400 | 2 |
| 1-9 | 110 | in:500, flat:500, out:500 | cubes, rollers, bouncers, 15-20, 5 | shields, 60-100, 1-3 | gravity@300, gravity@700, gravity@1200 | 3 |
| 1-10 | 110 | flat:300, out:300, flat:300, in:400 | all, 15-20, 6 | shields, 40-120, 1-3 | random, all, 250-400 | 2 |
| 1-11 | 110 | random:2000 | all, 10-30, 6 | shields, 80-200, 2-4 | random, all, 200-250 | — |
| 1-12 | 120 | in:600, flat:600, out:600 | all, 8-20, 7 | shields, 60-120, 1-3 | random, all, 200-250 | 2 |
| 2-1 | 95 | random:1500 | all, 20-30, 7 | shields, 30-40, 1-2 | random, all, 200-300 | — |
| 2-2 | 95 | in:600, flat:60, out:800 | all, 15-30, 6 | all, 40-60, 1-3 | hueshift@300, hueshift@700, gravity@1100 | 4 |
| 2-3 | 90 | out:400, flat:400, in:200, flat:200, in:200 | cubes, 10-30, 8 | bonuses, 20-50, 2-3 | random, gravity, nebula, hueshift, blackout, 200-250 | — |
| 2-4 | 90 | in:300, flat:300, out:200, flat:200, in:200, flat:400, in:300 | cubes, beams, spikes, 12-25, 6 | all, 20-50, 1-2 | random, all, 200-300 | 2 |
| 2-5 | 90 | out:1550 | all, 15-25, 8 | shields, 30-60, 1-3 | random, blackout, plasma, 150-250 | 3 |
| 2-6 | 90 | random:2000 | all, 16-22, 8 | all, 60-80, 1-4 | random, all, 200-400 | 2 |
| 2-7 | 85 | in:400, flat:400, out:400, flat:400, in:400 | cubes, beams, spikes, rollers, 10-25, 8 | shields, 35-80, 2-4 | random, hueshift, gravity, 500-500 | 4 |
| 2-8 | 90 | in:1800 | all, 20-25, 8 | all, 40-60, 1-3 | random, nebula, gravity, plasma, 250-400 | 12 |
| 2-9 | 85 | in:500, flat:500, out:500 | cubes, beams, rollers, bouncers, 15-20, 8 | shields, 40-60, 1-3 | gravity@300, @600, @900, @1200 | 3 |
| 2-10 | 80 | flat:2000 | cubes, beams, rollers, 12-18, 8 | all, 40-100, 2-3 | random, nebula, hueshift, 250-400 | 11 |
| 2-11 | 80 | random:2000 | all, 12-18, 8 | shields, 40-60, 1-3 | random, all, 200-250 | — |
| 2-12 | 80 | in:600, flat:600, out:600 | all, 8-20, 8 | shields, 35-55, 1-3 | random, all, 200-250 | 4 |
| 3-1 | 65 | in:1500 | cubes, beams, 20-30, 8 | shields, 60-90, 1-4 | — | — |
| 3-2 | 65 | out:400, flat:400, in:200, flat:200, in:200 | cubes, beams, 12-30, 8 | all, 40-60, 2-3 | random, gravity, nebula, hueshift, blackout, 200-250 | — |
| 3-3 | 70 | in:150, flat:150, out:250, flat:150, in:150, flat:150, in:150, flat:150, out:250, flat:250, in:300 | cubes, beams, spikes, 12-24, 8 | all, 36-56, 1-3 | gravity@150, nebula@450, gravity@800, hueshift@850, hueshift@1100, nebula@1150, blackout@1450, blackout@1800 | — |
| 3-4 | 65 | random:2200 | all, 12-25, 10 | all, 20-50, 1-2 | random, blackout, nebula, 200-300 | 5 |
| 3-5 | 70 | in:2000 | cubes, beams, spikes, 18-24, 10 | — | random, all, 250-300 | 6 |
| 3-6 | 65 | flat:1500 | cubes, beams, rollers, 16-24, 12 | all, 20-80, 1-3 | blackout@200, gravity@1100 | 1 |
| 3-7 | 65 | in:300, flat:100, out:300, flat:100, in:600 | all, 15-20, 10 | all, 40-80, 1-3 | hueshift@250, plasma@500, nebula@750 | 1 |
| 3-8 | 65 | flat:1800 | cubes, beams, rollers, 15-25, 12 | all, 20-80, 1-3 | random, nebula, gravity, plasma, 250-400 | — |
| 3-9 | 85 | in:500, flat:500, out:500 | cubes, beams, rollers, bouncers, 15-20, 8 | all, 20-60, 1-3 | gravity@300, blackout@600, nebula@900, plasma@1200 | 4 |
| 3-10 | 70 | in:400, flat:400, out:400, flat:400, in:400 | cubes, beams, spikes, rollers, 10-25, 10 | shields, 20-80, 1-4 | random, hueshift, gravity, 400-500 | 4 |
| 3-11 | 65 | random:2400 | all, 12-18, 12 | shields, 30-60, 1-3 | random, all, 200-250 | — |
| 3-12 | 65 | in:2200 | all, 15-20, 15 | all, 20-60, 1-3 | random, all, 250-400 | 12 |
| 4-1 | 52 | random:1000 | all, 20-30, 8 | all, 40-50, 1-3 | — | — |
| 4-2 | 50 | in:1200 | cubes, 20-30, 10 | shields, 40-60, 1-3 | blackout@300, nebula@600, gravity@900 | — |
| 4-3 | 55 | in:500, flat:60, out:500, flat:100, in:500, flat:200, in:200 | cubes, beams, spikes, rollers, 18-24, 15 | shields, 40-100, 1-4 | gravity@500, @1000, @1500 | — |
| 4-4 | 52 | random:2000 | cubes, beams, spikes, 20-30, 12 | shields, 60-100, 1-3 | gravity@300, nebula@1000 | 3 |
| 4-5 | 55 | out:1550 | all, 15-25, 15 | all, 24-48, 1-3 | random, all, 150-250 | 3 |
| 4-6 | 50 | random:2000 | all, 20-30, 15 | all, 20-60, 1-4 | random, all, 200-400 | 2 |
| 4-7 | 55 | in:400, flat:400, out:400, flat:400, in:400 | cubes, beams, spikes, rollers, 18-26, 15 | all, 25-80, 2-4 | random, nebula, plasma, 500-500 | 3 |
| 4-8 | 50 | flat:2500 | cubes, beams, rollers, 20-25, 12 | all, 20-60, 1-3 | random, nebula, gravity, plasma, 250-400 | 5 |
| 4-9 | 55 | in:500, flat:500, out:500, then alternating flat/in/out parts of 100 each, ending in:200 | cubes, beams, spikes, rollers, 15-20, 15 | all, 20-60, 1-3 | random, gravity, nebula, blackout, 300-300 | — |
| 4-10 | 48 | in:2000 | all, 10-25, 15 | shields, 20-80, 1-4 | random, all, 400-500 | 4 |
| 4-11 | 52 | random:2000 | all, 12-18, 15 | all, 30-60, 1-3 | random, all, 200-250 | — |
| 4-12 | 48 | in:1000, flat:100, out:500, flat:100, in:1000 | all, 8-24, 15 | all, 20-35, 1-3 | random, all, 250-350 | — |

Notes on the data:

- Races 1-1 to 1-3 are a tutorial: cubes only, a single shape or simple shape changes, one zone, few shields.
- 8 races use a fixed `seed` (for example 4-6), so they are always the same.
- The hand-made patterns (rings, walls, zig-zags, columns, "bunkers", and others) are 1–8 segments
  long and mostly use spikes and beams. They appear as single set pieces at the given segments.
- Because the upper bound is exclusive, `1-1` means exactly 1 spot and `1-3` means 1 or 2 spots.
