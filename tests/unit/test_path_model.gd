extends TestCase

const L := 0.39018064403  # 2·sin(π/16)
const SEGMENTS := 3000


func _path(seed_value: int = 1) -> PathModel:
	var path := PathModel.new(seed_value, L)
	path.position(SEGMENTS)
	return path


func test_segments_have_equal_length() -> void:
	var path := _path()
	for s in SEGMENTS:
		check_near(path.position(s).distance_to(path.position(s + 1)), L, 0.002, "segment %d" % s)


func test_starts_straight_for_about_30_segments() -> void:
	var path := _path()
	for s in 29:
		check_near(path.forward(s).angle_to(Vector3.FORWARD), 0.0, 0.0001, "segment %d" % s)
		check_near(path.position(s).x, 0.0, 0.0001, "segment %d x" % s)


func test_spacing_between_10_and_20() -> void:
	var path := _path()
	check(path.spacing_log.size() > 100, "enough control points")
	for d in path.spacing_log:
		check(d >= 10.0 and d < 20.0, "spacing %f" % d)


func test_turns_within_limits() -> void:
	for seed_value in [1, 2, 3]:
		var path := _path(seed_value)
		check(path.turn_log.size() > 20, "seed %d made turns" % seed_value)
		for bend in path.turn_log:
			check(bend > 10.0 and bend < 50.0, "bend %f" % bend)


func test_flat_limit_respected() -> void:
	var path := PathModel.new(5, L)
	path.max_bend_deg = 30.0
	path.position(SEGMENTS)
	for bend in path.turn_log:
		check(bend > 10.0 and bend < 30.0, "bend %f" % bend)


func test_about_half_the_control_points_are_straight() -> void:
	var path := _path(9)
	var points := path.spacing_log.size()
	var turns := path.turn_log.size()
	# 50 % go straight up front; some turn attempts also fall back to straight after 6 rejections.
	check(turns > points * 0.25 and turns < points * 0.55, "%d turns of %d points" % [turns, points])


func test_same_seed_same_path() -> void:
	var a := _path(42)
	var b := _path(42)
	for s in range(0, SEGMENTS, 7):
		check_eq(a.position(s), b.position(s), "segment %d" % s)
	var c := _path(43)
	check(a.position(SEGMENTS) != c.position(SEGMENTS), "different seeds should differ")


func test_frames_are_orthonormal() -> void:
	var path := _path()
	for s in SEGMENTS:
		check_near(path.up(s).length(), 1.0, 0.0001, "|up| at %d" % s)
		check_near(path.up(s).dot(path.forward(s)), 0.0, 0.0001, "up·fwd at %d" % s)


func test_no_twist() -> void:
	# Minimal rotation: from one segment to the next, "up" never turns around the forward axis.
	var path := _path()
	for s in SEGMENTS:
		var change := path.up(s + 1) - path.up(s)
		check_near(change.dot(path.right(s)), 0.0, 0.002, "twist at %d" % s)


func test_forget_before_keeps_later_frames() -> void:
	var path := _path()
	var expected := path.position(500)
	path.forget_before(400)
	check_eq(path.position(500), expected)
	check_eq(path.position(400) != Vector3.ZERO, true, "frame 400 kept")


func test_ring_matches_vertex() -> void:
	var geometry := TunnelGeometry.new(_path())
	for seg in [0, 37, 500]:
		var ring := geometry.ring(seg)
		check_eq(ring.size(), 17, "ring size")
		for k in 17:
			check(ring[k].is_equal_approx(geometry.vertex(k, seg)), "seg %d vertex %d" % [seg, k])
