extends SceneTree
## End-to-end check for slices 0029-0032 through the real scene: a Hue Shift mark is crossed, the banner shows
## the warning and counts down, the zone starts (the global uniform changes), a Space Fold ends it; then a
## Plasma Cloud vortex is touched and flashes.

enum Phase { INIT, COUNTDOWN, ACTIVE, FOLD, PLASMA, DONE }

var _main: Node
var _phase := Phase.INIT
var _ticks := 0
var _errors: PackedStringArray = []


func _initialize() -> void:
	_main = load("res://src/main.tscn").instantiate()
	_main.set("countdown_enabled", false)
	_main.set("start_in_menu", false)
	_main.set("obstacles_enabled", false)
	root.add_child(_main)


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	var run: SurvivalRun = _main.get("_run")
	var banner: Label = _main.get_node("Hud/Banner")
	var flash: ScreenFlash = _main.get_node("Hud/Flash")
	match _phase:
		Phase.INIT:
			_main.call("start_run", 55)
			_phase = Phase.COUNTDOWN
			_ticks = 0
		Phase.COUNTDOWN:
			if _ticks == 1:
				run.track.segment = 90.0
				run.track.elapsed = 5.0
				var mark := ZoneField.Mark.new()
				mark.seg = 100
				mark.zone = Zone.Kind.HUE_SHIFT
				run.zones.add(mark)
			if run.zone_state == SurvivalRun.ZoneState.COUNTDOWN:
				if not banner.visible or not banner.text.contains("hue shift"):
					_errors.append("the banner does not show the zone: '%s'" % banner.text)
				if flash.current_alpha() <= 0.0:
					_errors.append("no warning flash")
				_phase = Phase.ACTIVE
				_ticks = 0
			elif _ticks > 200:
				_errors.append("the mark was not crossed")
				return _finish()
		Phase.ACTIVE:
			if run.zone_state == SurvivalRun.ZoneState.ACTIVE:
				if banner.visible:
					_errors.append("the banner stays during the zone")
				if _main.get_node("Environment").environment.fog_density > 0.31:
					_errors.append("the fog is not lighter in Hue Shift")
				run.held = SurvivalRun.Bonus.SPACE_FOLD
				run.fire()
				_phase = Phase.FOLD
				_ticks = 0
			elif _ticks > 400:
				_errors.append("the zone never started")
				return _finish()
		Phase.FOLD:
			if _ticks == 3:
				if run.zone_state != SurvivalRun.ZoneState.IDLE:
					_errors.append("Space Fold did not end the zone")
				run.start_zone_now(Zone.Kind.PLASMA_CLOUD)
				run.shields.add()
				run.vortices.append(Vector2i(int(run.track.segment) + 3, 5))
				run.track.p = 1.0 - 5.5 / 8.0
				_phase = Phase.PLASMA
				_ticks = 0
		Phase.PLASMA:
			if run.shields.count == 0:
				if flash.current_alpha() <= 0.0:
					_errors.append("no plasma flash")
				if not (_main.get_node("Hud/Glow") as ColorRect).visible:
					_errors.append("no plasma glow")
				return _finish()
			elif _ticks > 120:
				_errors.append("the vortex was not touched")
				return _finish()
	return false


func _finish() -> bool:
	if _errors.is_empty():
		print("  ok    e2e zones (mark, banner, Hue Shift, Space Fold, plasma)")
		quit(0)
	else:
		for e in _errors:
			print("  FAIL  e2e zones: %s" % e)
		quit(1)
	return true
