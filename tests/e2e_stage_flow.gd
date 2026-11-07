extends SceneTree
## End-to-end check for slice 0036 through the real scene: play, single, the stage list with locks, stage 1
## starts race 1 with its label; finishing opens "run finished" and "next run" starts race 2 with the running
## score; a crash opens Game Over and "new game" retries the same race; a completed stage asks before it
## restarts; the last race opens "stage finished".

enum Phase { MENU, RACE1, FINISH1, NEXT, CRASH, RETRY, RESTART, LAST, DONE }

const PATH := "user://e2e_stage_flow.cfg"

var _main: Node
var _phase := Phase.MENU
var _ticks := 0
var _errors: PackedStringArray = []


func _initialize() -> void:
	_main = load("res://src/main.tscn").instantiate()
	_main.set("options", LaunchOptions.parse(PackedStringArray([])))
	_main.set("obstacles_enabled", false)
	root.add_child(_main)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://e2e_economy.cfg"))
	var economy := Economy.new("user://e2e_economy.cfg")
	_main.set("_economy", economy)
	_main.get_node("Hud/Menu").set("economy", economy)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var progress := StageProgress.new(PATH)
	_main.set("_progress", progress)
	_main.get_node("Hud/Menu").set("progress", progress)


func _action(name: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = pressed
	Input.parse_input_event(event)


func _force_racing(run: SurvivalRun, segment: float) -> void:
	run.phase = SurvivalRun.Phase.RACING
	run.track.ramp_held = false
	run.track.segment = segment
	run.track.elapsed = 5.0
	run.track.p = 1.0 - 7.5 / 8.0


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	var menu: MenuController = _main.get_node("Hud/Menu")
	var screen: ScreenPanel = _main.get_node("Hud/Screen")
	var label: Label = _main.get_node("Hud/RaceLabel")
	var progress: StageProgress = _main.get("_progress")
	var run: SurvivalRun = _main.get("_run")
	match _phase:
		Phase.MENU:
			if _ticks == 2:
				menu.activate()
				menu.activate()
				if menu.current_page() != MenuController.Page.STAGES or menu.page_item_texts().size() != 4:
					_errors.append("single did not open four stages: %s" % [menu.page_item_texts()])
				menu.move(1)
				menu.activate()
				if menu.current_page() != MenuController.Page.STAGES or _main.get("_run") != null:
					_errors.append("a locked stage was started")
				menu.move(-1)
				menu.activate()
				_phase = Phase.RACE1
				_ticks = 0
		Phase.RACE1:
			if _ticks == 2:
				if run == null or _main.get("stage") != 1 or _main.get("race") != 1:
					_errors.append("stage 1 did not start race 1")
					return _finish()
				if not label.visible or label.text != "stage 01 / run 01":
					_errors.append("the race label is wrong: '%s'" % label.text)
				_force_racing(run, 495.0)
				_phase = Phase.FINISH1
				_ticks = 0
		Phase.FINISH1:
			if _ticks == 100:
				if not run.finished or progress.done(1) != 1:
					_errors.append("race 1 did not finish and save")
				if not screen.visible or screen.title != "run finished" or screen.choices.size() != 2:
					_errors.append("no 'run finished' panel")
				_main.call("_on_choice", 0)
				_phase = Phase.NEXT
				_ticks = 0
		Phase.NEXT:
			if _ticks == 2:
				if _main.get("race") != 2 or run.score != progress.score(1) or run.finished:
					_errors.append("'next run' did not start race 2 with the running score")
				run.obstacles.add(Obstacle.make(int(run.track.segment) + 3, 7, Obstacle.Kind.CUBE, 0))
				_force_racing(run, 100.0)
				run.obstacles.add(Obstacle.make(103, 7, Obstacle.Kind.CUBE, 0))
				_phase = Phase.CRASH
				_ticks = 0
		Phase.CRASH:
			if _ticks == 150:
				if not run.track.crashed or not screen.visible or screen.title != "game over":
					_errors.append("no Game Over panel after the crash")
				if progress.score(1) != 0 or progress.done(1) != 1:
					_errors.append("the crash did not reset the score and keep the progress")
				_main.call("_on_choice", 0)
				_phase = Phase.RETRY
				_ticks = 0
		Phase.RETRY:
			if _ticks == 2:
				if _main.get("race") != 2 or (_main.get("_run") as SurvivalRun).track.crashed or (_main.get("_run") as SurvivalRun).score != 0:
					_errors.append("'new game' did not retry race 2 from 0")
				for race in range(1, 13):
					progress.finish_race(1, race, 1000)
				_main.call("enter_menu", MenuController.Page.STAGES)
				menu.activate()
				if menu.current_page() != MenuController.Page.RESTART:
					_errors.append("a completed stage did not ask about restarting")
				menu.move(1)
				menu.activate()
				if menu.current_page() != MenuController.Page.STAGES:
					_errors.append("'keep it' did not go back")
				menu.activate()
				menu.move(-1)
				menu.activate()
				_phase = Phase.RESTART
				_ticks = 0
		Phase.RESTART:
			if _ticks == 2:
				if progress.done(1) != 0 or _main.get("race") != 1 or _main.get("stage") != 1:
					_errors.append("restarting did not reset the stage and start race 1")
				_main.call("start_race", 1, 12)
				_phase = Phase.LAST
				_ticks = 0
		Phase.LAST:
			if _ticks == 2:
				_force_racing(_main.get("_run"), 1550.0 if false else float((_main.get("_run") as SurvivalRun).config.run_length - 5))
			if _ticks == 100:
				if not screen.visible or screen.title != "stage finished" or screen.choices.size() != 1:
					_errors.append("no 'stage finished' panel")
				_action("ui_accept", true)
			if _ticks == 110:
				_action("ui_accept", false)
			if _ticks == 130:
				if not (_main.get("_in_menu") as bool) or menu.current_page() != MenuController.Page.MAIN:
					_errors.append("'main menu' on the stage finished panel did not return to the menu")
				return _finish()
	if _ticks > 400:
		_errors.append("timed out in phase %s" % Phase.keys()[_phase])
		return _finish()
	return false


func _finish() -> bool:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://e2e_economy.cfg"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	if _errors.is_empty():
		print("  ok    e2e stage flow (stages, locks, race label, finished and game over panels, restart)")
		quit(0)
	else:
		for e in _errors:
			print("  FAIL  e2e stage flow: %s" % e)
		quit(1)
	return true
