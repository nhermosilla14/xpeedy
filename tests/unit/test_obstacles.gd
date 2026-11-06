extends TestCase

const Shape := PartSequence.Shape
const Kind := Obstacle.Kind


func _config(generate: bool = false) -> RunConfig:
	var config := RunConfig.standard()
	config.generate_obstacles = generate
	return config


func _place(run: SurvivalRun, seg: float, lane_pos: float) -> void:
	run.track.segment = seg
	run.track.elapsed = 5.0
	run.track.p = 1.0 - lane_pos / 8.0
	run.step(0.0, 0.0)


## A run (no generated obstacles) with the ship in the first part, which is an unmorphing tube.
func _tube_run() -> SurvivalRun:
	return SurvivalRun.new(_config(), 1)


## A run and the first segment of a part of `shape` that follows a part of another shape.
func _run_with_part(shape: Shape) -> Array:
	for seed_value in range(1, 30):
		var run := SurvivalRun.new(_config(), seed_value)
		for i in range(1, 40):
			if run.track.parts.shape(i) == shape and run.track.parts.shape(i - 1) != shape:
				return [run, run.track.parts.start(i)]
	return [null, -1]


func _hit(run: SurvivalRun, o: Obstacle, seg: float, lane_pos: float) -> bool:
	run.obstacles.add(o)
	_place(run, seg, lane_pos)
	return run.track.crashed


func _cube(seg: int, lane: int) -> Obstacle:
	return Obstacle.make(seg, lane, Kind.CUBE, 0)


# --- Placement and determinism (doc 10) ---

func test_standard_config() -> void:
	check_near(RunConfig.standard().target_tps, 80.0, 0.0001, "Standard is 80 ms")


func test_spacing_and_level_formulas() -> void:
	check_eq(ObstacleField.spacing_at(55), 12)
	check_eq(ObstacleField.spacing_at(299), 12)
	check_eq(ObstacleField.spacing_at(300), 11)
	check_eq(ObstacleField.spacing_at(1199), 9)
	check_eq(ObstacleField.spacing_at(1200), 8)
	check_eq(ObstacleField.spacing_at(9000), 8)
	check_eq(ObstacleField.level_at(149), 0)
	check_eq(ObstacleField.level_at(150), 1)
	check_eq(ObstacleField.level_at(2250), 15)


func test_first_pattern_is_placed_at_segment_55() -> void:
	var field := ObstacleField.new(1, PartSequence.new(1))
	field.generate_to(54)
	check(field.all().is_empty(), "nothing before the first placement point")
	field.generate_to(55)
	check_eq(field.at_segment(55).size(), 1, "one obstacle at 55")


func test_placement_points_follow_the_spacing() -> void:
	var field := ObstacleField.new(2, PartSequence.new(2))
	field.generate_to(3000)
	var segs: Array[int] = []
	for o in field.all():
		segs.append(o.seg)
	check_eq(segs[0], 55)
	check(segs.size() > 200, "many patterns: %d" % segs.size())
	for i in segs.size() - 1:
		check_eq(segs[i + 1] - segs[i], ObstacleField.spacing_at(segs[i]), "gap after %d" % segs[i])


func _signature(field: ObstacleField) -> Array:
	var result := []
	for o in field.all():
		result.append([o.seg, o.lane, o.kind, o.colour, o.shape])
	return result


func test_same_seed_same_obstacles_whatever_the_request_order() -> void:
	var a := ObstacleField.new(7, PartSequence.new(7))
	for horizon in [100, 400, 1200, 3000]:
		a.generate_to(horizon)
	var b := ObstacleField.new(7, PartSequence.new(7))
	b.generate_to(3000)
	check_eq(_signature(a), _signature(b))
	var c := ObstacleField.new(8, PartSequence.new(8))
	c.generate_to(3000)
	check(_signature(a) != _signature(c), "different seeds differ")


func test_level_zero_pattern_uses_every_kind_lane_and_colour() -> void:
	var field := ObstacleField.new(3, PartSequence.new(3))
	field.generate_to(4000)
	var kinds := {}
	var lanes := {}
	var colours := {}
	var cubes := 0
	for o in field.all():
		kinds[o.kind] = true
		lanes[o.lane] = true
		colours[o.colour] = true
		cubes += 1 if o.kind == Kind.CUBE else 0
	check_eq(kinds.size(), 2, "cube and beam")
	check_eq(lanes.size(), 16, "all lanes")
	check_eq(colours.size(), 5, "all colours")
	var share := float(cubes) / field.all().size()
	check_near(share, 0.5, 0.12, "cube share")


func test_obstacle_shape_is_the_shape_of_its_part() -> void:
	var parts := PartSequence.new(4)
	var field := ObstacleField.new(4, parts)
	field.generate_to(3000)
	var shapes := {}
	for o in field.all():
		check_eq(o.shape, parts.shape_at(o.seg), "shape at %d" % o.seg)
		shapes[o.shape] = true
	check_eq(shapes.size(), 3, "in, flat and out parts all seen")


func test_run_generates_obstacles_as_the_horizon_advances() -> void:
	var run := SurvivalRun.new(_config(true), 1)
	check(run.obstacles.all().is_empty(), "nothing at the start")
	_place(run, 50.0, 7.5)
	check_eq(run.obstacles.at_segment(55).size(), 1, "obstacle at 55 after the horizon reaches it")


func test_obstacles_behind_the_ship_are_forgotten() -> void:
	var run := _tube_run()
	run.obstacles.add(_cube(100, 3))
	var version := run.obstacles.version
	_place(run, 150.0, 12.5)
	check(run.obstacles.all().is_empty(), "dropped once well behind")
	check(run.obstacles.version > version, "version bumped")


# --- Hit box (doc 04) ---

func test_segment_edges_of_the_hit_box() -> void:
	for case in [[99.39, false], [99.41, true], [100.99, true], [101.01, false]]:
		check_eq(_hit(_tube_run(), _cube(100, 5), case[0], 5.5), case[1], "ship at segment %f" % case[0])


func test_lane_edges_of_the_hit_box() -> void:
	for case in [[4.74, false], [4.76, true], [6.24, true], [6.26, false]]:
		check_eq(_hit(_tube_run(), _cube(100, 5), 100.0, case[0]), case[1], "ship at lane %f" % case[0])


func test_seam_wrap_in_a_tube() -> void:
	for case in [[0, 15.7, false], [0, 15.8, true], [15, 0.3, false], [15, 0.2, true]]:
		check_eq(_hit(_tube_run(), _cube(100, case[0]), 100.0, case[1]), case[2],
			"obstacle on lane %d, ship at %f" % [case[0], case[1]])


func test_no_seam_wrap_on_flat_parts() -> void:
	var found := _run_with_part(Shape.FLAT)
	var start: int = found[1]
	var seg := start + 40
	check_eq(_hit(found[0], _cube(seg, 0), seg + 0.0, 15.8), false, "lane 0 obstacle vs ship at 15.8")
	var again := _run_with_part(Shape.FLAT)
	check_eq(_hit(again[0], _cube(seg, 15), seg + 0.0, 0.2), false, "lane 15 obstacle vs ship at 0.2")


func test_no_seam_wrap_while_morphing() -> void:
	var found := _run_with_part(Shape.FLAT)
	var seg: int = found[1] + 10
	check_eq(_hit(found[0], _cube(seg, 0), seg + 0.0, 15.8), false, "no wrap in the middle of a morph")
	check(found[0].track.is_morphing(), "the ship was in the middle of a morph")


func test_tube_beam_also_hits_the_opposite_lane() -> void:
	var beam := Obstacle.make(100, 3, Kind.BEAM, 0)
	check_eq(_hit(_tube_run(), beam, 100.0, 11.5), true, "beam in a tube reaches lane + 8")
	check_eq(_hit(_tube_run(), Obstacle.make(100, 3, Kind.CUBE, 0), 100.0, 11.5), false, "a cube doesn't")
	var pole := Obstacle.make(100, 3, Kind.BEAM, 0)
	pole.shape = Shape.FLAT
	check_eq(_hit(_tube_run(), pole, 100.0, 11.5), false, "a pole on a flat part doesn't")
	check_eq(_hit(_tube_run(), Obstacle.make(100, 3, Kind.BEAM, 0), 100.0, 3.5), true, "its own lane still hits")


func test_beam_opposite_lane_needs_a_mostly_tube_shaped_tunnel() -> void:
	for case in [[15.0, false], [23.0, false], [25.0, true], [29.0, true]]:
		var found := _run_with_part(Shape.IN)
		var seg: int = found[1] + int(case[0])
		var beam := Obstacle.make(seg, 3, Kind.BEAM, 0)
		check_eq(_hit(found[0], beam, seg + 0.5, 11.5), case[1], "%d segments into the morph" % int(case[0]))


# --- Sweeping and crashes ---

func test_a_long_tick_cannot_skip_an_obstacle() -> void:
	var run := _tube_run()
	run.obstacles.add(_cube(102, 5))
	_place(run, 100.0, 5.5)
	check(not run.track.crashed, "not hit yet at 100")
	run.step(0.4, 0.0)  # 5 segments at 80 ms per segment
	check(run.track.segment > 104.9, "moved through the obstacle: %f" % run.track.segment)
	check(run.track.crashed, "crashed on the obstacle in the swept range")
	var miss := _tube_run()
	miss.obstacles.add(_cube(102, 12))
	_place(miss, 100.0, 5.5)
	miss.step(0.4, 0.0)
	check(not miss.track.crashed, "no crash when the obstacle is in another lane")


func test_a_crash_is_reported_once_and_stops_the_ship() -> void:
	var run := _tube_run()
	var o := _cube(100, 5)
	_hit(run, o, 100.0, 5.5)
	check(run.track.crashed, "crashed")
	check_eq(run.track.crash_reason, "obstacle")
	var events := run.take_events()
	check_eq(events.size(), 1, "one event")
	check_eq(events[0].kind, RunEvent.Kind.OBSTACLE_CRASH)
	check(events[0].obstacle == o, "the obstacle that was hit")
	check(run.take_events().is_empty(), "events are cleared when taken")
	var seg := run.track.segment
	run.step(0.5, 1.0)
	check_eq(run.track.segment, seg, "ship frozen after the crash")
	check_eq(run.take_events().size(), 0, "no further events")


func test_collisions_can_be_turned_off() -> void:
	var config := _config()
	config.collisions_enabled = false
	var run := SurvivalRun.new(config, 1)
	check_eq(_hit(run, _cube(100, 5), 100.0, 5.5), false, "ghost mode passes through")


func test_dead_obstacles_are_ignored() -> void:
	var o := _cube(100, 5)
	o.alive = false
	check_eq(_hit(_tube_run(), o, 100.0, 5.5), false)


func test_a_wall_crash_keeps_its_reason() -> void:
	var found := _run_with_part(Shape.FLAT)
	var run: SurvivalRun = found[0]
	_place(run, found[1] + 40.0, 0.1)
	run.step(0.05, 1.0)
	check(run.track.crashed, "drove off the right edge")
	check_eq(run.track.crash_reason, "wall")
