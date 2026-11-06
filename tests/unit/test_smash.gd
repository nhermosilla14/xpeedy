extends TestCase

const Kind := Obstacle.Kind
const Shape := PartSequence.Shape


func _run(shields: int = 0) -> SurvivalRun:
	var config := RunConfig.standard()
	config.generate_obstacles = false
	config.generate_spots = false
	config.start_shields = shields
	return SurvivalRun.new(config, 1)


func _place(run: SurvivalRun, seg: float, lane_pos: float) -> void:
	run.track.segment = seg
	run.track.elapsed = 5.0
	run.track.p = 1.0 - lane_pos / 8.0
	run.step(0.0, 0.0)


## Points that did not come from distance.
func _bonus(run: SurvivalRun) -> int:
	return run.score - run.distance_points


## Flies into `o` (at segment 100, lane 5) with `shields` units and returns the run.
func _fly_into(o: Obstacle, shields: int) -> SurvivalRun:
	var run := _run(shields)
	run.obstacles.add(o)
	_place(run, 100.0, 5.5)
	return run


func _obstacle(kind: Kind, seg: int = 100, lane: int = 5) -> Obstacle:
	return Obstacle.make(seg, lane, kind, 2)


# --- Costs and points (doc 04, 05, 09) ---

func test_costs_and_points_per_kind() -> void:
	check_eq([_obstacle(Kind.CUBE).shield_cost(), _obstacle(Kind.CUBE).smash_points()], [1, 100])
	check_eq([_obstacle(Kind.SPIKE).shield_cost(), _obstacle(Kind.SPIKE).smash_points()], [1, 100])
	check_eq([_obstacle(Kind.BEAM).shield_cost(), _obstacle(Kind.BEAM).smash_points()], [2, 300])


func test_a_cube_is_smashed_with_one_shield() -> void:
	var o := _obstacle(Kind.CUBE)
	var run := _fly_into(o, 1)
	check(not run.track.crashed, "survived")
	check_eq(run.shields.count, 0, "the shield was spent")
	check_eq(_bonus(run), 100, "+100")
	check(not o.alive, "the obstacle is destroyed")


func test_a_spike_is_smashed_with_one_shield() -> void:
	var run := _fly_into(_obstacle(Kind.SPIKE), 3)
	check(not run.track.crashed, "survived")
	check_eq(run.shields.count, 2)
	check_eq(_bonus(run), 100, "+100")


func test_a_beam_costs_two_shields() -> void:
	var o := _obstacle(Kind.BEAM)
	var run := _fly_into(o, 2)
	check(not run.track.crashed, "survived")
	check_eq(run.shields.count, 0, "both shields were spent")
	check_eq(_bonus(run), 300, "+300")
	check(not o.alive, "destroyed")


func test_a_beam_with_one_shield_is_a_crash_that_keeps_the_shield() -> void:
	var o := _obstacle(Kind.BEAM)
	var run := _fly_into(o, 1)
	check(run.track.crashed, "crashed")
	check_eq(run.track.crash_reason, "obstacle")
	check_eq(run.shields.count, 1, "the single shield is not used")
	check_eq(_bonus(run), 0, "no points")
	check(o.alive, "the beam is still there")


func test_without_shields_any_obstacle_is_a_crash() -> void:
	for kind in [Kind.CUBE, Kind.SPIKE, Kind.BEAM]:
		var run := _fly_into(_obstacle(kind), 0)
		check(run.track.crashed, "kind %d" % kind)


func test_a_tube_beam_hit_on_its_opposite_lane_is_smashed_too() -> void:
	var beam := Obstacle.make(100, 3, Kind.BEAM, 0)
	var run := _run(2)
	run.obstacles.add(beam)
	_place(run, 100.0, 11.5)
	check(not run.track.crashed, "survived")
	check_eq(run.shields.count, 0, "cost 2")
	check_eq(_bonus(run), 300)


# --- Several obstacles in one tick ---

func _two_cubes_run(shields: int) -> SurvivalRun:
	var run := _run(shields)
	run.obstacles.add(_obstacle(Kind.CUBE, 100, 5))
	run.obstacles.add(_obstacle(Kind.CUBE, 101, 5))
	_place(run, 98.0, 5.5)
	run.step(0.24, 0.0)  # three segments at 80 ms per segment: sweeps over both cubes
	return run


func test_several_obstacles_can_be_smashed_in_one_tick() -> void:
	var run := _two_cubes_run(2)
	check(run.track.segment > 100.9, "the tick covered both: %f" % run.track.segment)
	check(not run.track.crashed, "survived")
	check_eq(run.shields.count, 0)
	check_eq(_bonus(run), 200, "+200")


func test_the_second_obstacle_is_a_crash_when_the_shields_run_out() -> void:
	var run := _two_cubes_run(1)
	check(run.track.crashed, "crashed on the second cube")
	check_eq(run.shields.count, 0, "the first cube took the shield")
	check_eq(_bonus(run), 100, "points for the first")


func test_obstacles_are_resolved_in_segment_order() -> void:
	# A beam first and a cube after it: two shields cover the beam, so the cube is a crash.
	var run := _run(2)
	run.obstacles.add(Obstacle.make(101, 5, Kind.CUBE, 0))
	run.obstacles.add(Obstacle.make(100, 5, Kind.BEAM, 0))
	_place(run, 98.0, 5.5)
	run.step(0.24, 0.0)
	check(run.track.crashed, "the beam used both shields, the cube crashed")
	check_eq(_bonus(run), 300)


# --- Timer, trails, events ---

func test_a_smash_restarts_the_decay_timer() -> void:
	var run := _run(2)
	run.shields.time_left = 4.0
	run.obstacles.add(_obstacle(Kind.CUBE))
	_place(run, 100.0, 5.5)
	check_eq(run.shields.count, 1)
	check_near(run.shields.time_left, 20.0, 0.0001, "timer restarted")


func test_a_smashed_obstacle_loses_its_trail_and_the_farther_one_shows() -> void:
	var run := _run(1)
	_place(run, 90.0, 5.5)
	var near := _obstacle(Kind.CUBE, 100, 5)
	var far := Obstacle.make(108, 5, Kind.CUBE, 3)
	run.obstacles.add(near)
	run.obstacles.add(far)
	check_eq(run.trails.texel(100, 5).g, 100.0, "the near cube's trail ends on its own tile")
	_place(run, 100.0, 5.5)
	check(not near.alive, "smashed")
	check_eq(run.trails.texel(100, 5).g, 108.0, "now the far cube's trail covers that tile")
	check_eq(run.trails.texel(100, 5).r, 3.0, "in its colour")


func test_a_smash_changes_the_obstacle_version() -> void:
	var run := _run(1)
	var o := _obstacle(Kind.CUBE)
	run.obstacles.add(o)
	var before := run.obstacles.version
	_place(run, 100.0, 5.5)
	check(run.obstacles.version > before, "views see the change")


func test_a_smash_is_reported() -> void:
	var o := _obstacle(Kind.BEAM)
	var run := _fly_into(o, 2)
	var events := run.take_events()
	var smashes := events.filter(func(e: RunEvent) -> bool: return e.kind == RunEvent.Kind.OBSTACLE_SMASHED)
	check_eq(smashes.size(), 1, "one smash")
	check(smashes[0].obstacle == o, "for that obstacle")
	check_eq(smashes[0].points, 300)
	check_eq(events.filter(func(e: RunEvent) -> bool: return e.kind == RunEvent.Kind.CRASH).size(), 0, "no crash")


func test_a_wall_crash_is_reported_once() -> void:
	var run := _run()
	var found := false
	for seed_value in range(1, 30):
		var candidate := SurvivalRun.new(run.config, seed_value)
		for i in range(1, 40):
			if candidate.track.parts.shape(i) == Shape.FLAT:
				run = candidate
				_place(run, candidate.track.parts.start(i) + 40.0, 0.1)
				found = true
				break
		if found:
			break
	run.take_events()
	run.step(0.05, 1.0)
	check(run.track.crashed, "drove off the edge")
	var events := run.take_events()
	check_eq(events.size(), 1, "one event")
	check_eq([events[0].kind, events[0].reason], [RunEvent.Kind.CRASH, "wall"])
	run.step(0.5, 1.0)
	check(run.take_events().is_empty(), "nothing more after the crash")


func test_the_score_never_goes_down() -> void:
	var run := _run(4)
	var last := 0
	for i in 5:
		run.obstacles.add(_obstacle(Kind.CUBE, 100 + i * 3, 5))
	_place(run, 98.0, 5.5)
	for i in 400:
		run.step(1.0 / 60.0, 0.0)
		check(run.score >= last, "tick %d" % i)
		last = run.score
