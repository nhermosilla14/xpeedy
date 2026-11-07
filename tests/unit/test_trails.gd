extends TestCase

const Shape := PartSequence.Shape
const Kind := Obstacle.Kind


func _cube(seg: int, lane: int, colour: int = 1) -> Obstacle:
	return Obstacle.make(seg, lane, Kind.CUBE, colour)


func _beam(seg: int, lane: int, shape: Shape) -> Obstacle:
	var o := Obstacle.make(seg, lane, Kind.BEAM, 2)
	o.shape = shape
	return o


func _map(first: int = 0) -> TrailMap:
	var map := TrailMap.new()
	map.advance(first)
	return map


# --- Formulas (doc 04) ---

func test_fade_in_over_ten_segments_from_25_ahead() -> void:
	check_near(TrailMath.fade(30.0), 0.0, 0.0001, "invisible beyond 25")
	check_near(TrailMath.fade(25.0), 0.0, 0.0001, "starts at 25")
	check_near(TrailMath.fade(20.0), 0.5, 0.0001, "half way")
	check_near(TrailMath.fade(15.0), 1.0, 0.0001, "full at 15")
	check_near(TrailMath.fade(3.0), 1.0, 0.0001, "stays full")


func test_highlight_grows_from_15_to_5_segments() -> void:
	check_near(TrailMath.approach(20.0), 0.0, 0.0001, "none beyond 15")
	check_near(TrailMath.approach(15.0), 0.0, 0.0001, "starts at 15")
	check_near(TrailMath.approach(10.0), 0.5, 0.0001, "half at 10")
	check_near(TrailMath.approach(5.0), 1.0, 0.0001, "full at 5")
	check_near(TrailMath.approach(1.0), 1.0, 0.0001, "stays full")


func test_highlight_depends_on_lateral_distance() -> void:
	check_near(TrailMath.lateral(0.0), sqrt(1.5), 0.0001, "in the lane")
	check_near(TrailMath.lateral(0.5), 1.0, 0.0001, "half a lane away")
	check_near(TrailMath.lateral(1.5), 0.0, 0.0001, "none at 1.5 lanes")
	check_near(TrailMath.lateral(3.0), 0.0, 0.0001, "none beyond")
	check_near(TrailMath.highlight(5.0, 0.5), 1.0, 0.0001, "combined")
	check_near(TrailMath.highlight(5.0, 0.0), 1.0, 0.0001, "never above 1")
	check_near(TrailMath.highlight(10.0, 1.0), 0.5 * sqrt(0.5), 0.0001, "mid approach, one lane off")


func test_lane_distance_wraps_only_when_the_seam_is_open() -> void:
	check_near(TrailMath.lane_distance(15.5, 0, true), 1.0, 0.0001, "around the seam")
	check_near(TrailMath.lane_distance(15.5, 0, false), 15.0, 0.0001, "flat: no wrap")
	check_near(TrailMath.lane_distance(7.0, 7, true), 0.5, 0.0001, "inside the lane")


func test_tile_colour_combines_fade_and_highlight() -> void:
	var base := Color.WHITE
	var obstacle := Color(0.2, 0.4, 0.6)
	check(TrailMath.tile_colour(base, obstacle, 30.0, 0.0).is_equal_approx(base), "far: track colour")
	check(TrailMath.tile_colour(base, obstacle, 20.0, 5.0).is_equal_approx(base.lerp(obstacle, 0.5)),
		"half faded, ship far from the lane")
	check(TrailMath.tile_colour(base, obstacle, 12.0, 5.0).is_equal_approx(obstacle),
		"fully faded, no highlight")
	check(TrailMath.tile_colour(base, obstacle, 5.0, 0.5).is_equal_approx(TrailMath.WARNING),
		"close and in the lane: red-orange")
	check(TrailMath.tile_colour(base, obstacle, 20.0, 0.0, 0.0).is_equal_approx(base),
		"zero weight hides an opposite-lane trail")


# --- Map ---

func test_trail_covers_the_25_segments_before_the_obstacle() -> void:
	var map := _map(60)
	map.add_obstacle(_cube(100, 3, 4))
	for seg in range(75, 101):
		var t := map.texel(seg, 3)
		check_eq([t.r, t.g, t.b, t.a], [4.0, 100.0, 0.0, 0.0], "tile at %d" % seg)
	check_eq(map.texel(74, 3).r, -1.0, "nothing before the trail")
	check_eq(map.texel(101, 3).r, -1.0, "nothing after the obstacle")
	check_eq(map.texel(90, 4).r, -1.0, "nothing on other lanes")
	check_eq(map.texel(90, 2).r, -1.0, "nothing on other lanes")


func test_a_tube_beam_also_paints_the_opposite_lane() -> void:
	var map := _map(60)
	map.add_obstacle(_beam(100, 3, Shape.IN))
	var own := map.texel(90, 3)
	var opposite := map.texel(90, 11)
	check_eq([own.r, own.b], [2.0, 0.0], "own lane")
	check_eq([opposite.r, opposite.g, opposite.b], [2.0, 100.0, 1.0], "opposite lane, flagged")
	var map2 := _map(60)
	map2.add_obstacle(_beam(100, 3, Shape.FLAT))
	check_eq(map2.texel(90, 11).r, -1.0, "a pole has no opposite trail")
	var map3 := _map(60)
	map3.add_obstacle(_cube(100, 3))
	check_eq(map3.texel(90, 11).r, -1.0, "a cube has none either")


func test_the_nearest_obstacle_owns_overlapping_tiles_in_either_order() -> void:
	var near := _cube(100, 3, 1)
	var far := _cube(110, 3, 2)
	var a := _map(60)
	a.add_obstacle(near)
	a.add_obstacle(far)
	var b := _map(60)
	b.add_obstacle(far)
	b.add_obstacle(near)
	check_eq(a.data, b.data, "order doesn't matter")
	check_eq(a.texel(90, 3).g, 100.0, "near obstacle's part")
	check_eq(a.texel(100, 3).g, 100.0, "its own tile")
	check_eq(a.texel(101, 3).g, 110.0, "far obstacle's part")
	check_eq(a.texel(85, 3).g, 100.0, "overlap goes to the nearer one")
	check_eq(a.texel(80, 3).g, 100.0, "before the far trail starts, still the near one's")


func test_rows_are_cleared_when_another_segment_claims_them() -> void:
	var map := _map(0)
	map.add_obstacle(_cube(30, 2))
	check_eq(map.texel(20, 2).r, 1.0, "trail present")
	map.advance(70)  # claims segments 70..119, which reuse the rows of 6..55
	check_eq(map.texel(20, 2).r, -1.0, "old segment no longer owned")
	for seg in range(70, 120):
		for lane in 16:
			check_eq(map.texel(seg, lane).r, -1.0, "stale data at %d/%d" % [seg, lane])


func test_trails_written_ahead_of_the_window_survive_scrolling() -> void:
	var map := _map(0)
	map.add_obstacle(_cube(60, 5))  # trail 35..60; 50..60 are outside the window of 0..49
	check_eq(map.texel(55, 5).r, 1.0, "written before it was visible")
	map.advance(10)  # segments 50..59 enter the window
	check_eq(map.texel(55, 5).r, 1.0, "not wiped when entering the window")
	check_eq(map.texel(40, 5).r, 1.0, "still there")


func test_writes_outside_the_ring_are_ignored() -> void:
	var map := _map(100)
	map.add_obstacle(_cube(90, 1))  # entirely behind the window
	map.add_obstacle(_cube(260, 1))  # trail 235..260, beyond first + 64
	check_eq(map.texel(95, 1).r, -1.0, "behind")
	check_eq(map.texel(250, 1).r, -1.0, "too far ahead")
	for seg in range(100, 150):
		check_eq(map.texel(seg, 1).r, -1.0, "window is clean at %d" % seg)


func test_removing_an_obstacle_clears_its_trail_and_exposes_the_farther_one() -> void:
	var field := ObstacleField.new(1, PartSequence.new(1))
	var near := _cube(100, 3, 1)
	var far := _cube(110, 3, 2)
	field.add(near)
	field.add(far)
	var map := _map(60)
	map.add_obstacle(near)
	map.add_obstacle(far)
	map.remove_obstacle(near, field)
	check_eq(map.texel(80, 3).r, -1.0, "own part gone (the far trail starts at 85)")
	check_eq(map.texel(90, 3).g, 110.0, "the far obstacle's trail shows again")
	check_eq(map.texel(100, 3).g, 110.0, "including under the removed obstacle")
	var alone := _map(60)
	alone.add_obstacle(far)
	check_eq(map.data, alone.data, "same as if only the far obstacle had been added")


func test_removing_a_tube_beam_clears_both_lanes() -> void:
	var field := ObstacleField.new(1, PartSequence.new(1))
	var beam := _beam(100, 3, Shape.IN)
	field.add(beam)
	var map := _map(60)
	map.add_obstacle(beam)
	map.remove_obstacle(beam, field)
	for seg in range(75, 101):
		check_eq(map.texel(seg, 3).r, -1.0, "lane 3 at %d" % seg)
		check_eq(map.texel(seg, 11).r, -1.0, "lane 11 at %d" % seg)


func test_version_changes_with_the_data() -> void:
	var map := _map(0)
	var before := map.version
	map.add_obstacle(_cube(40, 3))
	check(map.version > before, "painting bumps the version")


# --- Wired into the run ---

func test_the_run_paints_trails_for_generated_obstacles() -> void:
	var run := SurvivalRun.new(RunConfig.standard(), 1)
	run.track.segment = 50.0
	run.track.elapsed = 5.0
	run.step(0.0, 0.0)
	var o := run.obstacles.at_segment(55)[0]
	check_eq(run.trails.texel(50, o.lane).g, 55.0, "trail towards the first obstacle")
	check_eq(run.trails.texel(50, o.lane).r, float(o.colour), "in the obstacle's colour")


func test_trails_are_exact_far_into_a_run() -> void:
	# Regression: half-float storage could not hold whole segment numbers above 2048.
	for base in [2047, 2049, 4097, 100000, 16777000]:
		var map := _map(base - 30)
		map.add_obstacle(_cube(base, 6, 3))
		for seg in range(base - 25, base + 1):
			var t := map.texel(seg, 6)
			check_eq([t.r, int(t.g)], [3.0, base], "obstacle at %d seen from tile %d" % [base, seg])


func test_bytes_are_laid_out_for_an_rgba8_texture() -> void:
	var map := _map(60)
	map.add_obstacle(_beam(100, 3, Shape.IN))
	var own := ((100 - 7 & 63) * 16 + 3) * 4  # tile at segment 93, lane 3: 7 segments before the beam
	check_eq([map.data[own], map.data[own + 1], map.data[own + 2], map.data[own + 3]], [3, 7, 0, 0],
		"colour + 1, distance to the obstacle, not opposite, no spot")
	var opposite := ((100 - 7 & 63) * 16 + 11) * 4
	check_eq([map.data[opposite], map.data[opposite + 1], map.data[opposite + 2]], [3, 7, 255],
		"opposite lane flagged in blue")
	check_eq(map.data.size(), 64 * 16 * 4, "16 x 64 RGBA8")


# --- Shield spots in the map ---

func test_a_spot_marks_three_tiles_on_its_lane() -> void:
	var map := _map(60)
	map.add_spot(Spot.make(70, 4))
	for seg in range(70, 73):
		check_eq(map.texel(seg, 4).a, 1.0, "spot tile at %d" % seg)
		check_eq(map.data[((seg & 63) * 16 + 4) * 4 + 3], 60, "alpha byte at %d" % seg)
	check_eq(map.texel(69, 4).a, 0.0, "before the spot")
	check_eq(map.texel(73, 4).a, 0.0, "after the spot")
	check_eq(map.texel(71, 5).a, 0.0, "other lanes")
	map.remove_spot(Spot.make(70, 4))
	check_eq(map.texel(71, 4).a, 0.0, "cleared")


func test_spots_and_trails_do_not_clear_each_other() -> void:
	var map := _map(60)
	map.add_spot(Spot.make(90, 3))
	var field := ObstacleField.new(1, PartSequence.new(1))
	var cube := _cube(100, 3)
	field.add(cube)
	map.add_obstacle(cube)
	check_eq(map.texel(91, 3).a, 1.0, "the trail did not clear the spot")
	check_eq(map.texel(91, 3).r, 1.0, "both are there")
	map.remove_obstacle(cube, field)
	check_eq(map.texel(91, 3).a, 1.0, "removing the trail left the spot")
	check_eq(map.texel(91, 3).r, -1.0, "and removed the trail")


func test_a_reused_row_loses_its_spots() -> void:
	var map := _map(0)
	map.add_spot(Spot.make(20, 2))
	map.advance(70)
	for seg in range(70, 120):
		check_eq(map.texel(seg, 2).a, 0.0, "stale spot at %d" % seg)


func test_bonus_spots_store_their_kind_in_the_alpha_byte() -> void:
	var map := TrailMap.new()
	map.advance(60)
	for kind in [Spot.Kind.SHIELD, Spot.Kind.QUAKE, Spot.Kind.TIME_DILATION, Spot.Kind.SPACE_FOLD]:
		var spot := Spot.make(70, 3, kind)
		map.add_spot(spot)
		check_eq(map.texel(70, 3).a, float(kind + 1), "texel for kind %d" % kind)
		check_eq(map.data[((70 & 63) * 16 + 3) * 4 + 3], (kind + 1) * 60)
		map.remove_spot(spot)
		check_eq(map.texel(70, 3).a, 0.0, "removed")
