# 0028. Credits, the upgrade catalogue and the passive upgrades

- Status: Accepted
- Date: 2026-11-07
- Deciders: Nicolás Hermosilla P. (instruction to go on, Tachyon Boost dropped), agent
- Intent: 0010

## Context
Doc 08 and 13 define the upgrades, their prices and unlock schedule, and say normal play never awarded
credits. We need credits from play, persistence next to the stage progress, and a way to apply the upgrades'
numbers to the existing `RunConfig`.

## Decision
- **`Upgrade`** (`src/model/upgrade.gd`): a static table of six entries `{key, name, prices[], unlock[]}` with
  the prices of doc 08 and, per level, the number of completed races that unlocks it. Keys: `flow_control`,
  `fractal_shields`, `modulator`, `recharger`, `torpedo`, `phase_shift`. Helpers: `levels(key)`,
  `price(key, level)`, `unlock_at(key, level)`, `applies(key, mode)` where mode is a stage race or a Survival
  difficulty (Extreme and Pure none; Casual, Easy and Standard all but Flow Control and Modulator).
- **`Economy`** (`src/core/economy.gd`): a `ConfigFile` at `user://economy.cfg` with `gained`, `spent`,
  `races` (total distinct races ever finished) and `levels/<key>`. API: `credits()` (never below zero),
  `earn(n)`, `spend(n)`, `level(key)`, `races()`, `is_unlocked(key, level)`, `can_buy(key)`, `buy(key)` (the
  next level, if unlocked and affordable), `any_buyable()`, `race_finished(stage, is_new_race, is_stage_end)`
  (adds the counter and the reward), `survival_score(score)` (1 credit per 500). Missing or corrupt files give
  zeros. The path is injectable.
- **Rewards**: a new race gives `2 + stage` credits, a finished stage 10 more, a Survival run `score / 500`
  when it ends in a plain run. The numbers live in constants next to the table.
- **Applying passive upgrades**: `Upgrades.apply(config, economy, applicable)` (`src/model/upgrades.gd`)
  adjusts a `RunConfig`: decay seconds 20 + {0, 1, 3, 5}, and for stage races maximum shields 3 + modulator
  level and the stage speed factor 0.87 / 0.95 / 1.09 (`RaceConfig.from_spec(spec, score, factor)` multiplies
  the file's speed by it). It also records the active upgrade levels in `RunConfig` for ADR 0029. A run with
  no upgrade levels is exactly what it was; debug and benchmark runs skip the economy altogether.
- **Where**: `main.gd` builds the config as now and then calls `Upgrades.apply` for plain runs.

## Alternatives considered
- Credits in `best.cfg` or `stages.cfg` — the economy changes on other events and must survive a stage restart.
- Rewarding every finish — repeating race 1 would farm credits; only new races pay, and restarting a stage
  makes its races new again by `StageProgress.finish_race` advancing progress.

## Consequences
- Prices, thresholds and rewards are data, so balance changes are one-line edits.
- Tachyon Boost is not in the table.
