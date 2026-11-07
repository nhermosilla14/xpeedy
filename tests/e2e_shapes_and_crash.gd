extends SceneTree
## End-to-end check for slice 0004 through the real scene and input map: the tunnel morphs from
## inside to flat, driving off the flat edge crashes the run, and "restart" starts a new one.

const Shape := PartSequence.Shape
const TIMEOUT_TICKS := 60 * 12

enum Phase { MORPH, STEER_OFF, CRASHED, RESTARTED }

var _main: Node
var _phase := Phase.MORPH
var _ticks := 0
var _errors: PackedStringArray = []
var _turns_seen := {}
var _crash_seed := 0
var _restart_tick := 0


func _initialize() -> void:
	_main = load("res://src/main.tscn").instantiate()
	_main.set("countdown_enabled", false)
	_main.set("start_in_menu", false)
	root.add_child(_main)
	_main.set("obstacles_enabled", false)


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	var track: TrackModel = _main.get("_track")
	match _phase:
		Phase.MORPH:
			if _ticks == 1:
				_place_before_first_flat(track)
				return false
			_turns_seen[snappedf(track.geometry.turn, 0.01)] = true
			if track.current_shape() == Shape.FLAT and not track.is_morphing():
				if track.crashed:
					_errors.append("crashed while driving straight through a morph")
				if _turns_seen.size() < 5:
					_errors.append("tunnel did not morph gradually (%d shapes seen)" % _turns_seen.size())
				if absf(track.geometry.turn) > 0.0001:
					_errors.append("not flat after the morph: turn=%f" % track.geometry.turn)
				Input.action_press("steer_right")
				_phase = Phase.STEER_OFF
		Phase.STEER_OFF:
			if track.crashed:
				Input.action_release("steer_right")
				_crash_seed = track.seed_value
				_phase = Phase.CRASHED
		Phase.CRASHED:
			_send_restart(true)
			_restart_tick = _ticks
			_phase = Phase.RESTARTED
		Phase.RESTARTED:
			if _ticks == _restart_tick + 1:
				_send_restart(false)
			if _ticks < _restart_tick + 3:
				return false
			if track.crashed or track.seed_value == _crash_seed:
				_errors.append("restart did not start a new run")
			if track.segment > 4.0:
				_errors.append("new run did not start at the beginning: %f" % track.segment)
			return _finish()
	if _ticks > TIMEOUT_TICKS:
		_errors.append("timed out in phase %s" % Phase.keys()[_phase])
		return _finish()
	return false


## Moves the ship to 10 segments before the first flat part, already at full speed.
func _place_before_first_flat(track: TrackModel) -> void:
	var i := 1
	while track.parts.shape(i) != Shape.FLAT:
		i += 1
	track.segment = float(track.parts.start(i)) - 10.0
	track.elapsed = 5.0


## Injects a real input event, as a key press would, so "just pressed" is seen by the scene.
func _send_restart(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = "restart"
	event.pressed = pressed
	Input.parse_input_event(event)


func _finish() -> bool:
	for e in _errors:
		print("  FAIL  e2e shapes and crash: " + e)
	if _errors.is_empty():
		print("  ok    e2e shapes and crash (morphed through %d shapes, crashed, restarted)" % _turns_seen.size())
	quit(1 if not _errors.is_empty() else 0)
	return true
