# 0019. Survival difficulties, per-difficulty bests and settings

- Status: Accepted
- Date: 2026-11-07
- Deciders: Nicolás Hermosilla P. (delegated to the agent), agent
- Intent: 0005

## Context
Doc 10 defines Casual (133 ms per segment), Easy (100), Standard (80), Extreme (67) and Pure (50, cubes
and beams only). `RunConfig` has `target_tps` and `spikes_enabled` already. ADR 0017 stores one personal best
(`survival_standard`). Doc 16 lists a persisted settings set; `Steering` already has an invert flag.

## Decision
- **`Difficulty`** (`src/model/difficulty.gd`): a static table of the five keys (`casual`, `easy`,
  `standard`, `extreme`, `pure`) with their label, triangle count and badge colour, and
  `Difficulty.config(key) -> RunConfig` returning `RunConfig.standard()` adjusted (`target_tps`,
  `spikes_enabled`). Zones, bonuses, rollers and bouncers are added to the table by their intents.
  The ramp end speed and everything derived from `target_tps` already follow the config.
- **Personal best keys** become `survival_<difficulty>`; `PersonalBest.SURVIVAL_STANDARD` becomes
  `PersonalBest.key(difficulty)`. The existing `survival_standard` entries stay valid.
- **`Settings`** (`src/core/settings.gd`): a `ConfigFile` at `user://settings.cfg` with `steering/invert`
  (bool). Missing or invalid values fall back to the defaults. The path is injectable for tests, as with
  `PersonalBest`. `main.gd` loads it when a run starts and applies `invert` to its `Steering`.
- Settings are read when a run starts, as in doc 16.

## Alternatives considered
- Extending `RunConfig` with named constructors — the table also feeds the menu (labels, badges), so a
  separate `Difficulty` keeps menu data out of the rules.
- One file for bests and settings — they change at different times and bests must never be lost to a settings
  reset.

## Consequences
- A new difficulty or custom mode is a table entry plus its rules.
- `main.gd` gets a current-difficulty field used by restart, "new game" and the best-score label.
