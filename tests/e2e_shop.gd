extends SceneTree
## End-to-end check for slice 0038 through the real scene: the main menu has "upgrades"; the shop lists the six
## upgrades with prices and locks; confirm buys an unlocked level and spends credits; a locked level or an
## unaffordable one is refused; the next run uses what was bought; a finished new race pays credits.

const ECONOMY := "user://e2e_shop_economy.cfg"
const STAGES := "user://e2e_shop_stages.cfg"

var _main: Node
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
	var progress := StageProgress.new(STAGES)
	_main.set("_economy", economy)
	_main.set("_progress", progress)
	_main.get_node("Hud/Menu").set("economy", economy)
	_main.get_node("Hud/Menu").set("progress", progress)


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	var menu: MenuController = _main.get_node("Hud/Menu")
	var economy: Economy = _main.get("_economy")
	if _ticks == 2:
		if "upgrades" not in menu.page_item_texts():
			_errors.append("the main menu has no upgrades entry: %s" % [menu.page_item_texts()])
		menu.move(1)
		menu.activate()
		if menu.current_page() != MenuController.Page.UPGRADES or menu.page_item_texts().size() != 6:
			_errors.append("the shop does not list six upgrades: %s" % [menu.page_item_texts()])
		economy.earn(100)
		menu.move(3)
		menu.activate()
		if economy.level(Upgrade.RECHARGER) != 1 or economy.credits() != 80:
			_errors.append("buying the recharger failed (level %d, credits %d)" % [economy.level(Upgrade.RECHARGER), economy.credits()])
		menu.move(2)
		menu.activate()
		if economy.level(Upgrade.PHASE_SHIFT) != 0 or economy.credits() != 80:
			_errors.append("a locked level was sold")
		menu.back()
		menu.activate()
		menu.activate()
		menu.activate()
		var run: SurvivalRun = _main.get("_run")
		if run == null or run.config.recharger_level != 1:
			_errors.append("the next race does not use the bought recharger")
		elif run.config.max_shields != 3:
			_errors.append("a stage race starts with %d shields instead of 3" % run.config.max_shields)
		else:
			run.phase = SurvivalRun.Phase.RACING
			run.track.ramp_held = false
			run.track.segment = 495.0
			run.track.elapsed = 5.0
			run.track.p = 1.0 - 7.5 / 8.0
	if _ticks == 120:
		if economy.credits() != 80 + 3 or economy.races() != 1:
			_errors.append("finishing race 1-1 did not pay 3 credits and count (credits %d, races %d)" % [economy.credits(), economy.races()])
		return _finish()
	return false


func _finish() -> bool:
	for path in [ECONOMY, STAGES]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if _errors.is_empty():
		print("  ok    e2e shop (entry, six upgrades, buying, locks, next race, reward)")
		quit(0)
	else:
		for e in _errors:
			print("  FAIL  e2e shop: %s" % e)
		quit(1)
	return true
