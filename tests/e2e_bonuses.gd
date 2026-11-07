extends SceneTree
## End-to-end check for slices 0026-0028 through the real scene: a Quake spot is picked up and the HUD ring
## shows it; the fire action clears the obstacles ahead and plays the flash; a Time Dilation spot slows the
## game clock and shows the tint, then both return to normal.

enum Phase { INIT, PICKUP, FIRE_QUAKE, DILATE, DONE }

var _main: Node
var _phase := Phase.INIT
var _ticks := 0
var _errors: PackedStringArray = []


func _initialize() -> void:
	_main = load("res://src/main.tscn").instantiate()
	_main.set("countdown_enabled", false)
	_main.set("start_in_menu", false)
	root.add_child(_main)


func _action(name: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = pressed
	Input.parse_input_event(event)


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	var run: SurvivalRun = _main.get("_run")
	var hud: Hud = _main.get_node("Hud/Status")
	var flash: ScreenFlash = _main.get_node("Hud/Flash")
	var tint: ColorRect = _main.get_node("Hud/Tint")
	match _phase:
		Phase.INIT:
			_main.set("obstacles_enabled", true)
			_main.call("start_run", 77)
			_phase = Phase.PICKUP
			_ticks = 0
		Phase.PICKUP:
			if _ticks == 1:
				run.track.segment = 90.0
				run.track.elapsed = 5.0
				run.spots.add(Spot.make(100, 5, Spot.Kind.QUAKE))
				run.track.p = 1.0 - 5.5 / 8.0
			if _ticks == 2:
				for i in 6:
					run.obstacles.add(Obstacle.make(130 + i * 2, (i * 3) % 16, Obstacle.Kind.CUBE, 1))
			if run.held == SurvivalRun.Bonus.QUAKE:
				_phase = Phase.FIRE_QUAKE
				_ticks = 0
			elif _ticks > 120:
				_errors.append("the Quake spot was not picked up")
				return _finish()
		Phase.FIRE_QUAKE:
			if _ticks == 2:
				if hud.shown_held != SurvivalRun.Bonus.QUAKE:
					_errors.append("the HUD ring does not show the held bonus")
				_action("fire", true)
			if _ticks == 5:
				_action("fire", false)
			if _ticks == 10:
				var alive := 0
				for o in run.obstacles.all():
					alive += 1 if o.alive and o.seg < run.track.window_start() + 50 else 0
				if run.held != SurvivalRun.Bonus.NONE or alive != 0:
					_errors.append("the Quake did not clear the obstacles (%d left)" % alive)
				if flash.current_alpha() <= 0.0:
					_errors.append("no Quake flash")
				run.track.crashed = false
				run.held = SurvivalRun.Bonus.TIME_DILATION
				_action("fire", true)
			if _ticks == 14:
				_action("fire", false)
				_phase = Phase.DILATE
				_ticks = 0
		Phase.DILATE:
			if _ticks == 4:
				if not is_equal_approx((_main.get("_clock") as RunClock).scale, 0.75) or not tint.visible:
					_errors.append("Time Dilation did not slow the clock and show the tint")
				run.dilation_left = 0.02
			if _ticks == 20:
				if not is_equal_approx((_main.get("_clock") as RunClock).scale, 1.0) or tint.visible:
					_errors.append("Time Dilation did not end")
				return _finish()
	return false


func _finish() -> bool:
	if _errors.is_empty():
		print("  ok    e2e bonuses (pick-up, ring, Quake, Time Dilation)")
		quit(0)
	else:
		for e in _errors:
			print("  FAIL  e2e bonuses: %s" % e)
		quit(1)
	return true
