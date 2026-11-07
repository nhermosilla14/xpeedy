class_name Upgrades
extends RefCounted
## Puts the bought upgrades into a run's settings (ADR 0028, doc 08).

const DECAY_BASE := 20.0
const DECAY_BONUS := [0.0, 1.0, 3.0, 5.0]
const STAGE_MAX_SHIELDS := 3
## Stage speed factor by Flow Control level: 0.87 normally, 0.95 and 1.09 (doc 11).
const SPEED_FACTORS := [0.87, 0.95, 1.09]


## The stage speed factor for the player's Flow Control level.
static func speed_factor(economy: Economy) -> float:
	return SPEED_FACTORS[economy.level(Upgrade.FLOW_CONTROL)]


## `mode` is `Upgrade.STAGE` or a Survival difficulty key. The speed factor is applied when the race config is
## built (`RaceConfig.from_spec`).
static func apply(config: RunConfig, economy: Economy, mode: String) -> void:
	var fractal := economy.level(Upgrade.FRACTAL_SHIELDS) if Upgrade.applies(Upgrade.FRACTAL_SHIELDS, mode) else 0
	config.shield_decay_seconds = DECAY_BASE + DECAY_BONUS[fractal]
	if mode == Upgrade.STAGE:
		config.max_shields = STAGE_MAX_SHIELDS + economy.level(Upgrade.MODULATOR)
	config.recharger_level = economy.level(Upgrade.RECHARGER) if Upgrade.applies(Upgrade.RECHARGER, mode) else 0
	config.torpedo_level = economy.level(Upgrade.TORPEDO) if Upgrade.applies(Upgrade.TORPEDO, mode) else 0
	config.phase_level = economy.level(Upgrade.PHASE_SHIFT) if Upgrade.applies(Upgrade.PHASE_SHIFT, mode) else 0
