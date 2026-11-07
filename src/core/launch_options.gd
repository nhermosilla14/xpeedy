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
## No obstacles and no shield spots (for looking at the tunnel).
var clean := false
## "in", "flat" or "out": start inside the first part of that shape (for looking at it).
var start_shape := ""
## Save the viewport to this PNG after `screenshot_seconds` and quit (for side-by-side reviews).
var screenshot_path := ""
var screenshot_seconds := 2.0

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
			"--clean":
				o.clean = true
			"--start-shape":
				o.start_shape = value
			"--screenshot":
				o.screenshot_path = value.get_slice(",", 0)
				if value.contains(","):
					o.screenshot_seconds = value.get_slice(",", 1).to_float()
	return o
