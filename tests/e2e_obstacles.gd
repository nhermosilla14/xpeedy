extends SceneTree
## End-to-end check for slice 0006 through the real scene: the first obstacle appears where the model
## says, the instance buffers match the model, flying into the obstacle crashes (and restart works),
## and steering around the obstacles survives past them.

const Kind := Obstacle.Kind
const MAX_TICKS := 60 * 30
const START_SEGMENT := 48.0

enum Phase { INIT, HIT_SETUP, HIT_FLY, RESTART, DODGE_SETUP, DODGE_FLY }

var _main: Node
var _phase := Phase.INIT
var _ticks := 0
var _errors: PackedStringArray = []
var _first_seed := 0
var _restart_tick := 0
var _checked_instances := false


func _initialize() -> void:
	_main = load("res://src/main.tscn").instantiate()
	_main.set("countdown_enabled", false)
	_main.set("start_in_menu", false)
	root.add_child(_main)
	_first_seed = 11


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	if _phase == Phase.INIT:
		# The scene's own _ready has run by now; start a run with a known seed.
		_main.call("start_run", _first_seed)
		_phase = Phase.HIT_SETUP
		_ticks = 0
		return false
	var run: SurvivalRun = _main.get("_run")
	var track: TrackModel = run.track
	match _phase:
		Phase.HIT_SETUP:
			if _ticks == 1:
				track.segment = START_SEGMENT
				track.elapsed = 5.0
				return false
			var first := run.obstacles.at_segment(55)
			if first.is_empty():
				_errors.append("no obstacle at segment 55")
				return _finish()
			_check_instances(run)
			track.p = 1.0 - (first[0].lane + 0.5) / 8.0
			_phase = Phase.HIT_FLY
		Phase.HIT_FLY:
			if track.crashed:
				if track.crash_reason != "obstacle":
					_errors.append("crashed for the wrong reason: %s" % track.crash_reason)
				if track.segment < 54.0 or track.segment > 56.5:
					_errors.append("crashed at segment %f, expected about 54.4" % track.segment)
				_send_restart(true)
				_restart_tick = _ticks
				_phase = Phase.RESTART
		Phase.RESTART:
			if _ticks == _restart_tick + 1:
				_send_restart(false)
			if _ticks < _restart_tick + 3:
				return false
			if track.crashed or track.seed_value == _first_seed:
				_errors.append("restart did not start a new run")
			_phase = Phase.DODGE_SETUP
			_ticks = 0
		Phase.DODGE_SETUP:
			if _ticks == 1:
				track.segment = START_SEGMENT
				track.elapsed = 5.0
				return false
			var lane := _free_lane(run)
			if lane < 0.0:
				_errors.append("no free lane found")
				return _finish()
			track.p = 1.0 - lane / 8.0
			_phase = Phase.DODGE_FLY
		Phase.DODGE_FLY:
			if track.crashed:
				_errors.append("crashed at segment %f while steering around obstacles" % track.segment)
				return _finish()
			if track.segment > 96.0:
				return _finish()
	if _ticks > MAX_TICKS:
		_errors.append("timed out in phase %s" % Phase.keys()[_phase])
		return _finish()
	return false


## Lane position (a lane centre) clear of every obstacle between segments 50 and 100, with margin.
func _free_lane(run: SurvivalRun) -> float:
	for lane in 16:
		var centre := lane + 0.5
		var clear := true
		for o in run.obstacles.all():
			if o.seg < 50 or o.seg > 100:
				continue
			var lanes := [o.lane]
			if o.is_tube_beam():
				lanes.append((o.lane + 8) % 16)
			for l in lanes:
				var d := absf(centre - (l + 0.5))
				d = minf(d, 16.0 - d)
				if d < 1.6:
					clear = false
		if clear:
			return centre
	return -1.0


func _check_instances(run: SurvivalRun) -> void:
	var view: ObstacleView = _main.get_node("Obstacles")
	var counts := view.instance_counts()
	var expected := [0, 0, 0]
	for o in run.obstacles.all():
		expected[o.kind] += 1
	if counts != expected:
		_errors.append("instance counts %s differ from the model %s" % [counts, expected])
	if expected[Kind.CUBE] + expected[Kind.BEAM] < 3:
		_errors.append("expected several obstacles in the horizon, got %s" % [expected])
	var first := run.obstacles.at_segment(55)[0]
	var data := view.instance_data(first.kind)
	var found := false
	for i in counts[first.kind]:
		var base := i * ObstacleView.FLOATS_PER_INSTANCE
		if int(data[base + 12]) == first.lane and int(data[base + 13]) == first.seg \
				and int(data[base + 14]) == first.colour and data[base + 15] == 1.0:
			found = true
	if not found:
		_errors.append("the obstacle at 55 is missing from the instance buffer")
	_check_trails(run, first)
	_checked_instances = true


## The trail texture the shader reads must hold the model's trail map, with the first obstacle's trail.
func _check_trails(run: SurvivalRun, first: Obstacle) -> void:
	var texture: TrailTexture = _main.get("_trail_texture")
	if texture.image.get_data() != run.trails.data:
		_errors.append("the trail texture differs from the model's trail map")
	var tile := run.trails.texel(first.seg - 3, first.lane)
	if tile.r != float(first.colour) or tile.g != float(first.seg):
		_errors.append("no trail towards the obstacle at 55: %s" % [tile])
	var tunnel: TunnelView = _main.get_node("Tunnel")
	if tunnel.material.get_shader_parameter("trail_tex") != texture.texture:
		_errors.append("the tunnel material does not use the trail texture")


func _send_restart(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = "restart"
	event.pressed = pressed
	Input.parse_input_event(event)


func _finish() -> bool:
	if not _checked_instances:
		_errors.append("instance buffer was never checked")
	for e in _errors:
		print("  FAIL  e2e obstacles: " + e)
	if _errors.is_empty():
		print("  ok    e2e obstacles (hit and crashed, restarted, then steered around them)")
	quit(1 if not _errors.is_empty() else 0)
	return true
