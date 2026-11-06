extends TestCase

const Shape := PartSequence.Shape
const L := 0.39018064403


func _geometry(turn: float) -> TunnelGeometry:
	var g := TunnelGeometry.new(PathModel.new(1, L))
	g.turn = turn
	return g


func test_in_shape_is_the_radius_one_16_gon() -> void:
	var g := _geometry(TunnelGeometry.TUBE_TURN)
	for k in 17:
		var a := (8.0 - k) * TAU / 16.0
		var expected := Vector3(sin(a), -cos(a), 0.0)
		check(g.vertex(k, 0).is_equal_approx(expected), "vertex %d: %s vs %s" % [k, g.vertex(k, 0), expected])


func test_flat_shape_is_a_ribbon_16_lanes_wide() -> void:
	var g := _geometry(0.0)
	for k in 17:
		var v := g.vertex(k, 0)
		check_near(v.y, -1.0, 0.0001, "vertex %d height" % k)
		check_near(v.x, (8.0 - k) * L, 0.0001, "vertex %d x" % k)
	check_near(g.vertex(0, 0).distance_to(g.vertex(16, 0)), 16.0 * L, 0.0001, "edges apart")
	check(g.normal(3.5, 0.0).is_equal_approx(Vector3.UP), "flat normal is up")


func test_out_shape_is_a_convex_tube_below() -> void:
	var g := _geometry(-TunnelGeometry.TUBE_TURN)
	# The mirror of the in-tube across the bottom faces: every vertex is 1 from the mirrored centre.
	var mirror_centre := g.vertex(0, 0).lerp(g.vertex(8, 0), 0.5)
	for k in 16:
		check_near(g.vertex(k, 0).distance_to(mirror_centre), 1.0, 0.0001, "vertex %d radius" % k)
	check(g.vertex(0, 0).is_equal_approx(g.vertex(16, 0)), "out tube closes")
	check(g.vertex(0, 0).y < -2.5, "out tube hangs below: %s" % g.vertex(0, 0))
	# Normals point away from the out-tube's centre (riding on its outer surface).
	var n := g.normal(7.5, 0.0)
	var mid := (g.vertex(7, 0) + g.vertex(8, 0)) * 0.5
	check((mid - mirror_centre).normalized().is_equal_approx(n), "outward normal")


func test_lane_width_constant_in_every_shape() -> void:
	for turn in [TunnelGeometry.TUBE_TURN, 0.07, 0.0, -TunnelGeometry.TUBE_TURN]:
		var g := _geometry(turn)
		for k in 16:
			check_near(g.vertex(k, 0).distance_to(g.vertex(k + 1, 0)), L, 0.0001, "turn %f face %d" % [turn, k])


func test_flatness() -> void:
	check_near(_geometry(TunnelGeometry.TUBE_TURN).flatness(), 0.0, 0.0001)
	check_near(_geometry(0.0).flatness(), 1.0, 0.0001)
	check_near(_geometry(-TunnelGeometry.TUBE_TURN * 0.5).flatness(), 0.5, 0.0001)


# --- Track: shape state, seam rules, crashes ---

func _track_in_part(shape: Shape, seed_value: int = 3) -> Array:
	var track := TrackModel.new(80.0, seed_value)
	for i in range(1, 200):
		if track.parts.shape(i) == shape and track.parts.shape(i - 1) != shape:
			return [track, i]
	return [track, -1]


func _place(track: TrackModel, seg: float) -> void:
	track.segment = seg
	track.elapsed = 5.0
	track.step(0.0, 0.0)


func test_morph_progress_and_turn() -> void:
	var found := _track_in_part(Shape.FLAT)
	var track: TrackModel = found[0]
	var start := track.parts.start(found[1])
	_place(track, start + 15.0)
	check_near(track.morph_progress(), 0.5, 0.0001, "halfway")
	check_eq(track.previous_shape(), Shape.IN, "from in")
	check_near(track.geometry.turn, TunnelGeometry.TUBE_TURN * 0.5, 0.0001, "turn halfway")
	_place(track, start + 40.0)
	check_near(track.morph_progress(), 1.0, 0.0001, "done")
	check_near(track.geometry.turn, 0.0, 0.0001, "flat")


func _crosses(track: TrackModel, seg: float) -> bool:
	_place(track, seg)
	track.p = 0.999
	track.step(0.002, 1.0)  # moves 0.0015 sideways and 0.025 segments forward
	return not track.crashed


func test_seam_rules_tube_to_flat() -> void:
	var found := _track_in_part(Shape.FLAT)
	var start: int = found[0].parts.start(found[1])
	for case in [[-50.0, true], [0.0, true], [0.5, true], [0.7, false], [15.0, false], [29.0, false], [60.0, false]]:
		var fresh: TrackModel = _track_in_part(Shape.FLAT)[0]
		check_eq(_crosses(fresh, start + case[0]), case[1], "tube→flat at +%.1f segments" % case[0])


func test_seam_rules_flat_to_tube() -> void:
	for tube in [Shape.IN, Shape.OUT]:
		var found := _track_in_part(tube)
		if found[1] < 0:
			found = _track_in_part(tube, 8)
		var start: int = found[0].parts.start(found[1])
		for case in [[-5.0, false], [15.0, false], [29.3, false], [29.5, true], [30.0, true], [80.0, true]]:
			var fresh: TrackModel = _track_in_part(tube, found[0].seed_value)[0]
			check_eq(_crosses(fresh, start + case[0]), case[1], "flat→%s at +%.1f" % [tube, case[0]])


func test_crash_stops_the_ship() -> void:
	var found := _track_in_part(Shape.FLAT)
	var track: TrackModel = found[0]
	_place(track, track.parts.start(found[1]) + 40.0)
	track.p = -0.999
	track.step(0.01, -1.0)
	check(track.crashed, "drove off the left edge")
	var seg := track.segment
	track.step(0.5, 1.0)
	check_eq(track.segment, seg, "no movement after crash")
	check_near(track.crash_time, 0.5, 0.0001, "crash timer")


func test_flat_parts_bend_at_most_30_degrees() -> void:
	var track := TrackModel.new(80.0, 21)
	track.path.position(6000)
	var flats := 0
	for i in range(1, 60):
		if track.parts.start(i) > 5000:
			break
		if track.parts.shape(i) == Shape.FLAT:
			flats += 1
	check(flats > 3, "has flat parts")
	var flat_turns := 0
	var any_over_30 := false
	for i in track.path.turn_log.size():
		var bend := track.path.turn_log[i]
		if track.parts.shape_at(track.path.turn_segments[i]) == Shape.FLAT:
			flat_turns += 1
			check(bend < 30.0, "flat bend %f" % bend)
		else:
			check(bend < 50.0, "tube bend %f" % bend)
			any_over_30 = any_over_30 or bend >= 30.0
	check(flat_turns > 3, "some turns on flat parts")
	check(any_over_30, "tube parts still allow bends over 30°")


func test_normal_turns_smoothly_across_lanes_in_a_tube() -> void:
	# Regression: the camera "up" used to jump 22.5° at every lane boundary inside tubes.
	var g := _geometry(TunnelGeometry.TUBE_TURN)
	for k in range(1, 16):
		var before := g.normal(k - 0.001, 0.0)
		var after := g.normal(k + 0.001, 0.0)
		check(rad_to_deg(before.angle_to(after)) < 0.1, "jump at lane boundary %d" % k)
	var seam := rad_to_deg(g.normal(15.999, 0.0).angle_to(g.normal(0.001, 0.0)))
	check(seam < 0.1, "jump at the seam: %f°" % seam)


func test_normal_at_lane_centre_is_the_face_normal() -> void:
	var g := _geometry(TunnelGeometry.TUBE_TURN)
	for k in 16:
		var mid := (g.vertex(k, 0) + g.vertex(k + 1, 0)) * 0.5
		var to_centre := (Vector3(0.0, 0.0, mid.z) - mid).normalized()
		check(g.normal(k + 0.5, 0.0).is_equal_approx(to_centre), "lane %d" % k)


func test_flat_edge_lane_16_is_the_left_edge() -> void:
	var g := _geometry(0.0)
	check(g.surface(16.0, 0.0).is_equal_approx(g.vertex(16, 0)), "lane 16 is vertex 16, not vertex 0")
	check(g.normal(16.0, 0.0).is_equal_approx(Vector3.UP), "edge normal stays up on flat")
	check(g.normal(0.0, 0.0).is_equal_approx(Vector3.UP), "right edge normal stays up on flat")
