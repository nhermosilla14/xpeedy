extends TestCase

const PATH := "user://test_economy.cfg"


func _clean() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func _economy() -> Economy:
	_clean()
	return Economy.new(PATH)


func test_prices_and_the_total() -> void:
	check_eq(Upgrade.keys().size(), 6)
	check_eq(Upgrade.total_price(), 430)
	check_eq(Upgrade.price(Upgrade.FLOW_CONTROL, 2), 30)
	check_eq(Upgrade.price(Upgrade.TORPEDO, 3), 45)
	check_eq(Upgrade.price(Upgrade.PHASE_SHIFT, 2), 55)
	for key in Upgrade.keys():
		check_eq(Upgrade.row(key)["unlock"].size(), Upgrade.levels(key), key)
	check(not Upgrade.keys().has("boost"), "no Tachyon Boost")


func test_the_unlock_schedule() -> void:
	var expected := {
		"recharger": [0, 7, 42], "fractal_shields": [0, 12, 24], "phase_shift": [15, 36],
		"flow_control": [0, 20], "torpedo": [0, 26, 40], "modulator": [0, 33]}
	for key in expected:
		for level in expected[key].size():
			check_eq(Upgrade.unlock_at(key, level + 1), expected[key][level], "%s level %d" % [key, level + 1])


func test_where_upgrades_apply() -> void:
	for key in Upgrade.keys():
		check(Upgrade.applies(key, Upgrade.STAGE), "%s in stages" % key)
		check(not Upgrade.applies(key, "extreme") and not Upgrade.applies(key, "pure"), "%s not in extreme or pure" % key)
	for mode in ["casual", "easy", "standard"]:
		check(Upgrade.applies(Upgrade.RECHARGER, mode), "recharger in %s" % mode)
		check(Upgrade.applies(Upgrade.FRACTAL_SHIELDS, mode), "fractal in %s" % mode)
		check(not Upgrade.applies(Upgrade.FLOW_CONTROL, mode), "no flow control in %s" % mode)
		check(not Upgrade.applies(Upgrade.MODULATOR, mode), "no modulator in %s" % mode)


func test_credits_never_go_negative_and_spending_needs_the_balance() -> void:
	var economy := _economy()
	check_eq(economy.credits(), 0)
	check(not economy.spend(1), "cannot spend what is not there")
	economy.earn(10)
	check(economy.spend(4), "spent")
	check_eq(economy.credits(), 6)
	check(not economy.spend(7), "not enough")
	check_eq(economy.credits(), 6)
	economy.earn(-5)
	check_eq(economy.credits(), 6, "negative earnings are ignored")
	_clean()


func test_levels_are_bought_in_order_when_unlocked_and_affordable() -> void:
	var economy := _economy()
	economy.earn(1000)
	check(economy.can_buy(Upgrade.RECHARGER), "level 1 is open from the start")
	check(economy.buy(Upgrade.RECHARGER), "bought")
	check_eq(economy.level(Upgrade.RECHARGER), 1)
	check_eq(economy.credits(), 980)
	check(not economy.can_buy(Upgrade.RECHARGER), "level 2 needs 7 races")
	check(not economy.buy(Upgrade.RECHARGER), "refused")
	for i in 7:
		economy.race_finished(1, true, false)
	check(economy.buy(Upgrade.RECHARGER), "level 2 after 7 races")
	check_eq(economy.level(Upgrade.RECHARGER), 2)
	check(not economy.can_buy(Upgrade.PHASE_SHIFT), "phase shift needs 15 races")
	_clean()


func test_an_unaffordable_level_is_not_bought() -> void:
	var economy := _economy()
	economy.earn(14)
	check(not economy.can_buy(Upgrade.FLOW_CONTROL), "15 needed")
	economy.earn(1)
	check(economy.buy(Upgrade.FLOW_CONTROL), "15 is enough")
	check_eq(economy.credits(), 0)
	_clean()


func test_the_maximum_level_stops_buying() -> void:
	var economy := _economy()
	economy.earn(10000)
	for i in 50:
		economy.race_finished(1, true, false)
	for key in Upgrade.keys():
		for i in Upgrade.levels(key):
			check(economy.buy(key), "%s level %d" % [key, i + 1])
		check(not economy.buy(key), "%s is maxed" % key)
		check_eq(economy.next_price(key), 0)
	check(not economy.any_buyable(), "nothing left")
	_clean()


func test_new_races_pay_and_count_once() -> void:
	var economy := _economy()
	check_eq(economy.race_finished(2, true, false), 4)
	check_eq(economy.races(), 1)
	check_eq(economy.race_finished(2, false, false), 0)
	check_eq(economy.races(), 1, "an old race does not count")
	check_eq(economy.race_finished(3, true, true), 15)
	check_eq(economy.races(), 2)
	check_eq(economy.credits(), 19)
	_clean()


func test_survival_pays_one_credit_per_500_points() -> void:
	var economy := _economy()
	check_eq(economy.survival_score(499), 0)
	check_eq(economy.survival_score(1250), 2)
	check_eq(economy.credits(), 2)
	_clean()


func test_the_economy_is_saved_and_a_corrupt_file_gives_zeros() -> void:
	var economy := _economy()
	economy.earn(100)
	economy.buy(Upgrade.TORPEDO)
	economy.race_finished(1, true, false)
	var again := Economy.new(PATH)
	check_eq(again.credits(), economy.credits())
	check_eq(again.level(Upgrade.TORPEDO), 1)
	check_eq(again.races(), 1)
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("[credits]\ngained=\"lots\"\nspent=99\n[levels]\ntorpedo=9\n")
	file.close()
	var broken := Economy.new(PATH)
	check_eq(broken.credits(), 0)
	check_eq(broken.level(Upgrade.TORPEDO), 3)
	_clean()


func _config() -> RunConfig:
	return RunConfig.standard()


func test_no_upgrades_leave_a_survival_run_unchanged() -> void:
	var economy := _economy()
	var config := Difficulty.config("standard")
	Upgrades.apply(config, economy, "standard")
	check_near(config.shield_decay_seconds, 20.0, 0.0001, "decay")
	check_eq(config.max_shields, 4)
	check_eq(config.recharger_level + config.torpedo_level + config.phase_level, 0)
	_clean()


func test_fractal_shields_set_the_decay() -> void:
	var economy := _economy()
	economy.earn(1000)
	for i in 30:
		economy.race_finished(1, true, false)
	var expected := [20.0, 21.0, 23.0, 25.0]
	for level in 4:
		var config := Difficulty.config("standard")
		Upgrades.apply(config, economy, "standard")
		check_near(config.shield_decay_seconds, expected[level], 0.0001, "level %d" % level)
		economy.buy(Upgrade.FRACTAL_SHIELDS)
	_clean()


func test_the_modulator_and_flow_control_are_for_stages() -> void:
	var economy := _economy()
	economy.earn(1000)
	for i in 40:
		economy.race_finished(1, true, false)
	economy.buy(Upgrade.MODULATOR)
	economy.buy(Upgrade.FLOW_CONTROL)
	var stage := RunConfig.standard()
	Upgrades.apply(stage, economy, Upgrade.STAGE)
	check_eq(stage.max_shields, 4)
	var survival := Difficulty.config("standard")
	Upgrades.apply(survival, economy, "standard")
	check_eq(survival.max_shields, 4, "survival keeps 4")
	var none := RunConfig.standard()
	Upgrades.apply(none, _fresh(), Upgrade.STAGE)
	check_eq(none.max_shields, 3, "a stage race starts with 3 shields")
	_clean()


func _fresh() -> Economy:
	return Economy.new("user://no_such_economy.cfg")


func test_flow_control_sets_the_speed_factor() -> void:
	var economy := _economy()
	economy.earn(1000)
	for i in 25:
		economy.race_finished(1, true, false)
	check_near(Upgrades.speed_factor(economy), 0.87, 0.00001, "level 0")
	economy.buy(Upgrade.FLOW_CONTROL)
	check_near(Upgrades.speed_factor(economy), 0.95, 0.00001, "level 1")
	economy.buy(Upgrade.FLOW_CONTROL)
	check_near(Upgrades.speed_factor(economy), 1.09, 0.00001, "level 2")
	var spec := RaceParser.parse("speed: 130\ntrack: in:500\nobstacles: cubes, 20-30, 4\n")
	check_near(RaceConfig.from_spec(spec, 0, Upgrades.speed_factor(economy)).target_tps, 130.0 * 1.09, 0.0001, "race speed")
	check_near(RaceConfig.from_spec(spec).target_tps, 130.0 * 0.87, 0.0001, "default factor")
	_clean()


func test_active_levels_follow_the_mode() -> void:
	var economy := _economy()
	economy.earn(1000)
	for i in 20:
		economy.race_finished(1, true, false)
	economy.buy(Upgrade.RECHARGER)
	economy.buy(Upgrade.TORPEDO)
	economy.buy(Upgrade.PHASE_SHIFT)
	for mode in [Upgrade.STAGE, "easy"]:
		var config := RunConfig.standard()
		Upgrades.apply(config, economy, mode)
		check_eq([config.recharger_level, config.torpedo_level, config.phase_level], [1, 1, 1], mode)
	var extreme := RunConfig.standard()
	Upgrades.apply(extreme, economy, "extreme")
	check_eq([extreme.recharger_level, extreme.torpedo_level, extreme.phase_level], [0, 0, 0])
	check_near(extreme.shield_decay_seconds, 20.0, 0.0001, "no decay bonus in extreme")
	_clean()
