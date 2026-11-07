class_name RunConfig
extends RefCounted
## Everything a difficulty changes (ADR 0008). Standard is the only preset for now; the other
## difficulties of doc 10 are later presets, not new code paths.

var target_tps := 80.0
var max_shields := 4
var shield_decay_seconds := 20.0
## Spike formations in the patterns (doc 10; every difficulty but Pure has them).
var spikes_enabled := true
## Tests and the benchmark can turn obstacle generation off.
var generate_obstacles := true
## Tests can turn shield spot generation off.
var generate_spots := true
## Debugging: shields the run starts with (`--shields=N` on the command line).
var start_shields := 0
## Debugging: with this off, obstacles the shields can't pay for are ignored instead of crashing.
var crash_on_obstacles := true
## Debugging and benchmark: the run starts at this segment instead of at the beginning.
var start_segment := 0.0
## Debugging: with collisions off the ship passes through obstacles (`--ghost` on the command line).
var collisions_enabled := true


static func standard() -> RunConfig:
	return RunConfig.new()
