extends TestCase


func _config() -> RunConfig:
	var config := RunConfig.standard()
	config.generate_spots = false
	return config


# --- Launch options ---

func test_no_arguments_means_a_normal_run() -> void:
	var o := LaunchOptions.parse(PackedStringArray())
	check(not o.ghost and not o.benchmark and not o.invulnerable, "no debug flags")
	check_eq([o.shields, o.autopilot, o.run_seed, o.start_segment], [0, "", -1, 0.0])
	check_near(o.timescale, 1.0, 0.0001)


func test_single_options() -> void:
	var o := LaunchOptions.parse(PackedStringArray(
		["--ghost", "--shields=3", "--autopilot=plough", "--timescale=0.5", "--seed=77", "--start-segment=900", "--invulnerable"]))
	check(o.ghost and o.invulnerable and not o.benchmark, "flags")
	check_eq([o.shields, o.autopilot, o.run_seed, o.start_segment], [3, "plough", 77, 900.0])
	check_near(o.timescale, 0.5, 0.0001)


func test_look_review_options() -> void:
	var o := LaunchOptions.parse(PackedStringArray(["--clean", "--start-shape=flat", "--screenshot=/tmp/a.png,3.5"]))
	check(o.clean, "clean")
	check_eq(o.start_shape, "flat")
	check_eq(o.screenshot_path, "/tmp/a.png")
	check_near(o.screenshot_seconds, 3.5, 0.0001, "seconds")
	var plain := LaunchOptions.parse(PackedStringArray(["--screenshot=/tmp/b.png"]))
	check_eq(plain.screenshot_path, "/tmp/b.png")
	check_near(plain.screenshot_seconds, 2.0, 0.0001, "default delay")
	check(not plain.clean and plain.start_shape == "", "defaults")


func test_the_benchmark_bundles_a_comparable_run() -> void:
	var o := LaunchOptions.parse(PackedStringArray(["--benchmark"]))
	check(o.benchmark and o.invulnerable and not o.ghost, "benchmark flags")
	check_eq([o.shields, o.autopilot, o.run_seed, o.start_segment], [4, "plough", 2024, 2300.0])


func test_options_override_the_benchmark_defaults() -> void:
	var o := LaunchOptions.parse(PackedStringArray(["--benchmark", "--seed=5", "--start-segment=1000", "--shields=1"]))
	check_eq([o.run_seed, o.start_segment, o.shields, o.autopilot], [5, 1000.0, 1, "plough"])


func test_the_arguments_file_format_is_a_space_separated_line() -> void:
	# The launch script passes the contents of args.txt after `--`.
	var o := LaunchOptions.parse("--start-segment=2300 --shields=4".split(" "))
	check_eq([o.start_segment, o.shields], [2300.0, 4])


# --- A run that starts deep ---

func test_a_run_can_start_deep_at_full_speed() -> void:
	var config := _config()
	config.start_segment = 2300.0
	config.start_shields = 4
	var run := SurvivalRun.new(config, 7)
	check(run.track.segment >= 2300.0, "at the start segment: %f" % run.track.segment)
	check_near(run.track.tps, run.track.target_tps, 0.5, "already at full speed")
	check_eq(run.score, 0, "the score starts from zero")
	check(run.obstacles.placed_points.size() > 150, "the track up to here was generated")
	check(ObstacleField.level_at(run.obstacles.placed_points[run.obstacles.placed_points.size() - 1]) >= 15,
		"full density ahead")
	check(not run.obstacles.all().is_empty(), "obstacles ahead")
	check_eq(run.shields.count, 4)
	var before := run.track.segment
	var distance_before := run.distance_points
	for i in 60:
		run.step(1.0 / 60.0, 0.0)
		if run.track.crashed:
			break
	var travelled := run.distance_points - distance_before
	check(run.track.crashed or (travelled >= 11 and travelled <= 13), "about 12 distance points in a second: %d" % travelled)
	check(run.track.crashed or run.track.segment > before + 10.0, "moved on")


func test_a_normal_run_does_not_jump() -> void:
	var run := SurvivalRun.new(_config(), 7)
	check_near(run.track.segment, TrackModel.START_SEGMENT, 0.0001)


# --- Invulnerable mode ---

func _fly(config: RunConfig, kind: Obstacle.Kind, shields: int) -> SurvivalRun:
	config.generate_obstacles = false
	config.start_shields = shields
	var run := SurvivalRun.new(config, 1)
	var o := Obstacle.make(100, 5, kind, 1)
	run.obstacles.add(o)
	run.track.segment = 100.0
	run.track.elapsed = 5.0
	run.track.p = 1.0 - 5.5 / 8.0
	run.step(0.0, 0.0)
	return run


func test_invulnerable_runs_ignore_obstacles_the_shields_cannot_pay_for() -> void:
	var config := _config()
	config.crash_on_obstacles = false
	var run := _fly(config, Obstacle.Kind.CUBE, 0)
	check(not run.track.crashed, "a cube with no shields does not crash")
	var beam := _fly(_config_invulnerable(), Obstacle.Kind.BEAM, 1)
	check(not beam.track.crashed, "a beam with one shield does not crash")
	check_eq(beam.shields.count, 1, "and costs nothing")


func _config_invulnerable() -> RunConfig:
	var config := _config()
	config.crash_on_obstacles = false
	return config


func test_invulnerable_runs_still_smash_what_they_can_pay_for() -> void:
	var run := _fly(_config_invulnerable(), Obstacle.Kind.CUBE, 1)
	check(not run.track.crashed, "alive")
	check_eq(run.shields.count, 0, "the shield was spent")
	check_eq(run.score - run.distance_points, 100, "+100")


func test_normal_runs_still_crash() -> void:
	var run := _fly(_config(), Obstacle.Kind.CUBE, 0)
	check(run.track.crashed, "a cube with no shields is a crash")
