extends SceneTree
## End-to-end check for slice 0035 through the real scene: race 1-1 is started, the ship is moved close to the
## finish, the race finishes with the light-green flash, the run stops and the progress and score are saved;
## then race 1-2 is crashed and the running score resets while the progress stays.

enum Phase { INIT, FINISH, STOPPED, CRASH, DONE }

const PATH := "user://e2e_stages.cfg"

var _main: Node
var _phase := Phase.INIT
var _ticks := 0
var _errors: PackedStringArray = []
var _stopped_at := 0.0


func _initialize() -> void:
	_main = load("res://src/main.tscn").instantiate()
	_main.set("countdown_enabled", false)
	_main.set("start_in_menu", false)
	_main.set("obstacles_enabled", false)
	root.add_child(_main)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://e2e_economy.cfg"))
	var economy := Economy.new("user://e2e_economy.cfg")
	_main.set("_economy", economy)
	_main.get_node("Hud/Menu").set("economy", economy)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	_main.set("_progress", StageProgress.new(PATH))


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	var run: SurvivalRun = _main.get("_run")
	var progress: StageProgress = _main.get("_progress")
	var flash: ScreenFlash = _main.get_node("Hud/Flash")
	match _phase:
		Phase.INIT:
			_main.call("start_race", 1, 1)
			_phase = Phase.FINISH
			_ticks = 0
		Phase.FINISH:
			if _ticks == 1:
				if run.config.run_length != 500 or not is_equal_approx(run.config.target_tps, 130.0 * 0.87):
					_errors.append("race 1-1 was not built from its file")
				run.track.segment = 490.0
				run.track.elapsed = 5.0
				run.track.p = 1.0 - 7.5 / 8.0
			if run.finished:
				if flash.current_alpha() <= 0.0:
					_errors.append("no finish flash")
				if progress.done(1) != 1 or progress.score(1) <= 0:
					_errors.append("the finished race was not saved (done %d, score %d)" % [progress.done(1), progress.score(1)])
				_stopped_at = run.track.segment
				_phase = Phase.STOPPED
				_ticks = 0
			elif _ticks > 600:
				_errors.append("the race never finished")
				return _finish()
		Phase.STOPPED:
			if _ticks == 30:
				if run.track.segment != _stopped_at:
					_errors.append("the ship kept moving after the finish")
				_main.call("start_race", 1, 2)
				_phase = Phase.CRASH
				_ticks = 0
		Phase.CRASH:
			if _ticks == 2:
				if (_main.get("_run") as SurvivalRun).score != progress.score(1):
					_errors.append("race 2 did not start with the running score")
				var crash_run: SurvivalRun = _main.get("_run")
				crash_run.track.p = 1.0 - 7.5 / 8.0
				crash_run.obstacles.add(Obstacle.make(int(crash_run.track.segment) + 3, 7, Obstacle.Kind.CUBE, 0))
			if _ticks == 40:
				if progress.score(1) != 0 or progress.done(1) != 1:
					_errors.append("a crash must reset the score and keep the progress")
				return _finish()
	return false


func _finish() -> bool:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://e2e_economy.cfg"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	if _errors.is_empty():
		print("  ok    e2e races (finish, flash, stop, saved progress, crash resets the score)")
		quit(0)
	else:
		for e in _errors:
			print("  FAIL  e2e races: %s" % e)
		quit(1)
	return true
