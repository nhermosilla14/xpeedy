# 0009. Stage mode

- Status: Done
- Date: 2026-11-07
- Owner: Nicolás Hermosilla P., agent
- Related ADRs: 0024, 0025

## Goal
The "Single" mode of the original (doc 11): four stages of twelve finite races, each described by a race file,
played in order with progress, a running score and a personal best per stage. The player picks it from a mode
menu next to Survival. The user asked for Stage mode next; the agent accepted this intent, its ADRs and
slices on that instruction, and the user reviews the result. The RG351P benchmark stays skipped at the user's
request.

## Acceptance criteria
- **Race files**: the format of doc 11 (comments, case, ranges with an exclusive upper bound, `speed`, `track`,
  `obstacles`, `bonuses`, `zones`, `seed`) is parsed from text; a malformed file is rejected with a message.
  The 48 races of the catalogue ship as `data/stages/stage_<S>_<R>.txt` and load in order until one is
  missing. The hand-made `define` and `constructs` patterns are not part of this intent: the catalogue's
  patterns are not documented cell by cell, so those races run with generated patterns only.
- **Race rules** (doc 11): the effective speed is `speed × 0.87`; the track is the explicit shape sequence or
  a random one of the given length (the last explicit shape continues); obstacles use the enabled types, a
  spacing range and a fixed complexity level, the first pattern at spacing + 25; spots use the bonus rules
  (first group at spacing + 50, group size range, 1 in 8 skipped, a 50 % bonus roll with 10 % per bonus,
  shields only if enabled, none if the line is missing); zones are random (first mark at spacing + 50, next
  spacing + 3000 ÷ TPS + 1 later, from the allowed list) or at fixed segments; a fixed `seed` makes the race
  identical every time. Disabled beams become cubes.
- **Finishing**: the race ends when the ship has travelled the run length. A light-green full-width finish line
  is drawn just before that point, the last segments fade to black, a light-green flash plays and the run stops.
- **Progression** (doc 11, 09), saved on the device: stage 1 is open; stage n opens when every race of the
  earlier stages is done. Selecting a stage starts its next unfinished race; when all are done a dialog offers
  to restart the stage (progress and running score back to zero). The score accumulates across the races of a
  stage; a crash resets the running score to 0, keeps the progress and retries the same race. Finishing the
  last race saves the stage's personal best (only if higher).
- **Menus**: "play" opens a mode menu ("single", "survival"); "single" opens the stage list with four stages,
  a progress bar each (races done of twelve) and a padlock on locked ones; the run shows "stage 01 / run 01"
  during the start sequence. Finishing a race that is not the last opens a panel "run finished" with "next
  run" and "main menu"; the last race opens "stage finished" with the score, the best and "main menu". Game
  Over in a race offers "new game" (the same race) and "main menu"; the pause panel is the same as in Survival.
- Existing Survival behaviour, tests and saved files are unchanged.
- The user reviews it (screenshots).

## Out of scope
- Hand-made patterns and `constructs`, Flow Control and the other upgrades, "keep going", credits for finishing
  races, upgrade unlocks by race count, achievements, challenges (multiplayer), the stage-select screen's
  exact artwork.

## Open questions
- None. Where the doc is silent the decisions are in ADR 0024 and ADR 0025.
