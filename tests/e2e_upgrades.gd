extends SceneTree
## End-to-end check for slices 0040 and 0041 through the real scene: with the three active upgrades bought, a
## stage race shows their buttons; the recharge and torpedo actions and a Phase Shift work and their buttons
## go away; then keep going: an obstacle crash with enough credits asks, yes spends 1 credit and resumes,
## and a second crash goes straight to Game Over.

const ECONOMY := "user://e2e_upgrades_economy.cfg"
const STAGES := "user://e2e_upgrades_stages.cfg"

enum Phase { START, USE, CRASH1, CRASH2, DONE }

var _main: Node
var _phase := Phase.START
var _ticks := 0
var _errors: PackedStringArray = []


func _initialize() -> void:
	_main = load("res://src/main.tscn").instantiate()
	_main.set("options", LaunchOptions.parse(PackedStringArray([])))
	_main.set("obstacles_enabled", false)
	root.add_child(_main)
	for path in [ECONOMY, STAGES]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var economy := Economy.new(ECONOMY)
	economy.earn(500)
	for i in 50:
		economy.race_finished(1, true, false)
	for key in [Upgrade.RECHARGER, Upgrade.TORPEDO, Upgrade.PHASE_SHIFT]:
		economy.buy(key)
	_main.set("_economy", economy)
	_main.set("_progress", StageProgress.new(STAGES))
	_main.get_node("Hud/Menu").set("economy", economy)


func _action(name: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = pressed
	Input.parse_input_event(event)


func _racing(run: SurvivalRun, segment: float) -> void:
	run.phase = SurvivalRun.Phase.RACING
	run.track.ramp_held = false
	run.track.segment = segment
	run.track.elapsed = 5.0
	run.track.p = 1.0 - 7.5 / 8.0


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	var run: SurvivalRun = _main.get("_run")
	var hud: Hud = _main.get_node("Hud/Status")
	var screen: ScreenPanel = _main.get_node("Hud/Screen")
	var economy: Economy = _main.get("_economy")
	match _phase:
		Phase.START:
			if _ticks == 2:
				_main.call("start_race", 1, 1)
				_phase = Phase.USE
				_ticks = 0
		Phase.USE:
			if _ticks == 2:
				if run.config.recharger_level != 1 or run.config.torpedo_level != 1 or run.config.phase_level != 1:
					_errors.append("the bought upgrades are not in the run")
				_racing(run, 100.0)
				run.obstacles.add(Obstacle.make(112, 7, Obstacle.Kind.CUBE, 0))
			if _ticks == 4:
				if not (hud.shown_recharge and hud.shown_torpedo and hud.shown_phase):
					_errors.append("the three buttons are not shown (%s %s %s)" % [hud.shown_recharge, hud.shown_torpedo, hud.shown_phase])
				_action("recharge", true)
				_action("torpedo", true)
			if _ticks == 8:
				_action("recharge", false)
				_action("torpedo", false)
			if _ticks == 50:
				if run.shields.count != 1 or hud.shown_recharge:
					_errors.append("the recharger did not add a shield and hide its button")
				if run.torpedoes_left != 0 or run.obstacles.all()[0].alive:
					_errors.append("the torpedo was not fired or did not destroy the cube")
				run.obstacles.add(Obstacle.make(int(run.track.segment) + 4, 7, Obstacle.Kind.CUBE, 1))
				_main.call("_use_upgrade", "phase")
			if _ticks == 120:
				if run.track.crashed or run.phase_left <= 0.0:
					_errors.append("Phase Shift did not carry the ship through the cube")
				if hud.shown_phase:
					_errors.append("the phase button stays after use")
				_phase = Phase.CRASH1
				_ticks = 0
		Phase.CRASH1:
			if _ticks == 1:
				run.phase_left = 0.0
				run.shields.count = 0
				_racing(run, run.track.segment)
				run.obstacles.add(Obstacle.make(int(run.track.segment) + 3, 7, Obstacle.Kind.CUBE, 2))
			if _ticks == 200:
				if not run.track.crashed or not screen.visible or screen.title != "keep going?":
					_errors.append("no keep going question after an obstacle crash")
				var credits := economy.credits()
				_main.call("_on_choice", 0)
				if economy.credits() != credits - 1 or run.track.crashed:
					_errors.append("yes did not spend 1 credit and resume")
				_phase = Phase.CRASH2
				_ticks = 0
		Phase.CRASH2:
			if _ticks == 2:
				run.obstacles.add(Obstacle.make(int(run.track.segment) + 3, 7, Obstacle.Kind.CUBE, 3))
				run.track.p = 1.0 - 7.5 / 8.0
			if _ticks == 200:
				if not run.track.crashed or not screen.visible or screen.title != "game over":
					_errors.append("the second crash must go straight to Game Over (title '%s')" % screen.title)
				return _finish()
	if _ticks > 400:
		_errors.append("timed out in phase %s" % Phase.keys()[_phase])
		return _finish()
	return false


func _finish() -> bool:
	for path in [ECONOMY, STAGES]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if _errors.is_empty():
		print("  ok    e2e upgrades (buttons, recharge, torpedo, phase shift, keep going)")
		quit(0)
	else:
		for e in _errors:
			print("  FAIL  e2e upgrades: %s" % e)
		quit(1)
	return true
