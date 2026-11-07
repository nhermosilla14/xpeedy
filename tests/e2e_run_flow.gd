extends SceneTree
## End-to-end check for slice 0016 through the real scene: a plain run starts with the lights and the
## countdown, racing then scores; pausing freezes the run and shows the panel; resuming continues; a
## crash shows the Game Over panel with the score and the best after the flash, and "try again" starts a
## new run. The personal best goes to a temporary file.

enum Phase { INIT, COUNTDOWN, RACE, PAUSED, CRASH, DONE }

var _main: Node
var _phase := Phase.INIT
var _ticks := 0
var _errors: PackedStringArray = []
var _frozen_segment := 0.0
var _seed := 0


func _initialize() -> void:
	_main = load("res://src/main.tscn").instantiate()
	_main.set("start_in_menu", false)
	_main.set("options", LaunchOptions.parse(PackedStringArray(["--seed=44", "--difficulty=extreme"])))
	root.add_child(_main)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://e2e_economy.cfg"))
	var economy := Economy.new("user://e2e_economy.cfg")
	_main.set("_economy", economy)
	_main.get_node("Hud/Menu").set("economy", economy)


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	var run: SurvivalRun = _main.get("_run")
	var track := run.track
	var screen: ScreenPanel = _main.get_node("Hud/Screen")
	var lights: StartLights = _main.get_node("Hud/Lights")
	match _phase:
		Phase.INIT:
			_main.set("_best", PersonalBest.new("user://e2e_best.cfg"))
			_main.call("start_run", 44)
			_seed = 44
			_phase = Phase.COUNTDOWN
			_ticks = 0
		Phase.COUNTDOWN:
			if _ticks == 30:
				if run.phase != SurvivalRun.Phase.STARTING or not lights.visible:
					_errors.append("the start sequence is not running")
				if run.score != 0:
					_errors.append("score during the countdown")
			if run.phase == SurvivalRun.Phase.RACING:
				_phase = Phase.RACE
				_ticks = 0
			elif _ticks > 400:
				_errors.append("the countdown never ended")
				return _finish()
		Phase.RACE:
			if _ticks == 1 and lights.visible:
				_errors.append("lights still visible when racing")
			if _ticks == 1 and run.config.target_tps != 67.0:
				_errors.append("the run is not at the extreme speed")
			if _ticks == 90:
				if run.score <= 0:
					_errors.append("no score while racing")
				_main.call("_toggle_pause")
				if not screen.visible or screen.choices.size() != 3:
					_errors.append("the pause panel did not open")
				_main.call("_physics_process", 0.0)
				screen.move_selection(1)
				if screen.selected != 1:
					_errors.append("the selection did not move")
				screen.move_selection(-1)
				_frozen_segment = track.segment
				_phase = Phase.PAUSED
				_ticks = 0
		Phase.PAUSED:
			if _ticks == 30:
				if track.segment != _frozen_segment:
					_errors.append("the run moved while paused")
				_main.call("_toggle_pause")
				if screen.visible:
					_errors.append("the pause panel did not close")
			if _ticks == 60:
				if track.segment <= _frozen_segment:
					_errors.append("the run did not continue after resuming")
				track.crash("wall")
				_phase = Phase.CRASH
				_ticks = 0
		Phase.CRASH:
			if _ticks == 20 and screen.visible:
				_errors.append("the Game Over panel showed before the flash ended")
			if _ticks == 90:
				if not screen.visible or screen.title != "game over":
					_errors.append("no Game Over panel after the crash")
				elif not screen.lines[0].begins_with("score: ") or not screen.lines[1].begins_with("personal best: "):
					_errors.append("Game Over lines are wrong: %s" % [screen.lines])
				var best: PersonalBest = _main.get("_best")
				if best.get_best("survival_extreme") <= 0:
					_errors.append("the best was not saved under the extreme key")
				_main.call("_on_choice", 0)
				if (_main.get("_track") as TrackModel).crashed or (_main.get("_track") as TrackModel).seed_value == _seed:
					_errors.append("try again did not start a new run")
				return _finish()
	return false


func _finish() -> bool:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://e2e_economy.cfg"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://e2e_best.cfg"))
	if _errors.is_empty():
		print("  ok    e2e run flow (lights, countdown, pause, game over)")
		quit(0)
	else:
		for e in _errors:
			print("  FAIL  e2e run flow: %s" % e)
		quit(1)
	return true
