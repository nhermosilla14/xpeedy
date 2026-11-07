extends TestCase


func _counts(field: SpotField, from_seg: int, to_seg: int) -> Dictionary:
	var counts := {}
	for s in field.all():
		if s.seg >= from_seg and s.seg < to_seg:
			counts[s.kind] = counts.get(s.kind, 0) + 1
	return counts


func _total(counts: Dictionary) -> int:
	var n := 0
	for k in counts:
		n += counts[k]
	return n


func test_without_bonuses_the_spots_are_the_old_ones() -> void:
	var a := SpotField.new(5)
	var b := SpotField.new(5, false, false, false)
	a.generate_to(3000)
	b.generate_to(3000)
	check_eq(a.all().size(), b.all().size())
	for i in a.all().size():
		check(a.all()[i].seg == b.all()[i].seg and a.all()[i].lane == b.all()[i].lane, "same spot %d" % i)
		check_eq(a.all()[i].kind, Spot.Kind.SHIELD)


func test_before_segment_300_only_quake_or_shield() -> void:
	var quakes := 0
	var total := 0
	for seed_value in 200:
		var field := SpotField.new(seed_value, true, true, true)
		field.generate_to(299)
		for s in field.all():
			total += 1
			check(s.kind == Spot.Kind.SHIELD or s.kind == Spot.Kind.QUAKE, "only quake or shield early")
			quakes += 1 if s.kind == Spot.Kind.QUAKE else 0
	check(total > 200, "enough samples")
	check_near(float(quakes) / total, 0.1, 0.04, "about 1 in 10 are quakes")


func test_late_spots_include_all_kinds_with_the_documented_rates() -> void:
	var counts := {}
	for seed_value in 300:
		var field := SpotField.new(seed_value, true, true, true)
		field.generate_to(2500)
		for s in field.all():
			if s.seg > 800:
				counts[s.kind] = counts.get(s.kind, 0) + 1
	var total := _total(counts)
	check(total > 2000, "enough samples")
	# Beyond 750: quake 1/5; of the rest 1/6 dilation, then 1/6 of what is left fold.
	check_near(float(counts.get(Spot.Kind.QUAKE, 0)) / total, 0.2, 0.03, "quake 1 in 5")
	check_near(float(counts.get(Spot.Kind.TIME_DILATION, 0)) / total, 0.8 / 6.0, 0.03, "dilation")
	check_near(float(counts.get(Spot.Kind.SPACE_FOLD, 0)) / total, 0.8 * 5.0 / 36.0, 0.03, "fold")


func test_disabled_bonuses_become_shields() -> void:
	var field := SpotField.new(9, true, false, false)
	field.generate_to(3000)
	for s in field.all():
		check(s.kind == Spot.Kind.SHIELD or s.kind == Spot.Kind.QUAKE, "only quake")
	var quakes := 0
	for s in field.all():
		quakes += 1 if s.kind == Spot.Kind.QUAKE else 0
	check(quakes > 0, "quakes still appear")


func test_pure_has_no_bonuses_and_the_others_have_all_three() -> void:
	for key in Difficulty.keys():
		var config := Difficulty.config(key)
		var expected: bool = key != "pure"
		check_eq([config.quake_enabled, config.dilation_enabled, config.fold_enabled], [expected, expected, expected], key)


func _run() -> SurvivalRun:
	var config := RunConfig.standard()
	config.generate_obstacles = false
	config.generate_spots = false
	var run := SurvivalRun.new(config, 3)
	run.track.segment = 95.0
	run.track.elapsed = 5.0
	return run


func _fly_over(run: SurvivalRun, spot: Spot) -> void:
	run.spots.add(spot)
	run.track.p = 1.0 - (spot.lane + 0.5) / 8.0
	for i in 60:
		run.step(1.0 / 60.0, 0.0)


func test_a_bonus_spot_fills_an_empty_hand() -> void:
	var run := _run()
	_fly_over(run, Spot.make(100, 5, Spot.Kind.QUAKE))
	check_eq(run.held, SurvivalRun.Bonus.QUAKE)
	check_eq(run.shields.count, 0)
	var picked := false
	for e in run.take_events():
		picked = picked or (e.kind == RunEvent.Kind.BONUS_PICKUP and e.bonus == SurvivalRun.Bonus.QUAKE)
	check(picked, "pickup event")


func test_a_second_bonus_spot_is_used_up_and_changes_nothing() -> void:
	var run := _run()
	_fly_over(run, Spot.make(100, 5, Spot.Kind.QUAKE))
	run.take_events()
	run.track.segment = 105.0
	var second := Spot.make(110, 5, Spot.Kind.TIME_DILATION)
	_fly_over(run, second)
	check_eq(run.held, SurvivalRun.Bonus.QUAKE)
	check(second.collected, "used up")
	for e in run.take_events():
		check(e.kind != RunEvent.Kind.BONUS_PICKUP, "no second pickup")


func test_a_shield_spot_still_gives_a_shield() -> void:
	var run := _run()
	_fly_over(run, Spot.make(100, 5))
	check_eq(run.shields.count, 1)
	check_eq(run.held, SurvivalRun.Bonus.NONE)


func _with_obstacles(count: int) -> SurvivalRun:
	var run := _run()
	for i in count:
		run.obstacles.add(Obstacle.make(110 + i * 3, i % 16, Obstacle.Kind.CUBE, 0))
	run.obstacles.add(Obstacle.make(300, 4, Obstacle.Kind.CUBE, 0))
	return run


func test_firing_with_an_empty_hand_does_nothing() -> void:
	var run := _with_obstacles(3)
	run.fire()
	check_eq(run.take_events().size(), 0)
	check_eq(run.obstacles.all().size(), 4)


func test_quake_destroys_the_horizon_for_free_and_spares_what_comes_later() -> void:
	var run := _with_obstacles(12)
	run.held = SurvivalRun.Bonus.QUAKE
	run.shields.add()
	var score := run.score
	run.fire()
	check_eq(run.held, SurvivalRun.Bonus.NONE)
	var alive := 0
	for o in run.obstacles.all():
		alive += 1 if o.alive else 0
	check_eq(alive, 1, "only the one beyond the horizon survives")
	check_eq(run.score, score, "no points")
	check_eq(run.shields.count, 1, "no shield cost")
	var quake: RunEvent
	for e in run.take_events():
		if e.kind == RunEvent.Kind.QUAKE:
			quake = e
	check(quake != null, "quake event")
	check_eq(quake.destroyed.size(), SurvivalRun.QUAKE_EXPLOSIONS)
	for i in quake.destroyed.size() - 1:
		check(quake.destroyed[i].seg <= quake.destroyed[i + 1].seg, "nearest first")
	check_eq(run.trails.texel(105, 0).r < 0.0, true, "trails cleared")


func test_space_fold_is_just_used_up_without_zones() -> void:
	var run := _run()
	run.held = SurvivalRun.Bonus.SPACE_FOLD
	run.fire()
	check_eq(run.held, SurvivalRun.Bonus.NONE)


func test_time_dilation_lasts_seven_game_seconds_at_three_quarter_speed() -> void:
	var run := _run()
	run.held = SurvivalRun.Bonus.TIME_DILATION
	run.fire()
	check_near(run.time_scale(), 0.75, 0.00001, "scale")
	var clock := RunClock.new()
	var real := 0.0
	var ended := false
	while run.dilation_left > 0.0 and real < 20.0:
		clock.scale = run.time_scale()
		run.step(clock.advance(1.0 / 60.0), 0.0)
		real += 1.0 / 60.0
		if run.track.crashed:
			break
	for e in run.take_events():
		ended = ended or e.kind == RunEvent.Kind.DILATION_ENDED
	check_near(real, 7.0 / 0.75, 0.05, "about 9.33 real seconds")
	check(ended, "ended event")
	check_near(run.time_scale(), 1.0, 0.00001, "normal again")


func test_rollers_and_bouncers_freeze_during_time_dilation() -> void:
	var run := _run()
	run.step(1.0 / 60.0, 0.0)
	var before := run.game_time
	run.held = SurvivalRun.Bonus.TIME_DILATION
	run.fire()
	for i in 30:
		run.step(1.0 / 60.0, 0.0)
	check_near(run.game_time, before, 0.00001, "frozen")
	run.dilation_left = 0.0
	run.step(1.0 / 60.0, 0.0)
	check(run.game_time > before, "moving again")


func test_firing_again_restarts_time_dilation() -> void:
	var run := _run()
	run.held = SurvivalRun.Bonus.TIME_DILATION
	run.fire()
	for i in 120:
		run.step(1.0 / 60.0, 0.0)
	check(run.dilation_left < 6.0, "running down")
	run.held = SurvivalRun.Bonus.TIME_DILATION
	run.fire()
	check_near(run.dilation_left, 7.0, 0.00001, "restarted")


func test_shield_decay_slows_with_time_dilation() -> void:
	var slow := _run()
	slow.shields.add()
	slow.held = SurvivalRun.Bonus.TIME_DILATION
	slow.fire()
	var level := slow.shields.level()
	var clock := RunClock.new()
	clock.scale = slow.time_scale()
	for i in 60:
		slow.step(clock.advance(1.0 / 60.0), 0.0)
	var fast := _run()
	fast.shields.add()
	var fast_level := fast.shields.level()
	for i in 60:
		fast.step(1.0 / 60.0, 0.0)
	check((level - slow.shields.level()) < (fast_level - fast.shields.level()), "decays slower")
