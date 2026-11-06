class_name RunConfig
extends RefCounted
## Everything a difficulty changes (ADR 0008). Standard is the only preset for now; the other
## difficulties of doc 10 are later presets, not new code paths.

var target_tps := 80.0
## Tests and the benchmark can turn obstacle generation off.
var generate_obstacles := true
## Debugging: with collisions off the ship passes through obstacles (`--ghost` on the command line).
var collisions_enabled := true


static func standard() -> RunConfig:
	return RunConfig.new()
