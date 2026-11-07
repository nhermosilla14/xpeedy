extends SceneTree
## End-to-end check for slice 0008 through the real scene: the first shield spot is painted on the
## track, flying over it gives a shield, the HUD shows the score and the common shield bar, the pick-up flash appears and
## the spot's paint disappears; shields decay with game time.

const SEED := 21
const START_SEGMENT := 90.0

enum Phase { INIT, SETUP, FLY, WATCH, DONE }

var _main: Node
var _phase := Phase.INIT
var _ticks := 0
var _errors: PackedStringArray = []
var _spot: Spot
var _pickup_tick := -1
var _flash_seen := false


func _initialize() -> void:
	_main = load("res://src/main.tscn").instantiate()
	_main.set("countdown_enabled", false)
	_main.set("start_in_menu", false)
	root.add_child(_main)
	_main.set("obstacles_enabled", false)


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	if _phase == Phase.INIT:
		_main.call("start_run", SEED)
		_phase = Phase.SETUP
		_ticks = 0
		return false
	var run: SurvivalRun = _main.get("_run")
	var track := run.track
	var hud: Hud = _main.get_node("Hud/Status")
	var flash: ScreenFlash = _main.get_node("Hud/Flash")
	match _phase:
		Phase.SETUP:
			if _ticks == 1:
				track.segment = START_SEGMENT
				track.elapsed = 5.0
				return false
			if run.spots.all().is_empty():
				_errors.append("no shield spots were generated")
				return _finish()
			_spot = run.spots.all()[0]
			_check_painted(run)
			track.p = 1.0 - (_spot.lane + 0.5) / 8.0
			_phase = Phase.FLY
		Phase.FLY:
			if track.crashed:
				_errors.append("crashed on the way to the spot")
				return _finish()
			if run.shields.count > 0:
				_pickup_tick = _ticks
				_phase = Phase.WATCH
			elif track.segment > _spot.seg + 6:
				_errors.append("flew over the spot at %d without collecting it" % _spot.seg)
				return _finish()
		Phase.WATCH:
			_flash_seen = _flash_seen or flash.current_alpha() > 0.3
			if _ticks < _pickup_tick + 30:
				return false
			if run.shields.count != 1:
				_errors.append("expected one shield, have %d" % run.shields.count)
			if hud.shown_slots != 4:
				_errors.append("HUD bar has %d compartments, expected 4" % hud.shown_slots)
			if hud.shown_score != run.score or run.score <= 0:
				_errors.append("HUD score %d, model score %d" % [hud.shown_score, run.score])
			if not is_equal_approx(hud.shown_level, run.shields.level()):
				_errors.append("HUD bar level %f differs from the model's %f" % [hud.shown_level, run.shields.level()])
			if hud.shown_level < 0.9 or hud.shown_level > 1.0:
				_errors.append("one fresh shield should fill about one compartment, not %f" % hud.shown_level)
			if run.shields.time_left >= run.shields.decay_seconds:
				_errors.append("the decay timer is not running")
			if not _flash_seen:
				_errors.append("no pick-up flash was shown")
			if run.trails.texel(_spot.seg + 1, _spot.lane).a != 0.0:
				_errors.append("the spot is still painted after being collected")
			var texture: TrailTexture = _main.get("_trail_texture")
			if texture.image.get_data() != run.trails.data:
				_errors.append("the trail texture is out of date")
			return _finish()
	if _ticks > 60 * 20:
		_errors.append("timed out in phase %s" % Phase.keys()[_phase])
		return _finish()
	return false


## The spot must be painted in the model's map and in the texture the shader reads.
func _check_painted(run: SurvivalRun) -> void:
	if run.trails.texel(_spot.seg, _spot.lane).a != 1.0:
		_errors.append("the spot is not painted in the trail map")
	var texture: TrailTexture = _main.get("_trail_texture")
	var bytes := texture.image.get_data()
	var index := ((_spot.seg & 63) * 16 + _spot.lane) * 4 + 3
	if bytes[index] != 25:
		_errors.append("the spot is not in the uploaded texture")


func _finish() -> bool:
	for e in _errors:
		print("  FAIL  e2e shields and spots: " + e)
	if _errors.is_empty():
		print("  ok    e2e shields and spots (painted, collected, HUD, flash, decay)")
	quit(1 if not _errors.is_empty() else 0)
	return true
