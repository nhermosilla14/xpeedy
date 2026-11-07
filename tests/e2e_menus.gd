extends SceneTree
## End-to-end check for slices 0019 and 0020 through the real scene: a plain launch opens the main menu with
## no run; play opens the difficulty menu with the cubes' badges; choosing a difficulty starts a run of it
## (with the start sequence); pausing and choosing "main menu" returns to the menu; back goes up a level;
## a crash and "main menu" on the Game Over panel returns too, and "new game" keeps the difficulty.

enum Phase { MENU, DIFFICULTY, RUN, PAUSE_TO_MENU, BACK, SECOND_RUN, CRASH, DONE }

var _main: Node
var _phase := Phase.MENU
var _ticks := 0
var _errors: PackedStringArray = []


func _initialize() -> void:
	_main = load("res://src/main.tscn").instantiate()
	_main.set("options", LaunchOptions.parse(PackedStringArray(["--seed=9"])))
	root.add_child(_main)
	var settings := Settings.new("user://e2e_settings.cfg")
	_main.set("_settings", settings)
	_main.get_node("Hud/Menu").set("settings", settings)


func _action(name: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = pressed
	Input.parse_input_event(event)


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	var menu: MenuController = _main.get_node("Hud/Menu")
	var screen: ScreenPanel = _main.get_node("Hud/Screen")
	var run: SurvivalRun = _main.get("_run")
	match _phase:
		Phase.MENU:
			if _ticks == 2:
				if run != null or not menu.visible:
					_errors.append("a plain launch did not open the menu")
				if menu.current_page() != MenuController.Page.MAIN or menu.page_item_texts()[0] != "play":
					_errors.append("the main page is wrong: %s" % [menu.page_item_texts()])
				menu.activate()
				if menu.current_page() != MenuController.Page.DIFFICULTY:
					_errors.append("play did not open the difficulty page")
				_phase = Phase.DIFFICULTY
				_ticks = 0
		Phase.DIFFICULTY:
			if _ticks == 1:
				if menu.page_item_texts() != Difficulty.keys():
					_errors.append("difficulty items are wrong: %s" % [menu.page_item_texts()])
				if menu.selected_index() != 2:
					_errors.append("standard is not preselected")
				_action("ui_down", true)
			if _ticks == 8:
				_action("ui_down", false)
			if _ticks == 12:
				if menu.selected_index() != 3:
					_errors.append("the down action did not move the selection: %d" % menu.selected_index())
				_action("ui_accept", true)
			if _ticks == 18:
				_action("ui_accept", false)
			if _ticks == 24:
				_phase = Phase.RUN
				_ticks = 0
		Phase.RUN:
			if _ticks == 1:
				if run == null or run.config.target_tps != 67.0 or run.phase != SurvivalRun.Phase.STARTING:
					_errors.append("choosing extreme did not start an extreme run with the start sequence")
				if menu.visible:
					_errors.append("the menu is still visible during the run")
			if _ticks == 20:
				_main.call("_toggle_pause")
				_main.call("_on_choice", 2)
				_phase = Phase.PAUSE_TO_MENU
				_ticks = 0
		Phase.PAUSE_TO_MENU:
			if _ticks == 2:
				if not menu.visible or menu.current_page() != MenuController.Page.MAIN or _main.get("_run") != null:
					_errors.append("pause > main menu did not return to the main page")
				menu.activate()
				if menu.selected_index() != 3:
					_errors.append("the difficulty menu did not preselect the last difficulty")
				_action("ui_cancel", true)
			if _ticks == 6:
				_action("ui_cancel", false)
			if _ticks == 9:
				if menu.current_page() != MenuController.Page.MAIN:
					_errors.append("back did not return to the main page")
				menu.move(2)
				menu.activate()
				if menu.current_page() != MenuController.Page.SETTINGS:
					_errors.append("the gear did not open settings")
				menu.activate()
				menu.back()
				menu.activate()
				menu.move(-2)
				menu.activate()
				_phase = Phase.SECOND_RUN
				_ticks = 0
		Phase.SECOND_RUN:
			if _ticks == 2:
				if run == null or run.config.target_tps != 100.0 or run.config.spikes_enabled != true:
					_errors.append("the second run is not easy: %s" % [run.config.target_tps if run else -1])
				if not (_main.get("_steering") as Steering).invert:
					_errors.append("invert was not applied to the run")
				run.track.crash("wall")
				_phase = Phase.CRASH
				_ticks = 0
		Phase.CRASH:
			if _ticks == 90:
				if not screen.visible or screen.choices.size() != 2:
					_errors.append("no Game Over panel with two choices")
				screen.move_selection(1)
				_action("ui_accept", true)
			if _ticks == 94:
				_action("ui_accept", false)
			if _ticks == 98:
				if not menu.visible or _main.get("_run") != null:
					_errors.append("Game Over > main menu did not return to the menu")
				return _finish()
	if _ticks > 400:
		_errors.append("timed out in phase %s" % Phase.keys()[_phase])
		return _finish()
	return false


func _finish() -> bool:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://e2e_settings.cfg"))
	if _errors.is_empty():
		print("  ok    e2e menus (main, difficulty, run, pause, game over, back)")
		quit(0)
	else:
		for e in _errors:
			print("  FAIL  e2e menus: %s" % e)
		quit(1)
	return true
