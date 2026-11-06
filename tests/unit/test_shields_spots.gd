extends TestCase


func _config() -> RunConfig:
	var config := RunConfig.standard()
	config.generate_obstacles = false
	config.generate_spots = false
	return config


func _run() -> SurvivalRun:
	return SurvivalRun.new(_config(), 1)


func _place(run: SurvivalRun, seg: float, lane_pos: float) -> void:
	run.track.segment = seg
	run.track.elapsed = 5.0
	run.track.p = 1.0 - lane_pos / 8.0
	run.step(0.0, 0.0)


## Puts the ship at (seg, lane) in the first (tube) part with a spot at (100, lane) and reports pick-up.
func _collects(spot_lane: int, seg: float, lane_pos: float) -> bool:
	var run := _run()
	run.spots.add(Spot.make(100, spot_lane))
	_place(run, seg, lane_pos)
	return run.shields.count == 1


# --- ShieldStack (doc 05) ---

func test_the_stack_is_capped() -> void:
	var stack := ShieldStack.new(4, 20.0)
	for i in 6:
		stack.add()
	check_eq(stack.count, 4)


func test_one_unit_is_lost_every_decay_period() -> void:
	var stack := ShieldStack.new(4, 20.0)
	for i in 3:
		stack.add()
	stack.tick(19.9)
	check_eq(stack.count, 3, "not yet")
	stack.tick(0.2)
	check_eq(stack.count, 2, "after 20 s")
	stack.tick(20.0)
	check_eq(stack.count, 1)
	stack.tick(20.0)
	check_eq(stack.count, 0)
	stack.tick(100.0)
	check_eq(stack.count, 0, "never negative")


func test_a_long_tick_loses_several_units() -> void:
	var stack := ShieldStack.new(4, 20.0)
	for i in 4:
		stack.add()
	stack.tick(45.0)
	check_eq(stack.count, 2, "two expiries in 45 s")
	check_near(stack.time_left, 15.0, 0.0001, "timer keeps its phase")


func test_picking_up_a_shield_restarts_the_timer_even_when_full() -> void:
	var stack := ShieldStack.new(4, 20.0)
	for i in 4:
		stack.add()
	stack.tick(19.0)
	stack.add()
	check_eq(stack.count, 4, "still full")
	check_near(stack.time_left, 20.0, 0.0001, "timer restarted")
	stack.tick(19.0)
	check_eq(stack.count, 4, "no loss 19 s after the restart")
	stack.tick(1.5)
	check_eq(stack.count, 3)


func test_losing_units_restarts_the_timer() -> void:
	var stack := ShieldStack.new(4, 20.0)
	for i in 3:
		stack.add()
	stack.tick(15.0)
	stack.lose(1)
	check_eq(stack.count, 2)
	check_near(stack.time_left, 20.0, 0.0001)
	stack.lose(5)
	check_eq(stack.count, 0, "never negative")


func test_fraction_for_the_hud() -> void:
	var stack := ShieldStack.new(4, 20.0)
	stack.add()
	check_near(stack.fraction(), 1.0, 0.0001)
	stack.tick(10.0)
	check_near(stack.fraction(), 0.5, 0.0001)


func test_the_bar_level_drains_one_segment_per_period() -> void:
	var stack := ShieldStack.new(4, 20.0)
	check_near(stack.level(), 0.0, 0.0001, "empty")
	for i in 4:
		stack.add()
	check_near(stack.level(), 4.0, 0.0001, "full bar")
	stack.tick(10.0)
	check_near(stack.level(), 3.5, 0.0001, "after 10 s the last segment is half drained")
	stack.tick(10.0)
	check_near(stack.level(), 3.0, 0.0001, "after 20 s the last segment is gone")
	stack.tick(10.0)
	check_near(stack.level(), 2.5, 0.0001, "and the next one drains")
	stack.tick(30.0)
	check_near(stack.level(), 1.0, 0.0001, "30 s later")
	stack.tick(100.0)
	check_near(stack.level(), 0.0, 0.0001, "never negative")


func test_the_bar_level_falls_smoothly_across_an_expiry() -> void:
	var stack := ShieldStack.new(4, 20.0)
	for i in 3:
		stack.add()
	stack.tick(19.5)  # 0.5 s left on the third unit
	var before := stack.level()
	stack.tick(1.0)  # the unit expires during this second
	check_near(before - stack.level(), 1.0 / 20.0, 0.0001, "0.05 segments per second, no jump")
	check_eq(stack.count, 2)


func test_the_timer_idles_while_there_are_no_shields() -> void:
	var stack := ShieldStack.new(4, 20.0)
	stack.tick(50.0)
	check_near(stack.time_left, 20.0, 0.0001)
	stack.add()
	stack.tick(19.0)
	check_eq(stack.count, 1, "a pick-up after idling gets the full period")


# --- SpotField (doc 10) ---

func _groups(seed_value: int, horizon: int) -> Dictionary:
	var field := SpotField.new(seed_value)
	field.generate_to(horizon)
	var groups := {}
	for s in field.all():
		if not groups.has(s.seg):
			groups[s.seg] = [] as Array[Spot]
		groups[s.seg].append(s)
	return groups


func test_the_first_group_is_at_segment_100() -> void:
	var at_100 := 0
	for seed_value in range(1, 31):
		var field := SpotField.new(seed_value)
		field.generate_to(99)
		check(field.all().is_empty(), "nothing before 100 (seed %d)" % seed_value)
		field.generate_to(5000)
		var segs := _groups(seed_value, 5000).keys()
		segs.sort()
		check(segs[0] >= 100, "first group at %d" % segs[0])
		at_100 += 1 if segs[0] == 100 else 0
	check(at_100 >= 22, "about 7 in 8 first groups are not skipped: %d of 30" % at_100)


func test_groups_are_spaced_by_at_least_three_obstacle_spacings() -> void:
	for seed_value in [1, 2, 3]:
		var segs := _groups(seed_value, 6000).keys()
		segs.sort()
		check(segs.size() > 100, "many groups")
		for i in segs.size() - 1:
			var gap: int = segs[i + 1] - segs[i]
			check(gap >= 3 * ObstacleField.spacing_at(segs[i]), "gap %d after %d" % [gap, segs[i]])
	# Early on the spacing is 12, so the next group is 36-47 segments later (when none is skipped).
	var early := {}
	for seed_value in range(1, 80):
		var segs := _groups(seed_value, 200).keys()
		segs.sort()
		if segs.size() >= 2 and segs[0] == 100:
			early[segs[1] - segs[0]] = true
	for gap in early:
		check(gap >= 36 and gap <= 47 or gap >= 72, "first gap %d" % gap)
	check(early.size() >= 8, "the whole 36-47 range is used: %s" % [early.keys()])


func test_group_size_grows_with_distance_and_is_capped_at_three() -> void:
	var largest_early := 0
	var largest_mid := 0
	var largest_late := 0
	for seed_value in range(1, 25):
		var groups := _groups(seed_value, 6000)
		for seg in groups:
			var size: int = groups[seg].size()
			check(size >= 1 and size <= 3, "size %d" % size)
			if seg < 450:
				largest_early = maxi(largest_early, size)
			elif seg < 900:
				largest_mid = maxi(largest_mid, size)
			else:
				largest_late = maxi(largest_late, size)
	check_eq(largest_early, 1, "single spots before segment 450")
	check_eq(largest_mid, 2, "up to two between 450 and 899")
	check_eq(largest_late, 3, "up to three from 900")


func test_groups_are_spread_evenly_around_the_ring() -> void:
	var two := 0
	var three := 0
	for seed_value in range(1, 25):
		var groups := _groups(seed_value, 6000)
		for seg in groups:
			var lanes: Array = groups[seg].map(func(s: Spot) -> int: return s.lane)
			if lanes.size() == 2:
				two += 1
				check_eq((lanes[1] - lanes[0] + 16) % 16, 8, "two spots opposite each other")
			elif lanes.size() == 3:
				three += 1
				check_eq([(lanes[1] - lanes[0] + 16) % 16, (lanes[2] - lanes[0] + 16) % 16], [5, 10],
					"three spots every 16/3 lanes")
	check(two > 5 and three > 5, "both sizes were seen: %d, %d" % [two, three])


func test_same_seed_same_spots_whatever_the_request_order() -> void:
	var a := SpotField.new(9)
	for horizon in [150, 600, 2000]:
		a.generate_to(horizon)
	var b := SpotField.new(9)
	b.generate_to(2000)
	var sig := func(f: SpotField) -> Array:
		return f.all().map(func(s: Spot) -> Array: return [s.seg, s.lane])
	check_eq(sig.call(a), sig.call(b))
	var c := SpotField.new(10)
	c.generate_to(2000)
	check(sig.call(a) != sig.call(c), "different seeds differ")


# --- Collecting spots (doc 06) ---

func test_a_spot_is_three_segments_long() -> void:
	for case in [[99.39, false], [99.41, true], [102.99, true], [103.01, false]]:
		check_eq(_collects(5, case[0], 5.5), case[1], "ship at segment %f" % case[0])


func test_a_spot_is_one_lane_wide_plus_the_ship_half_width() -> void:
	for case in [[4.74, false], [4.76, true], [6.24, true], [6.26, false]]:
		check_eq(_collects(5, 101.0, case[0]), case[1], "ship at lane %f" % case[0])


func test_spots_wrap_across_the_seam_in_tubes() -> void:
	check_eq(_collects(0, 101.0, 15.8), true, "lane 0 spot, ship at 15.8")
	check_eq(_collects(15, 101.0, 0.2), true, "lane 15 spot, ship at 0.2")
	check_eq(_collects(0, 101.0, 15.7), false, "too far")


func test_a_spot_is_collected_once_and_reported() -> void:
	var run := _run()
	_place(run, 90.0, 5.5)
	var spot := Spot.make(100, 5)
	run.spots.add(spot)
	check_eq(run.trails.texel(101, 5).a, 1.0, "the spot is painted on the track")
	_place(run, 101.0, 5.5)
	check_eq(run.shields.count, 1, "one shield")
	check(spot.collected, "marked collected")
	check_eq(run.trails.texel(101, 5).a, 0.0, "its paint is gone")
	var events := run.take_events()
	check_eq(events.size(), 1, "one event")
	check_eq(events[0].kind, RunEvent.Kind.SHIELD_PICKUP)
	check(events[0].spot == spot, "for that spot")
	_place(run, 101.5, 5.5)
	check_eq(run.shields.count, 1, "not collected again")


func test_picking_up_a_spot_when_full_still_restarts_the_timer() -> void:
	var run := _run()
	for i in 4:
		run.shields.add()
	run.shields.time_left = 5.0
	run.spots.add(Spot.make(100, 5))
	_place(run, 101.0, 5.5)
	check_eq(run.shields.count, 4, "still four")
	check_near(run.shields.time_left, 20.0, 0.0001, "timer restarted")


func test_a_run_can_start_with_shields() -> void:
	var config := _config()
	config.start_shields = 3
	var run := SurvivalRun.new(config, 1)
	check_eq(run.shields.count, 3)
	check_near(run.shields.level(), 3.0, 0.0001)
	check_eq(_run().shields.count, 0, "none by default")


func test_the_run_decays_shields_with_game_time() -> void:
	var run := _run()
	run.shields.add()
	run.shields.add()
	run.step(1.0, 0.0)
	check_near(run.shields.time_left, 19.0, 0.0001, "one second of game time")


func test_spot_generation_follows_the_horizon() -> void:
	var run := SurvivalRun.new(RunConfig.standard(), 3)
	check(run.spots.all().is_empty(), "nothing at the start")
	_place(run, 60.0, 7.5)
	check(not run.spots.all().is_empty(), "the horizon reached the first group")
	var found := false
	for s in run.spots.all():
		found = found or run.trails.texel(s.seg, s.lane).a == 1.0
	check(found, "generated spots are painted")


# --- Score (doc 09) ---

func test_distance_scores_one_point_per_segment() -> void:
	var run := _run()
	check_eq(run.score, 0, "starts at zero")
	var last := 0
	for i in 600:
		run.step(1.0 / 60.0, 0.0)
		check_eq(run.score, int(floor(run.track.segment - TrackModel.START_SEGMENT)), "tick %d" % i)
		check(run.score >= last, "never decreases")
		last = run.score
	check(run.score > 50, "scored over 10 s: %d" % run.score)


func test_score_stops_at_a_crash() -> void:
	var run := _run()
	run.obstacles.add(Obstacle.make(60, 7, Obstacle.Kind.CUBE, 0))
	run.track.p = 1.0 - 7.5 / 8.0
	for i in 600:
		run.step(1.0 / 60.0, 0.0)
	check(run.track.crashed, "hit the cube")
	var score := run.score
	run.step(1.0, 0.0)
	check_eq(run.score, score, "no points after the crash")


func test_a_new_run_starts_at_zero() -> void:
	var run := _run()
	for i in 120:
		run.step(1.0 / 60.0, 0.0)
	check(run.score > 0, "scored")
	check_eq(SurvivalRun.new(_config(), 2).score, 0, "a fresh run")
