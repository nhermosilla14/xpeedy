extends TestCase


func _run(countdown: bool) -> SurvivalRun:
	var config := RunConfig.standard()
	config.countdown = countdown
	config.generate_obstacles = false
	config.generate_spots = false
	return SurvivalRun.new(config, 5)


func test_the_countdown_holds_the_start_speed_and_scores_nothing() -> void:
	var run := _run(true)
	check_eq(run.phase, SurvivalRun.Phase.STARTING)
	for i in 120:
		run.step(1.0 / 60.0, 0.0)
	check_eq(run.phase, SurvivalRun.Phase.STARTING)
	check_near(run.track.tps, TrackModel.START_TPS, 0.001, "starting speed")
	check_eq(run.score, 0)
	check_near(run.track.segment, TrackModel.START_SEGMENT + 2.0 * 1000.0 / TrackModel.START_TPS, 0.05, "distance")


func test_racing_starts_after_3_8_seconds_and_the_speed_ramps() -> void:
	var run := _run(true)
	for i in int(SurvivalRun.COUNTDOWN_SECONDS * 60.0) + 2:
		run.step(1.0 / 60.0, 0.0)
	check_eq(run.phase, SurvivalRun.Phase.RACING)
	var started := false
	for e in run.take_events():
		started = started or e.kind == RunEvent.Kind.RACE_STARTED
	check(started, "race started event")
	check_eq(run.score, 0)
	var at_start := run.track.segment
	for i in 120:
		run.step(1.0 / 60.0, 0.0)
	check(run.track.tps < TrackModel.START_TPS, "ramping")
	check(run.score > 0, "scoring")
	check(run.score <= int(run.track.segment - at_start) + 1, "score counts from the race start")


func test_light_timings() -> void:
	var run := _run(true)
	check_eq(run.light_progress(0), -1.0)
	while run.countdown_time < 1.8 - 0.001:
		run.step(1.0 / 60.0, 0.0)
	check_near(run.light_progress(0), 1.0 - 0.0, 0.5, "first light swelling")
	check(run.light_progress(0) >= 0.0 and run.light_progress(0) <= 1.0, "first lit")
	check_eq(run.light_progress(2), -1.0)


func test_without_the_countdown_everything_is_as_before() -> void:
	var run := _run(false)
	check_eq(run.phase, SurvivalRun.Phase.RACING)
	run.step(1.0 / 60.0, 0.0)
	check(run.track.elapsed > 0.0, "ramp runs")
	check_eq(run.light_progress(0), 1.0)


func test_personal_best_is_saved_loaded_and_only_raised() -> void:
	var path := "user://test_best.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var best := PersonalBest.new(path)
	check_eq(best.get_best("k"), 0)
	check(best.submit("k", 100), "first is a best")
	check(not best.submit("k", 50), "lower is not")
	check(best.submit("k", 120), "higher is")
	check_eq(PersonalBest.new(path).get_best("k"), 120)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_a_corrupt_or_missing_best_file_counts_as_none() -> void:
	var path := "user://test_best_bad.cfg"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("this is [not a config\n")
	file.close()
	check_eq(PersonalBest.new(path).get_best("k"), 0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check_eq(PersonalBest.new("user://nope.cfg").get_best("k"), 0)


func test_plain_runs_are_the_ones_that_count() -> void:
	check(LaunchOptions.parse(PackedStringArray([])).is_plain_run(), "plain")
	check(LaunchOptions.parse(PackedStringArray(["--seed=3"])).is_plain_run(), "seed is plain")
	check(not LaunchOptions.parse(PackedStringArray(["--invulnerable"])).is_plain_run(), "invulnerable")
	check(not LaunchOptions.parse(PackedStringArray(["--benchmark"])).is_plain_run(), "benchmark")
	check(not LaunchOptions.parse(PackedStringArray(["--no-countdown"])).is_plain_run(), "no countdown")
