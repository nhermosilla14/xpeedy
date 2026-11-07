extends TestCase

const IN := PartSequence.Shape.IN
const FLAT := PartSequence.Shape.FLAT
const OUT := PartSequence.Shape.OUT


func test_roller_step_time_follows_the_angle_and_the_speed() -> void:
	check_near(MovingMath.roller_step_seconds(80.0, IN), 60.0 / 210.0, 0.00001, "inside, standard")
	check_near(MovingMath.roller_step_seconds(80.0, FLAT), 90.0 / 210.0, 0.00001, "flat")
	check_near(MovingMath.roller_step_seconds(80.0, OUT), 120.0 / 210.0, 0.00001, "outside")
	check_near(MovingMath.roller_step_seconds(133.0, IN), 60.0 / 157.0, 0.00001, "casual is faster... per degree")


func test_a_roller_steps_then_rests_for_200_ms() -> void:
	var step := MovingMath.roller_step_seconds(80.0, FLAT)
	check_eq(MovingMath.roller_steps(0.0, 0.0, 80.0, FLAT), 0)
	check(MovingMath.roller_progress(step * 0.5, 0.0, 80.0, FLAT) > 0.49, "mid-step")
	check_near(MovingMath.roller_progress(step * 0.5, 0.0, 80.0, FLAT), 0.5, 0.0001, "half")
	check_eq(MovingMath.roller_steps(step + 0.01, 0.0, 80.0, FLAT), 1)
	check_eq(MovingMath.roller_progress(step + 0.1, 0.0, 80.0, FLAT), -1.0)
	check_eq(MovingMath.roller_steps(step + 0.2 + 0.001, 0.0, 80.0, FLAT), 1)
	check(MovingMath.roller_progress(step + 0.2 + 0.001, 0.0, 80.0, FLAT) >= 0.0, "second step started")
	check_eq(MovingMath.roller_steps(2.0 * (step + 0.2) - 0.001, 0.0, 80.0, FLAT), 2)


func test_rollers_wrap_around_a_tube_and_reverse_on_a_flat_part() -> void:
	check_eq(MovingMath.roller_lane(14, 1, 3, IN), 1)
	check_eq(MovingMath.roller_lane(1, -1, 3, OUT), 14)
	var lanes := []
	for k in 8:
		lanes.append(MovingMath.roller_lane(13, 1, k, FLAT))
	check_eq(lanes, [13, 14, 15, 14, 13, 12, 11, 10])
	lanes.clear()
	for k in 5:
		lanes.append(MovingMath.roller_lane(1, -1, k, FLAT))
	check_eq(lanes, [1, 0, 1, 2, 3])


func test_the_roller_danger_follows_its_progress() -> void:
	var step := MovingMath.roller_step_seconds(80.0, IN)
	check_eq(MovingMath.roller_danger(5, 1, step * 0.2, 0.0, 80.0, IN), [5] as Array[int])
	check_eq(MovingMath.roller_danger(5, 1, step * 0.5, 0.0, 80.0, IN), [5, 6] as Array[int])
	check_eq(MovingMath.roller_danger(5, 1, step * 0.8, 0.0, 80.0, IN), [6] as Array[int])
	check_eq(MovingMath.roller_danger(5, 1, step + 0.1, 0.0, 80.0, IN), [6] as Array[int])
	check_eq(MovingMath.roller_danger(5, -1, step * 0.5, 0.0, 80.0, IN), [5, 4] as Array[int])
	check_eq(MovingMath.roller_danger(0, -1, step * 0.5, 0.0, 80.0, IN), [0, 15] as Array[int])


func test_the_phase_shifts_the_motion() -> void:
	var step := MovingMath.roller_step_seconds(80.0, IN)
	check_eq(MovingMath.roller_steps(0.0, step + 0.1, 80.0, IN), 1)
	check_near(MovingMath.roller_progress(0.0, step * 0.25, 80.0, IN), 0.25, 0.0001, "phase")


func test_the_bouncer_wave() -> void:
	check_near(MovingMath.bouncer_half_period(100.0), 1.0, 0.00001, "half-period at 100")
	check_near(MovingMath.bouncer_half_period(80.0), 1.08, 0.00001, "standard")
	check_near(MovingMath.bouncer_half_period(133.0), 0.868, 0.00001, "casual")
	check_near(MovingMath.bouncer_height(0.0, 0.0, 80.0, FLAT), 0.0, 0.00001, "starts on the surface")
	check_near(MovingMath.bouncer_height(1.08, 0.0, 80.0, FLAT), 1.57, 0.00001, "top after a half-period")
	check_near(MovingMath.bouncer_height(1.08, 0.0, 80.0, IN), 1.96, 0.00001, "tube range")
	check_near(MovingMath.bouncer_height(2.16, 0.0, 80.0, OUT), 0.0, 0.00001, "back down")


func test_bouncer_danger_windows() -> void:
	check_eq(MovingMath.bouncer_danger(3, 0.0, 0.0, 80.0, FLAT), [3] as Array[int])
	check_eq(MovingMath.bouncer_danger(3, 1.08, 0.0, 80.0, FLAT), [] as Array[int])
	check_eq(MovingMath.bouncer_danger(3, 1.08, 0.0, 80.0, OUT), [] as Array[int])
	check_eq(MovingMath.bouncer_danger(3, 1.08, 0.0, 80.0, IN), [11] as Array[int])
	check_eq(MovingMath.bouncer_danger(3, 0.54, 0.0, 80.0, IN), [] as Array[int])
	check_eq(MovingMath.bouncer_danger(3, 0.0, 0.0, 80.0, IN), [3] as Array[int])


func test_smash_cost_and_points() -> void:
	for kind in [Obstacle.Kind.ROLLER, Obstacle.Kind.BOUNCER]:
		var o := Obstacle.make(60, 4, kind, 0)
		check_eq(o.shield_cost(), 1)
		check_eq(o.smash_points(), 200)
		check(o.is_moving(), "moving")


func _kinds(field: ObstacleField) -> Dictionary:
	var counts := {}
	for o in field.all():
		counts[o.kind] = counts.get(o.kind, 0) + 1
	return counts


func test_moving_obstacles_appear_only_when_enabled() -> void:
	for seed_value in [1, 2, 3]:
		var parts := PartSequence.new(seed_value)
		var off := ObstacleField.new(seed_value, parts)
		off.generate_to(3000)
		var counts := _kinds(off)
		check(not counts.has(Obstacle.Kind.ROLLER) and not counts.has(Obstacle.Kind.BOUNCER), "none when off")
		var on := ObstacleField.new(seed_value, PartSequence.new(seed_value), true, true, true)
		on.generate_to(3000)
		counts = _kinds(on)
		check(counts.get(Obstacle.Kind.ROLLER, 0) > 0, "rollers when on (seed %d)" % seed_value)
		check(counts.get(Obstacle.Kind.BOUNCER, 0) > 0, "bouncers when on (seed %d)" % seed_value)


func test_disabled_moving_obstacles_leave_the_old_track_unchanged() -> void:
	var a := ObstacleField.new(7, PartSequence.new(7), true, false, false)
	var b := ObstacleField.new(7, PartSequence.new(7))
	a.generate_to(2000)
	b.generate_to(2000)
	check_eq(a.all().size(), b.all().size())
	for i in a.all().size():
		var x := a.all()[i]
		var y := b.all()[i]
		check(x.seg == y.seg and x.lane == y.lane and x.kind == y.kind, "same obstacle %d" % i)


func test_only_the_enabled_kind_is_placed() -> void:
	var rollers := ObstacleField.new(4, PartSequence.new(4), true, true, false)
	rollers.generate_to(3000)
	check(not _kinds(rollers).has(Obstacle.Kind.BOUNCER), "no bouncers")
	check(_kinds(rollers).has(Obstacle.Kind.ROLLER), "rollers")
	var bouncers := ObstacleField.new(4, PartSequence.new(4), true, false, true)
	bouncers.generate_to(3000)
	check(not _kinds(bouncers).has(Obstacle.Kind.ROLLER), "no rollers")
	check(_kinds(bouncers).has(Obstacle.Kind.BOUNCER), "bouncers")


func test_moving_patterns_stay_inside_one_part() -> void:
	for seed_value in [1, 5, 9]:
		var parts := PartSequence.new(seed_value)
		var field := ObstacleField.new(seed_value, parts, true, true, true)
		field.generate_to(4000)
		for o in field.all():
			if not o.is_moving():
				continue
			var point := 0
			for p in field.placed_points:
				if p <= o.seg:
					point = p
			check_eq(parts.index_at(o.seg), parts.index_at(point), "a moving pattern stays in one part")


func test_the_same_seed_gives_the_same_moving_obstacles() -> void:
	var a := ObstacleField.new(11, PartSequence.new(11), true, true, true)
	var b := ObstacleField.new(11, PartSequence.new(11), true, true, true)
	a.generate_to(2500)
	b.generate_to(2500)
	check_eq(a.all().size(), b.all().size())
	for i in a.all().size():
		var x := a.all()[i]
		var y := b.all()[i]
		check(x.seg == y.seg and x.lane == y.lane and x.kind == y.kind and x.direction == y.direction \
			and is_equal_approx(x.phase, y.phase), "same obstacle %d" % i)


func _run_with(o: Obstacle) -> SurvivalRun:
	var config := RunConfig.standard()
	config.generate_obstacles = false
	config.generate_spots = false
	var run := SurvivalRun.new(config, 3)
	run.track.segment = 40.0
	run.track.elapsed = 5.0
	run.obstacles.add(o)
	return run


func test_a_bouncer_crashes_the_ship_only_while_it_is_down() -> void:
	# Standard: half-period 1.08 s. At game time 0 the bouncer is on the surface; at 1.08 s it is up.
	var down := Obstacle.make(42, 7, Obstacle.Kind.BOUNCER, 0)
	var run := _run_with(down)
	run.track.p = 1.0 - 7.5 / 8.0
	run.game_time = 0.0
	run.step(1.0 / 60.0, 0.0)
	for i in 120:
		if run.track.crashed:
			break
		run.step(1.0 / 60.0, 0.0)
	check(run.track.crashed, "crashed into a bouncer on the surface")
	var up := Obstacle.make(42, 7, Obstacle.Kind.BOUNCER, 0)
	up.shape = PartSequence.Shape.FLAT
	var run2 := _run_with(up)
	run2.track.p = 1.0 - 7.5 / 8.0
	run2.game_time = 1.0
	for i in 40:
		run2.step(1.0 / 60.0, 0.0)
	check(not run2.track.crashed, "flew under a raised bouncer")


func test_a_roller_is_smashed_with_a_shield_for_200() -> void:
	var o := Obstacle.make(42, 7, Obstacle.Kind.ROLLER, 0)
	var run := _run_with(o)
	run.shields.add()
	run.track.p = 1.0 - 7.5 / 8.0
	for i in 120:
		if not o.alive or run.track.crashed:
			break
		run.step(1.0 / 60.0, 0.0)
	check(not run.track.crashed, "no crash")
	check(not o.alive, "smashed")
	check_eq(run.score >= 200, true)


func test_roller_trails_follow_the_danger_lanes() -> void:
	var o := Obstacle.make(60, 7, Obstacle.Kind.ROLLER, 2)
	var run := _run_with(o)
	run.step(1.0 / 60.0, 0.0)
	check_eq(o.painted, [7] as Array[int])
	check(run.trails.texel(50, 7).r >= 0.0, "painted on lane 7")
	run.game_time = MovingMath.roller_step_seconds(80.0, o.shape) * 0.5
	run.step(1.0 / 60.0, 0.0)
	check(o.painted.size() == 2, "both lanes mid-step")
	check(run.trails.texel(50, 8).r >= 0.0 and run.trails.texel(50, 7).r >= 0.0, "both painted")
	run.game_time = MovingMath.roller_step_seconds(80.0, o.shape) + 0.1
	run.step(1.0 / 60.0, 0.0)
	check_eq(o.painted, [8] as Array[int])
	check(run.trails.texel(50, 7).r < 0.0, "old lane cleared")


func test_a_stomp_is_reported_when_a_roller_near_the_ship_lands() -> void:
	var o := Obstacle.make(46, 7, Obstacle.Kind.ROLLER, 0)
	var run := _run_with(o)
	run.take_events()
	var step := MovingMath.roller_step_seconds(80.0, o.shape)
	run.game_time = step - 0.01
	run.step(0.02, 0.0)
	var stomps := 0
	for e in run.take_events():
		if e.kind == RunEvent.Kind.STOMP:
			stomps += 1
	check_eq(stomps, 1)
	var far := Obstacle.make(80, 3, Obstacle.Kind.ROLLER, 0)
	var run2 := _run_with(far)
	run2.take_events()
	run2.game_time = step - 0.01
	run2.step(0.02, 0.0)
	for e in run2.take_events():
		check(e.kind != RunEvent.Kind.STOMP, "no stomp far away")


func test_difficulties_enable_moving_obstacles_except_pure() -> void:
	for key in Difficulty.keys():
		var config := Difficulty.config(key)
		check_eq(config.rollers_enabled, key != "pure", key)
		check_eq(config.bouncers_enabled, key != "pure", key)


func test_instance_codes_of_moving_obstacles() -> void:
	var cube := Obstacle.make(60, 3, Obstacle.Kind.CUBE, 4)
	check_eq(ObstacleView.code(cube), 4.0)
	var roller := Obstacle.make(60, 3, Obstacle.Kind.ROLLER, 2)
	roller.shape = PartSequence.Shape.OUT
	roller.direction = 1
	check_eq(ObstacleView.code(roller), 2.0 + 16.0 + 24.0 + 48.0)
	var bouncer := Obstacle.make(60, 3, Obstacle.Kind.BOUNCER, 1)
	bouncer.direction = 1
	check_eq(ObstacleView.code(bouncer), 1.0 + 24.0 + 96.0)


func test_the_camera_shake_ends() -> void:
	var camera := ShipCamera.new()
	check(not camera.is_shaking(), "idle")
	camera.shake(0.1)
	check(camera.is_shaking(), "shaking")
	camera.free()
