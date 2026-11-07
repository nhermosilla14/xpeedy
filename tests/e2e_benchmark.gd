extends SceneTree
## End-to-end check for slice 0011: `--benchmark` through the real scene starts a run deep at level 15 with
## shields and the autopilot, keeps flying and smashing for several seconds, restarts itself after a
## crash, and the frame log shows how dense the track is (level 15 or more).

const TICKS := 60 * 12

var _main: Node
var _ticks := 0
var _errors: PackedStringArray = []
var _first_seed := 0
var _smashes := 0
var _crashed_ticks := 0
var _longest_crash := 0
var _restarts := 0
var _last_seed := 0


func _initialize() -> void:
	_main = load("res://src/main.tscn").instantiate()
	_main.set("countdown_enabled", false)
	_main.set("start_in_menu", false)
	_main.set("options", LaunchOptions.parse(PackedStringArray(["--benchmark"])))
	root.add_child(_main)


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	var run: SurvivalRun = _main.get("_run")
	if run == null:
		return false
	var track := run.track
	if _ticks == 1:
		_first_seed = track.seed_value
		_last_seed = track.seed_value
		if _first_seed != LaunchOptions.BENCHMARK_SEED:
			_errors.append("the benchmark seed is %d, expected %d" % [_first_seed, LaunchOptions.BENCHMARK_SEED])
		if track.segment < 2300.0:
			_errors.append("the benchmark did not start deep: segment %f" % track.segment)
		if run.shields.count < 1:
			_errors.append("no starting shields")
	if track.seed_value != _last_seed:
		_restarts += 1
		_last_seed = track.seed_value
		if track.segment < 2300.0:
			_errors.append("a restart did not start deep again: segment %f" % track.segment)
	if track.crashed:
		_crashed_ticks += 1
		_longest_crash = maxi(_longest_crash, _crashed_ticks)
	else:
		_crashed_ticks = 0
	if run.score - run.distance_points > 0:
		_smashes += 1
	if _ticks < TICKS:
		return false
	var explosions: ExplosionView = _main.get_node("Explosions")
	if _smashes == 0 and explosions.spawn_count == 0:
		_errors.append("the autopilot smashed nothing in %d ticks" % TICKS)
	if _longest_crash > 120:
		_errors.append("a crash was not restarted for %d ticks" % _longest_crash)
	var stats: FrameStats = _main.get_node("FrameStats")
	var text := stats.summary()
	for part in ["segment=", "level=", "obstacles=", "shields=", "score="]:
		if not text.contains(part):
			_errors.append("the benchmark log line lacks '%s': %s" % [part, text])
	var level := text.get_slice("level=", 1).get_slice(" ", 0).to_int()
	if level < 15:
		_errors.append("the benchmark should run at level 15 or more, not %d" % level)
	for e in _errors:
		print("  FAIL  e2e benchmark: " + e)
	if _errors.is_empty():
		print("  ok    e2e benchmark (deep start, flew %d ticks, %d restarts, %s)" % [TICKS, _restarts, text.get_slice("|", 1).strip_edges()])
	quit(1 if not _errors.is_empty() else 0)
	return true
