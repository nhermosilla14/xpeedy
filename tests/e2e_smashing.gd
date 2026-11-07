extends SceneTree
## End-to-end check for slice 0009 through the real scene. With shields, flying into a cube smashes it:
## the run survives, a shield is spent, points are added, the cube's instance and trail disappear, an
## explosion and the pink flash appear and the HUD bar animates the loss. Without shields the same cube
## is a crash with the white flash.

const Kind := Obstacle.Kind
const CUBE_SEGMENT := 90
const CUBE_LANE := 6
const CUBE_COLOUR := 4

enum Phase { INIT, SMASH_SETUP, SMASH_FLY, SMASH_WATCH, CRASH_SETUP, CRASH_FLY, CRASH_WATCH }

var _main: Node
var _phase := Phase.INIT
var _ticks := 0
var _errors: PackedStringArray = []
var _cube: Obstacle
var _event_tick := -1
var _flash_seen := false
var _explosion_seen := false
var _loss_seen := false
var _centre_at_smash := Vector3.ZERO


func _initialize() -> void:
	_main = load("res://src/main.tscn").instantiate()
	_main.set("countdown_enabled", false)
	_main.set("start_in_menu", false)
	root.add_child(_main)
	_main.set("obstacles_enabled", false)


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	if _phase == Phase.INIT:
		_main.call("start_run", 31)
		_phase = Phase.SMASH_SETUP
		_ticks = 0
		return false
	var run: SurvivalRun = _main.get("_run")
	var track := run.track
	var flash: ScreenFlash = _main.get_node("Hud/Flash")
	var hud: Hud = _main.get_node("Hud/Status")
	var explosions: ExplosionView = _main.get_node("Explosions")
	var obstacles: ObstacleView = _main.get_node("Obstacles")
	match _phase:
		Phase.SMASH_SETUP:
			_setup(run, 2)
			if _ticks > 2:
				_check_trail_before(run)
				_phase = Phase.SMASH_FLY
		Phase.SMASH_FLY:
			if track.crashed:
				_errors.append("crashed although it had two shields")
				return _finish()
			if run.shields.count < 2:
				_event_tick = _ticks
				# The path forgets frames behind the ship, so note where the cube is now.
				_centre_at_smash = track.geometry.surface(CUBE_LANE + 0.5, CUBE_SEGMENT + 0.5)
				_phase = Phase.SMASH_WATCH
			elif track.segment > CUBE_SEGMENT + 4:
				_errors.append("flew through the cube without smashing it")
				return _finish()
		Phase.SMASH_WATCH:
			_flash_seen = _flash_seen or (flash.current_alpha() > 0.4 and flash.color.g < 0.7 and flash.color.r > 0.9)
			_explosion_seen = _explosion_seen or explosions.spawn_count == 1
			_loss_seen = _loss_seen or hud.loss_left > 0.0
			if _ticks < _event_tick + 20:
				return false
			_check_smash(run, obstacles, explosions, hud)
			_main.call("start_run", 32)
			_phase = Phase.CRASH_SETUP
			_ticks = 0
		Phase.CRASH_SETUP:
			_setup(run, 0)
			if _ticks > 2:
				_phase = Phase.CRASH_FLY
		Phase.CRASH_FLY:
			if track.crashed:
				_event_tick = _ticks
				_flash_seen = false
				_phase = Phase.CRASH_WATCH
			elif track.segment > CUBE_SEGMENT + 4:
				_errors.append("flew through the cube without a crash and without shields")
				return _finish()
		Phase.CRASH_WATCH:
			_flash_seen = _flash_seen or (flash.current_alpha() > 0.5 and flash.color.b > 0.9)
			if _ticks < _event_tick + 5:
				return false
			if track.crash_reason != "obstacle":
				_errors.append("crash reason %s" % track.crash_reason)
			if run.shields.count != 0:
				_errors.append("shields changed on a crash")
			if not _flash_seen:
				_errors.append("no white crash flash")
			return _finish()
	if _ticks > 60 * 25:
		_errors.append("timed out in phase %s" % Phase.keys()[_phase])
		return _finish()
	return false


## Tick 1 places the ship and grants shields; on tick 2, once the run has moved its window there, the
## cube is added (its trail would be rejected as too far ahead of the old window).
func _setup(run: SurvivalRun, shields: int) -> void:
	var track := run.track
	if _ticks == 1:
		track.segment = 60.0
		track.elapsed = 5.0
		for i in shields:
			run.shields.add()
		track.p = 1.0 - (CUBE_LANE + 0.5) / 8.0
	elif _ticks == 2:
		_cube = Obstacle.make(CUBE_SEGMENT, CUBE_LANE, Kind.CUBE, CUBE_COLOUR)
		run.obstacles.add(_cube)


func _check_trail_before(run: SurvivalRun) -> void:
	var tile := run.trails.texel(CUBE_SEGMENT - 1, CUBE_LANE)
	if tile.r != float(CUBE_COLOUR):
		_errors.append("the cube has no trail before the smash: %s" % [tile])


func _check_smash(run: SurvivalRun, obstacles: ObstacleView, explosions: ExplosionView, hud: Hud) -> void:
	if run.track.crashed:
		_errors.append("the run ended on a smash")
	if run.shields.count != 1:
		_errors.append("expected 1 shield left, have %d" % run.shields.count)
	if run.score - run.distance_points != 100:
		_errors.append("expected +100 for the cube, got %d" % (run.score - run.distance_points))
	if _cube.alive:
		_errors.append("the cube is still alive")
	if obstacles.instance_counts()[Kind.CUBE] != 0:
		_errors.append("the cube is still in the instance buffer")
	var tile := run.trails.texel(CUBE_SEGMENT, CUBE_LANE)
	if tile.r != -1.0:
		_errors.append("the cube's trail is still painted: %s" % [tile])
	var texture: TrailTexture = _main.get("_trail_texture")
	if texture.image.get_data() != run.trails.data:
		_errors.append("the trail texture is out of date")
	if not _flash_seen:
		_errors.append("no pink smash flash")
	if not _explosion_seen or explosions.last_colour != CUBE_COLOUR:
		_errors.append("no explosion in the cube's colour")
	if explosions.last_origin.distance_to(_centre_at_smash) > 0.5:
		_errors.append("the explosion started %f units from the cube" % explosions.last_origin.distance_to(_centre_at_smash))
	if not _loss_seen:
		_errors.append("the HUD bar did not animate the lost shield")
	if hud.shown_level < 0.9 or hud.shown_level > 1.0:
		_errors.append("HUD bar level %f, expected about 1" % hud.shown_level)


func _finish() -> bool:
	for e in _errors:
		print("  FAIL  e2e smashing: " + e)
	if _errors.is_empty():
		print("  ok    e2e smashing (smashed with shields, crashed without)")
	quit(1 if not _errors.is_empty() else 0)
	return true
