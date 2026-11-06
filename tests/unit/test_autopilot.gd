extends TestCase


func _run(shields: int = 0) -> SurvivalRun:
	var config := RunConfig.standard()
	config.generate_obstacles = false
	config.generate_spots = false
	config.start_shields = shields
	var run := SurvivalRun.new(config, 1)
	run.track.segment = 50.0
	run.track.elapsed = 5.0
	run.step(0.0, 0.0)
	return run


func _at_lane(run: SurvivalRun, lane_pos: float) -> void:
	run.track.p = 1.0 - lane_pos / 8.0


func test_steers_towards_an_obstacle_it_can_smash() -> void:
	var run := _run(1)
	run.obstacles.add(Obstacle.make(60, 10, Obstacle.Kind.CUBE, 0))
	_at_lane(run, 7.5)
	check(Autopilot.plough(run) < 0.0, "lane 10 is at higher lane numbers: negative steer")
	_at_lane(run, 12.5)
	check(Autopilot.plough(run) > 0.0, "positive steer towards lower lanes")
	_at_lane(run, 10.5)
	check_near(Autopilot.plough(run), 0.0, 0.0001, "already in the lane")


func test_ignores_what_it_cannot_afford_and_heads_for_a_spot() -> void:
	var run := _run(1)
	run.obstacles.add(Obstacle.make(60, 12, Obstacle.Kind.BEAM, 0))
	run.spots.add(Spot.make(62, 3))
	_at_lane(run, 7.5)
	check(Autopilot.plough(run) > 0.0, "beam costs 2, so it heads for the spot on lane 3")


func test_goes_straight_with_nothing_to_aim_at() -> void:
	var run := _run(0)
	run.obstacles.add(Obstacle.make(60, 12, Obstacle.Kind.CUBE, 0))
	_at_lane(run, 7.5)
	check_near(Autopilot.plough(run), 0.0, 0.0001, "no shields, no spots")


func test_takes_the_short_way_round_the_seam_in_a_tube() -> void:
	var run := _run(1)
	run.obstacles.add(Obstacle.make(60, 0, Obstacle.Kind.CUBE, 0))
	_at_lane(run, 15.0)
	check(Autopilot.plough(run) < 0.0, "lane 15 to lane 0 is one step up, through the seam")
