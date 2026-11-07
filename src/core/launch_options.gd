class_name LaunchOptions
extends RefCounted
## Debug and benchmark options from the command line after `--` (or from `args.txt` on handhelds,
## see the PortMaster launch script). `--benchmark` bundles the settings for a comparable run.

## Pass through obstacles.
var ghost := false
## Obstacles the shields can't pay for are ignored instead of crashing the run.
var invulnerable := false
## Fixed seed, deep start, shields, autopilot, invulnerable, and the run restarts itself after a crash.
var benchmark := false
var shields := 0
## "" for the player, "plough" for the debug pilot.
var autopilot := ""
var timescale := 1.0
## -1 takes the seed from the clock.
var run_seed := -1
var start_segment := 0.0

const BENCHMARK_SEED := 2024
const BENCHMARK_SEGMENT := 2300.0
const BENCHMARK_SHIELDS := 4


static func parse(args: PackedStringArray) -> LaunchOptions:
	var o := LaunchOptions.new()
	if args.has("--benchmark"):
		o.benchmark = true
		o.run_seed = BENCHMARK_SEED
		o.start_segment = BENCHMARK_SEGMENT
		o.shields = BENCHMARK_SHIELDS
		o.autopilot = "plough"
		o.invulnerable = true
	for arg in args:
		var key := arg.get_slice("=", 0)
		var value := arg.get_slice("=", 1) if arg.contains("=") else ""
		match key:
			"--ghost":
				o.ghost = true
			"--invulnerable":
				o.invulnerable = true
			"--shields":
				o.shields = value.to_int()
			"--autopilot":
				o.autopilot = value
			"--timescale":
				o.timescale = value.to_float()
			"--seed":
				o.run_seed = value.to_int()
			"--start-segment":
				o.start_segment = value.to_float()
	return o
