class_name RaceConfig
extends RefCounted
## Builds the run settings of a stage race from its description (ADR 0024).


## `start_score` is the stage's running score the race begins with.
static func from_spec(spec: RaceSpec, start_score := 0, speed_factor := RaceSpec.SPEED_FACTOR) -> RunConfig:
	var config := RunConfig.standard()
	config.race = spec
	config.target_tps = spec.speed * speed_factor
	config.spikes_enabled = spec.spikes
	config.rollers_enabled = spec.rollers
	config.bouncers_enabled = spec.bouncers
	config.quake_enabled = spec.bonuses
	config.dilation_enabled = spec.bonuses
	config.fold_enabled = spec.bonuses
	config.generate_spots = spec.has_spots
	config.run_length = spec.run_length()
	config.start_score = start_score
	var zones: Array[int] = []
	match spec.zone_mode:
		RaceSpec.ZoneMode.RANDOM:
			zones.append_array(spec.allowed_zones)
		RaceSpec.ZoneMode.FIXED:
			for mark in spec.fixed_zones:
				if not zones.has(mark.x):
					zones.append(mark.x)
	config.zones = zones
	config.parts = spec.parts
	return config
