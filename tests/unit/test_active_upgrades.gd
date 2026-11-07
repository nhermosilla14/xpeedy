extends TestCase


func _run(recharger := 0, torpedo := 0, phase := 0) -> SurvivalRun:
	var config := RunConfig.standard()
	config.generate_obstacles = false
	config.generate_spots = false
	config.recharger_level = recharger
	config.torpedo_level = torpedo
	config.phase_level = phase
	var run := SurvivalRun.new(config, 3)
	run.track.segment = 90.0
	run.track.elapsed = 5.0
	run.track.p = 1.0 - 7.5 / 8.0
	return run


func _kinds(run: SurvivalRun) -> Array[int]:
	var kinds: Array[int] = []
	for e in run.take_events():
		kinds.append(e.kind)
	return kinds


func _step(run: SurvivalRun, seconds: float) -> void:
	for i in int(round(seconds * 60.0)):
		run.step(1.0 / 60.0, 0.0)


# --- Shield Recharger ---

func test_the_recharger_adds_its_level_in_shields_once() -> void:
	for level in [1, 2, 3]:
		var run := _run(level)
		check(run.can_recharge(), "usable")
		run.use_recharger()
		check_eq(run.shields.count, level, "level %d" % level)
		check(not run.can_recharge(), "used up")
		run.use_recharger()
		check_eq(run.shields.count, level, "only once")
		check(_kinds(run).has(RunEvent.Kind.RECHARGED), "event")


func test_the_recharger_caps_at_the_maximum_and_restarts_the_timer_even_when_full() -> void:
	var run := _run(3)
	run.shields.max_count = 3
	for i in 3:
		run.shields.add()
	run.shields.time_left = 4.0
	run.use_recharger()
	check_eq(run.shields.count, 3)
	check_near(run.shields.time_left, run.shields.decay_seconds, 0.0001, "timer restarted")
	check(not run.can_recharge(), "the button is used up")


func test_no_recharger_without_the_upgrade() -> void:
	var run := _run(0)
	check(not run.can_recharge(), "not available")
	run.use_recharger()
	check_eq(run.shields.count, 0)


# --- Tachyon Torpedo ---

func _cube(run: SurvivalRun, seg: int, lane: int, kind := Obstacle.Kind.CUBE) -> Obstacle:
	var o := Obstacle.make(seg, lane, kind, 0)
	run.obstacles.add(o)
	return o


func test_the_number_of_torpedoes_is_the_level() -> void:
	for level in [1, 2, 3]:
		check_eq(_run(0, level).torpedoes_left, level)
	check(not _run(0, 0).can_fire_torpedo(), "none without the upgrade")


func test_a_torpedo_destroys_what_is_in_its_lane_ahead_for_nothing() -> void:
	var run := _run(0, 1)
	run.shields.add()
	var hit := _cube(run, 100, 7)
	var other_lane := _cube(run, 102, 2)
	var behind_range := _cube(run, 150, 7)
	run.take_events()
	run.fire_torpedo()
	check_eq(run.torpedoes_left, 0)
	_step(run, 3.0)
	check(not hit.alive, "the cube in the lane was destroyed")
	check(other_lane.alive, "another lane is untouched")
	check(behind_range.alive, "beyond 25 segments is out of range")
	check_eq(run.shields.count, 1, "no shield cost")
	var kinds := _kinds(run)
	check(kinds.has(RunEvent.Kind.TORPEDO_FIRED) and kinds.has(RunEvent.Kind.TORPEDO_HIT), "events")
	check_eq(run.torpedoes.size(), 0, "the torpedo is gone after 25 segments")


func test_a_torpedo_gives_no_points() -> void:
	var run := _run(0, 1)
	_cube(run, 100, 7)
	_step(run, 0.1)
	var score := run.score
	run.fire_torpedo()
	var before := run.score
	var distance_points := 0
	_step(run, 1.0)
	distance_points = run.score - before
	check(distance_points < 15, "only distance points, no +100 for the kill (%d)" % distance_points)
	check(score >= 0, "score")


func test_a_torpedo_hits_within_04_lanes_of_a_tile() -> void:
	var run := _run(0, 1)
	run.track.p = 1.0 - 7.5 / 8.0
	var near := _cube(run, 105, 8)   # tile spans 8-9, the torpedo is at 7.5: 0.5 away, not within 0.4
	var closer := _cube(run, 107, 7)
	run.fire_torpedo()
	_step(run, 3.0)
	check(near.alive, "0.5 lanes away is a miss")
	check(not closer.alive, "its own lane is a hit")


func test_a_torpedo_hits_both_ends_of_a_tube_beam() -> void:
	var run := _run(0, 1)
	var beam := _cube(run, 105, 15, Obstacle.Kind.BEAM)
	beam.shape = PartSequence.Shape.IN
	run.fire_torpedo()
	_step(run, 3.0)
	check(not beam.alive, "the opposite end of the beam (lane 7) is hit")


func test_a_torpedo_hits_moving_obstacles_where_they_are() -> void:
	var run := _run(0, 1)
	var bouncer := _cube(run, 106, 7, Obstacle.Kind.BOUNCER)
	run.fire_torpedo()
	_step(run, 3.0)
	check(not bouncer.alive, "a bouncer is destroyed whatever its height")


func test_torpedoes_reload_in_travel_segments() -> void:
	var run := _run(0, 2)
	check_near(run.torpedo_reload_segments(), 64.0, 0.0001, "level 2")
	check_near(_run(0, 1).torpedo_reload_segments(), 80.0, 0.0001, "level 1")
	check_near(_run(0, 3).torpedo_reload_segments(), 51.2, 0.0001, "level 3")
	run.fire_torpedo()
	check_eq(run.torpedoes_left, 1)
	check(not run.can_fire_torpedo(), "reloading")
	check_near(run.torpedo_reload_fraction(), 0.0, 0.02, "dial starts empty")
	run.track.segment += 32.0
	check_near(run.torpedo_reload_fraction(), 0.5, 0.02, "half way")
	run.track.segment += 33.0
	check(run.can_fire_torpedo(), "ready again")
	run.fire_torpedo()
	check_eq(run.torpedoes_left, 0)
	check(not run.can_fire_torpedo(), "none left")


func test_the_reload_measures_travel_not_time() -> void:
	var run := _run(0, 2)
	run.fire_torpedo()
	var ready_at := run.torpedo_ready_at
	run.step(0.0, 0.0)
	check_near(run.torpedo_ready_at, ready_at, 0.0001, "a standing ship does not reload")
	check(not run.can_fire_torpedo(), "still reloading")


# --- Phase Shift ---

func test_phase_shift_lasts_five_or_ten_seconds() -> void:
	for level in [1, 2]:
		var run := _run(0, 0, level)
		run.use_phase_shift()
		check_near(run.phase_left, 5.0 * level, 0.0001, "level %d" % level)
		check(not run.can_phase(), "once per run")
		_step(run, 5.0 * level - 0.1)
		check(run.phase_left > 0.0, "still active")
		_step(run, 0.2)
		check_eq(run.phase_left, 0.0)


func test_phase_shift_ignores_obstacles() -> void:
	var run := _run(0, 0, 1)
	run.use_phase_shift()
	var cube := _cube(run, 100, 7)
	_step(run, 2.0)
	check(not run.track.crashed, "no crash")
	check(cube.alive, "no smash either")
	check_eq(run.shields.count, 0)
	var plain := _run(0, 0, 1)
	_cube(plain, 100, 7)
	_step(plain, 2.0)
	check(plain.track.crashed, "without Phase Shift it crashes")


func test_phase_shift_ignores_plasma_but_spots_still_work() -> void:
	var run := _run(0, 0, 1)
	run.use_phase_shift()
	run.zone_state = SurvivalRun.ZoneState.ACTIVE
	run.zone = Zone.Kind.PLASMA_CLOUD
	run.zone_timer = 7.0
	run.shields.add()
	run.vortices.append(Vector2i(100, 7))
	run.spots.add(Spot.make(102, 7))
	_step(run, 2.0)
	check_eq(run.shields.count, 2, "the vortex did nothing and the spot gave a shield")
	check(not _kinds(run).has(RunEvent.Kind.PLASMA_TOUCHED), "no plasma touch")


func test_phase_shift_warns_at_two_and_one_seconds_and_ends() -> void:
	var run := _run(0, 0, 1)
	run.use_phase_shift()
	var warnings := 0
	var ended := 0
	for i in int(5.3 * 60.0):
		run.step(1.0 / 60.0, 0.0)
		for e in run.take_events():
			warnings += 1 if e.kind == RunEvent.Kind.PHASE_WARNING else 0
			ended += 1 if e.kind == RunEvent.Kind.PHASE_ENDED else 0
	check_eq(warnings, 2)
	check_eq(ended, 1)


func test_phase_shift_runs_on_game_time() -> void:
	var run := _run(0, 0, 1)
	run.use_phase_shift()
	var clock := RunClock.new()
	clock.scale = 0.75
	var real := 0.0
	while run.phase_left > 0.0 and real < 20.0:
		run.step(clock.advance(1.0 / 60.0), 0.0)
		real += 1.0 / 60.0
	check_near(real, 5.0 / 0.75, 0.05, "Time Dilation stretches it")
	var paused := _run(0, 0, 1)
	paused.use_phase_shift()
	var left := paused.phase_left
	check_near(paused.phase_left, left, 0.0001, "not stepping (a pause) freezes it")


# --- Keep going ---

func test_keep_going_after_an_obstacle_crash_once() -> void:
	var run := _run()
	_cube(run, 100, 7)
	_cube(run, 120, 7)
	_step(run, 2.0)
	check(run.track.crashed and run.can_continue(), "crashed on an obstacle")
	check(run.continue_run(), "continued")
	check(not run.track.crashed, "running again")
	_step(run, 3.0)
	check(run.obstacles.all().filter(func(o: Obstacle) -> bool: return o.alive).is_empty() or not run.track.crashed, "the Quake cleared the way")
	check(not run.can_continue(), "only once")
	check(_kinds(run).has(RunEvent.Kind.CONTINUED), "event")


func test_no_keep_going_after_a_wall_crash_or_a_second_crash() -> void:
	var run := _run()
	run.track.crash("wall")
	check(not run.can_continue(), "a wall crash never continues")
	var again := _run()
	_cube(again, 100, 7)
	_step(again, 2.0)
	again.continue_run()
	_cube(again, int(again.track.segment) + 3, 7)
	_step(again, 2.0)
	check(again.track.crashed, "crashed again")
	check(not again.can_continue(), "no second continue")
