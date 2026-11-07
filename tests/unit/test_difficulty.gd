extends TestCase


func test_the_five_difficulties_in_menu_order() -> void:
	check_eq(Difficulty.keys(), ["casual", "easy", "standard", "extreme", "pure"] as Array[String])
	var expected := {"casual": 133.0, "easy": 100.0, "standard": 80.0, "extreme": 67.0, "pure": 50.0}
	for key in expected:
		check_near(Difficulty.config(key).target_tps, expected[key], 0.0001, key)


func test_pure_has_no_spikes_and_the_others_do() -> void:
	for key in Difficulty.keys():
		check_eq(Difficulty.config(key).spikes_enabled, key != "pure", key)


func test_standard_is_the_plain_run() -> void:
	var plain := RunConfig.standard()
	var standard := Difficulty.config("standard")
	check_eq(standard.target_tps, plain.target_tps)
	check_eq(standard.max_shields, plain.max_shields)
	check_eq(standard.spikes_enabled, plain.spikes_enabled)


func test_unknown_keys_fall_back_to_standard() -> void:
	check(not Difficulty.is_valid("nope"), "invalid")
	check_near(Difficulty.config("nope").target_tps, 80.0, 0.0001, "fallback")


func test_badges_have_one_to_five_triangles_and_distinct_colours() -> void:
	var seen := {}
	for i in 5:
		var key: String = Difficulty.keys()[i]
		check_eq(Difficulty.triangles(key), i + 1, key)
		seen[Difficulty.colour(key)] = true
	check_eq(seen.size(), 5)


func test_bests_are_kept_per_difficulty() -> void:
	check(PersonalBest.key("easy") != PersonalBest.key("extreme"), "distinct keys")
	check_eq(PersonalBest.key("standard"), "survival_standard")


func test_the_difficulty_option() -> void:
	check_eq(LaunchOptions.parse(PackedStringArray(["--difficulty=pure"])).difficulty, "pure")
	check_eq(LaunchOptions.parse(PackedStringArray([])).difficulty, "standard")
