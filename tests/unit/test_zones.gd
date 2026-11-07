extends TestCase


func _config(zones: Array[int]) -> RunConfig:
	var config := RunConfig.standard()
	config.generate_obstacles = false
	config.generate_spots = false
	config.zones = zones
	return config


func _run(zones: Array[int] = Zone.all_kinds()) -> SurvivalRun:
	var run := SurvivalRun.new(_config(zones), 3)
	run.track.segment = 90.0
	run.track.elapsed = 5.0
	return run


func _mark(seg: int, zone: int) -> ZoneField.Mark:
	var mark := ZoneField.Mark.new()
	mark.seg = seg
	mark.zone = zone
	return mark


func _kinds(run: SurvivalRun) -> Array[int]:
	var kinds: Array[int] = []
	for e in run.take_events():
		kinds.append(e.kind)
	return kinds


func _step(run: SurvivalRun, seconds: float) -> void:
	for i in int(round(seconds * 60.0)):
		run.step(1.0 / 60.0, 0.0)


func test_no_marks_without_enabled_zones() -> void:
	var field := ZoneField.new(5, [] as Array[int], 80.0)
	field.generate_to(5000)
	check_eq(field.all().size(), 0)


func test_marks_are_200_to_400_plus_the_countdown_distance_apart() -> void:
	var field := ZoneField.new(5, Zone.all_kinds(), 80.0)
	field.generate_to(8000)
	var marks := field.all()
	check(marks.size() > 8, "several marks")
	var extra := int(3000.0 / 80.0) + 1
	check(marks[0].seg >= 200 + extra and marks[0].seg <= 400 + extra, "first mark in range")
	for i in range(1, marks.size()):
		var gap := marks[i].seg - marks[i - 1].seg
		check(gap >= 200 + extra and gap <= 400 + extra, "gap %d" % gap)


func test_disabled_zones_are_rerolled_or_the_mark_is_skipped() -> void:
	var field := ZoneField.new(8, [Zone.Kind.BLACKOUT] as Array[int], 50.0)
	field.generate_to(40000)
	check(field.all().size() > 40, "most marks survive the re-rolls")
	for mark in field.all():
		check_eq(mark.zone, Zone.Kind.BLACKOUT)
	var all := ZoneField.new(8, Zone.all_kinds(), 50.0)
	all.generate_to(40000)
	check(field.all().size() < all.all().size(), "some marks were skipped")


func test_the_same_seed_gives_the_same_marks() -> void:
	var a := ZoneField.new(11, Zone.all_kinds(), 100.0)
	var b := ZoneField.new(11, Zone.all_kinds(), 100.0)
	a.generate_to(6000)
	b.generate_to(6000)
	check_eq(a.all().size(), b.all().size())
	for i in a.all().size():
		check(a.all()[i].seg == b.all()[i].seg and a.all()[i].zone == b.all()[i].zone, "mark %d" % i)


func test_marks_are_painted_on_all_lanes_with_a_zone_code() -> void:
	var map := TrailMap.new()
	map.advance(60)
	map.add_mark(_mark(70, Zone.Kind.HUE_SHIFT))
	for lane in 16:
		check_eq(map.texel(70, lane).a, float(Zone.Kind.HUE_SHIFT + 4), "lane %d" % lane)
	check_eq(map.texel(71, 3).a, 0.0)


func test_pure_has_blackout_only_and_the_others_all_five() -> void:
	check_eq(Difficulty.config("pure").zones, [Zone.Kind.BLACKOUT] as Array[int])
	for key in ["casual", "easy", "standard", "extreme"]:
		check_eq(Difficulty.config(key).zones.size(), 5, key)


func test_crossing_a_mark_runs_countdown_then_seven_seconds() -> void:
	var run := _run()
	run.zones.add(_mark(100, Zone.Kind.HUE_SHIFT))
	while run.zone_state == SurvivalRun.ZoneState.IDLE and run.track.segment < 120.0:
		run.step(1.0 / 60.0, 0.0)
	check_eq(run.zone_state, SurvivalRun.ZoneState.COUNTDOWN)
	check_eq(run.zone, Zone.Kind.HUE_SHIFT)
	var kinds := _kinds(run)
	check(kinds.has(RunEvent.Kind.ZONE_WARNING), "warning")
	_step(run, 3.05)
	check_eq(run.zone_state, SurvivalRun.ZoneState.ACTIVE)
	check(_kinds(run).has(RunEvent.Kind.ZONE_STARTED), "started")
	_step(run, 6.9)
	check_eq(run.zone_state, SurvivalRun.ZoneState.ACTIVE)
	_step(run, 0.2)
	check_eq(run.zone_state, SurvivalRun.ZoneState.IDLE)
	check_eq(run.zone, Zone.Kind.NONE)
	check(_kinds(run).has(RunEvent.Kind.ZONE_ENDED), "ended")


func test_countdown_seconds_are_reported_3_2_1() -> void:
	var run := _run()
	run.zones.add(_mark(100, Zone.Kind.BLACKOUT))
	var seconds: Array[int] = []
	for i in 600:
		run.step(1.0 / 60.0, 0.0)
		for e in run.take_events():
			if e.kind == RunEvent.Kind.ZONE_WARNING or e.kind == RunEvent.Kind.ZONE_SECOND:
				seconds.append(e.seconds)
	check_eq(seconds, [3, 2, 1] as Array[int])


func test_a_mark_does_nothing_while_a_zone_is_pending_or_active() -> void:
	var run := _run()
	run.zones.add(_mark(100, Zone.Kind.BLACKOUT))
	var second := _mark(108, Zone.Kind.DARK_NEBULA)
	run.zones.add(second)
	for i in 150:
		run.step(1.0 / 60.0, 0.0)
	check_eq(run.zone, Zone.Kind.BLACKOUT)
	_step(run, 4.0)
	check_eq(run.zone, Zone.Kind.BLACKOUT)
	check(second.crossed, "the second mark was used up")


func test_time_dilation_stretches_the_zone_timers() -> void:
	var run := _run()
	run.zone_state = SurvivalRun.ZoneState.ACTIVE
	run.zone = Zone.Kind.BLACKOUT
	run.zone_timer = 7.0
	var clock := RunClock.new()
	clock.scale = 0.75
	var real := 0.0
	while run.zone_state == SurvivalRun.ZoneState.ACTIVE and real < 20.0:
		run.step(clock.advance(1.0 / 60.0), 0.0)
		real += 1.0 / 60.0
	check_near(real, 7.0 / 0.75, 0.05, "9.33 real seconds")


func test_space_fold_ends_an_active_zone_and_is_wasted_otherwise() -> void:
	var run := _run()
	run.zone_state = SurvivalRun.ZoneState.ACTIVE
	run.zone = Zone.Kind.HUE_SHIFT
	run.zone_timer = 5.0
	run.held = SurvivalRun.Bonus.SPACE_FOLD
	run.fire()
	check_eq(run.zone_state, SurvivalRun.ZoneState.IDLE)
	check(_kinds(run).has(RunEvent.Kind.ZONE_ENDED), "ended event")
	run.zone_state = SurvivalRun.ZoneState.COUNTDOWN
	run.zone = Zone.Kind.BLACKOUT
	run.zone_timer = 2.0
	run.held = SurvivalRun.Bonus.SPACE_FOLD
	run.fire()
	check_eq(run.zone_state, SurvivalRun.ZoneState.COUNTDOWN)
	check_eq(run.held, SurvivalRun.Bonus.NONE)


# --- Gravity Well ---

func test_the_gravity_formula() -> void:
	check_near(Zone.gravity(0.0, 0.0, 0.0), 0.25 * 1.5 * sin(PI / 4.0), 0.00001, "t = 0")
	var t := 1.3
	check_near(Zone.gravity(t, 0.5, 1.0),
		0.25 * (2.5 * sin(2.5 * t + 0.5) + 1.5 * sin(1.5 * t + PI / 4.0 + 1.0)), 0.00001, "formula")


func test_gravity_pushes_the_ship_only_while_the_zone_is_active() -> void:
	var run := _run()
	run.track.p = 0.0
	_step(run, 0.5)
	check_near(run.track.p, 0.0, 0.0001, "no force before")
	run.zone_state = SurvivalRun.ZoneState.ACTIVE
	run.zone = Zone.Kind.GRAVITY_WELL
	run.zone_timer = 7.0
	run.zone_time = 0.5
	_step(run, 0.5)
	check(absf(run.track.p) > 0.001, "pushed during the zone")


func test_gravity_fades_out_over_the_last_second() -> void:
	var run := _run()
	run.zone_state = SurvivalRun.ZoneState.ACTIVE
	run.zone = Zone.Kind.GRAVITY_WELL
	run.zone_time = 3.0
	run.zone_timer = 4.0
	var full := run.gravity_value()
	run.zone_timer = 0.5
	check_near(run.gravity_value(), full * 0.5, 0.0001, "half faded")
	run.zone_timer = 0.0
	check_near(run.gravity_value(), 0.0, 0.0001, "gone")


func test_gravity_phases_come_from_the_seed() -> void:
	var a := _run()
	var b := _run()
	for run in [a, b]:
		run.zones.add(_mark(100, Zone.Kind.GRAVITY_WELL))
		_step(run, 6.0)
	check_near(a.gravity_value(), b.gravity_value(), 0.00001, "same seed, same force")


# --- Plasma Cloud ---

func _plasma_run() -> SurvivalRun:
	var run := _run()
	run.zone_state = SurvivalRun.ZoneState.ACTIVE
	run.zone = Zone.Kind.PLASMA_CLOUD
	run.zone_timer = 7.0
	return run


func test_vortices_are_5_to_9_segments_apart() -> void:
	var run := _plasma_run()
	run.config.target_tps = 133.0
	for i in 4:
		run.step(1.0 / 60.0, 0.0)
	check(run.vortices.size() >= 2, "some placed")
	for i in range(1, run.vortices.size()):
		var gap := run.vortices[i].x - run.vortices[i - 1].x
		check(gap >= 5 and gap <= 9, "gap %d" % gap)


func test_the_number_of_vortices_follows_the_speed() -> void:
	check_eq(Zone.max_vortices(133.0), 7)
	check_eq(Zone.max_vortices(100.0), 6)
	check_eq(Zone.max_vortices(80.0), 4)
	check_eq(Zone.max_vortices(67.0), 3)
	var run := _plasma_run()
	for i in 4:
		run.step(1.0 / 60.0, 0.0)
	check(run.vortices.size() <= 4, "at most 4 at standard speed")


func test_touching_a_vortex_costs_a_shield_clears_the_hand_and_never_crashes() -> void:
	var run := _plasma_run()
	run.shields.add()
	run.held = SurvivalRun.Bonus.QUAKE
	run.vortices.append(Vector2i(95, 5))
	run.trails.add_vortex(95, 5)
	run.track.p = 1.0 - 5.5 / 8.0
	_step(run, 1.5)
	check(not run.track.crashed, "no crash")
	check_eq(run.shields.count, 0)
	check_eq(run.held, SurvivalRun.Bonus.NONE)
	check(_kinds(run).has(RunEvent.Kind.PLASMA_TOUCHED), "event")
	check(not run.vortices.has(Vector2i(95, 5)), "the vortex is gone")


func test_touching_a_vortex_without_shields_still_discards_the_bonus() -> void:
	var run := _plasma_run()
	run.held = SurvivalRun.Bonus.TIME_DILATION
	run.vortices.append(Vector2i(95, 5))
	run.track.p = 1.0 - 5.5 / 8.0
	_step(run, 1.5)
	check(not run.track.crashed, "no crash")
	check_eq(run.held, SurvivalRun.Bonus.NONE)


func test_vortices_vanish_when_the_zone_ends() -> void:
	var run := _plasma_run()
	for i in 4:
		run.step(1.0 / 60.0, 0.0)
	check(run.vortices.size() > 0, "some alive")
	run.zone_timer = 0.01
	run.step(1.0 / 60.0, 0.0)
	check_eq(run.vortices.size(), 0)
	check_eq(run.zone_state, SurvivalRun.ZoneState.IDLE)


# --- View values ---

func test_fog_density_per_zone() -> void:
	check_near(ShipCamera.fog_density(Zone.Kind.NONE, 1.0), 0.5, 0.00001, "normal")
	for zone in [Zone.Kind.BLACKOUT, Zone.Kind.HUE_SHIFT, Zone.Kind.DARK_NEBULA]:
		check_near(ShipCamera.fog_density(zone, 1.0), 0.3, 0.00001, "lighter fog")
	check_near(ShipCamera.fog_density(Zone.Kind.PLASMA_CLOUD, 1.0), 0.5, 0.00001, "plasma keeps the fog")
	for t in [0.0, 0.4, 1.1, 2.3]:
		var d := ShipCamera.fog_density(Zone.Kind.GRAVITY_WELL, t)
		check(d >= 0.3 - 0.00001 and d <= 0.5 + 0.00001, "gravity well fog pulses 0.4 +- 0.1")
	check_near(ShipCamera.fog_density(Zone.Kind.GRAVITY_WELL, PI / 4.0), 0.5, 0.00001, "peak")


func test_the_camera_narrows_its_view_in_gravity_well() -> void:
	var camera := ShipCamera.new()
	camera.apply_zone(Zone.Kind.GRAVITY_WELL, 0.2)
	check_near(camera.fov, 80.0, 0.0001, "80 degrees")
	camera.apply_zone(Zone.Kind.NONE, 0.0)
	check_near(camera.fov, 96.0, 0.0001, "back to 96")
	camera.free()
