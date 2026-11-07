# 0025. Stage progress, the stage menus and the race flow

- Status: Accepted
- Date: 2026-11-07
- Deciders: Nicolás Hermosilla P. (instruction to go on), agent
- Intent: 0009

## Context
Stage mode keeps progress between sessions (races done per stage, a running score, a best per stage) and adds
menus (mode, stages) and end-of-race panels. ADR 0017–0019 gave the run flow, panels, menus and saved files.

## Decision
- **`StageProgress`** (`src/core/stage_progress.gd`): a `ConfigFile` at `user://stages.cfg` with, per stage,
  `done` (0–12), `score` (running) and `best`. API: `done(stage)`, `score(stage)`, `best(stage)`,
  `is_unlocked(stage)` (stage 1 always; stage n when every earlier stage has all its races done),
  `next_race(stage)` (1-based, or 0 when complete), `finish_race(stage, race, total_score)` (advances `done` if
  `race == done + 1`, stores the running score, and on the last race stores `best` if higher), `crash(stage)`
  (running score to 0), `restart(stage)`. Missing or corrupt files give zeros. The path is injectable.
- **Run kind**: `main.gd` knows `mode` (Survival or Stage), `stage` and `race`. Starting a stage race builds
  the config from the catalogue, with `start_score` from `StageProgress.score`, and the seed from the spec or
  the clock.
- **Menus**: `MenuController` gets pages for the mode ("single", "survival"), the stages (four items "stage 01"
  …, each with a progress bar of races done and a padlock when locked; activating a locked item does
  nothing) and the restart question. "play" opens the mode page; "survival" opens the difficulty page;
  "single" opens the stages; a stage with every race done first asks "restart stage?" with "yes" and "no".
- **Panels**: finishing a race shows `ScreenPanel` "run finished" (score) with "next run" and "main menu", or
  "stage finished" with the score, the personal best and "main menu" for the last race. Game Over in a race
  shows "new game" (retry the same race with score 0, progress kept) and "main menu". The start sequence
  shows a label "stage 01 / run 01" under the lights.
- **Finish effects**: a light-green full-screen flash on finishing (doc 11); the run stops and the world is
  frozen as after a crash.
- **Bests**: a stage's best shows in the best-score label like Survival's.

## Alternatives considered
- Saving stage progress in `best.cfg` — they change on different events and the file formats differ.
- A separate scene for stage mode — it is the same run and the same scene with different rules.

## Consequences
- Upgrade unlocks and credits (later intents) hook into `finish_race`.
- Stage select can later show a total races counter and the score per stage.
