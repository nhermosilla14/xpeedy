extends SceneTree
## End-to-end check for slice 0010 through the real scene: deep into a run (segment 2300, pattern level
## 15) the generator has produced the full catalogue and the instance buffers hold it, and the ship,
## with shields, smashes a spike for +100.

const Kind := Obstacle.Kind
const DEEP_SEGMENT := 2300.0
const SEEDS := [41, 42, 43, 44, 45, 46]

enum Phase { INIT, GENERATE, FLY }

var _main: Node
var _phase := Phase.INIT
var _ticks := 0
var _seed_index := 0
var _errors: PackedStringArray = []
var _spike: Obstacle
var _shields_before := 0


func _initialize() -> void:
	_main = load("res://src/main.tscn").instantiate()
	_main.set("countdown_enabled", false)
	_main.set("start_in_menu", false)
	root.add_child(_main)


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	if _phase == Phase.INIT:
		_start_deep_run()
		return false
	var run: SurvivalRun = _main.get("_run")
	var track := run.track
	match _phase:
		Phase.GENERATE:
			_spike = _find_clear_spike(run)
			if _spike == null:
				_seed_index += 1
				if _seed_index >= SEEDS.size():
					_errors.append("no spike with a clear approach in any of the seeds")
					return _finish()
				_start_deep_run()
				return false
			_check_catalogue(run)
			_shields_before = run.shields.count
			track.segment = _spike.seg - 8.0
			track.p = 1.0 - (_spike.lane + 0.5) / 8.0
			_phase = Phase.FLY
		Phase.FLY:
			if track.crashed:
				_errors.append("crashed on the way to the spike at %d (%s)" % [_spike.seg, track.crash_reason])
				return _finish()
			if not _spike.alive:
				if run.shields.count != _shields_before - 1:
					_errors.append("a spike should cost one shield")
				if run.score - run.distance_points != 100:
					_errors.append("a spike should give +100, got %d" % (run.score - run.distance_points))
				return _finish()
			if track.segment > _spike.seg + 2:
				_errors.append("flew past the spike without smashing it")
				return _finish()
	if _ticks > 60 * 30:
		_errors.append("timed out")
		return _finish()
	return false


## Starts a run with the next seed and jumps deep into it, so the generator fills in everything before.
func _start_deep_run() -> void:
	_main.call("start_run", SEEDS[_seed_index])
	var run: SurvivalRun = _main.get("_run")
	run.track.segment = DEEP_SEGMENT
	run.track.elapsed = 5.0
	for i in 3:
		run.shields.add()
	_phase = Phase.GENERATE
	_ticks = 0


## A spike whose lane is free of other obstacles on the way in, so the test isolates the smash.
func _find_clear_spike(run: SurvivalRun) -> Obstacle:
	for o in run.obstacles.all():
		if o.kind != Kind.SPIKE or o.seg < DEEP_SEGMENT + 12:
			continue
		var clear := true
		for other in run.obstacles.all():
			if other == o or other.seg < o.seg - 9 or other.seg > o.seg + 1:
				continue
			var touches := other.lane == o.lane or (other.is_tube_beam() and (other.lane + 8) % 16 == o.lane)
			if touches:
				clear = false
		if clear and run.track.parts.shape_at(o.seg - 9) == run.track.parts.shape_at(o.seg):
			return o
	return null


func _check_catalogue(run: SurvivalRun) -> void:
	var field := run.obstacles
	if field.placed_points.size() < 150:
		_errors.append("only %d patterns were generated up to segment 2300" % field.placed_points.size())
	if ObstacleField.level_at(field.placed_points[field.placed_points.size() - 1]) < 15:
		_errors.append("the last pattern is not at level 15")
	var counts := [0, 0, 0]
	for o in field.all():
		counts[o.kind] += 1
	if counts[Kind.CUBE] == 0 or counts[Kind.BEAM] == 0 or counts[Kind.SPIKE] == 0:
		_errors.append("expected cubes, beams and spikes ahead: %s" % [counts])
	var obstacles: ObstacleView = _main.get_node("Obstacles")
	if obstacles.instance_counts() != counts:
		_errors.append("instance counts %s differ from the model %s" % [obstacles.instance_counts(), counts])


func _finish() -> bool:
	for e in _errors:
		print("  FAIL  e2e patterns: " + e)
	if _errors.is_empty():
		print("  ok    e2e patterns (deep run generated the catalogue, spike smashed for +100)")
	quit(1 if not _errors.is_empty() else 0)
	return true
