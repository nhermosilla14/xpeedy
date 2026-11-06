extends TestCase


func test_speed_starts_at_300_and_reaches_target_at_one_second() -> void:
	var track := TrackModel.new(80.0)
	check_near(track.speed_at(0.0), 300.0, 0.001, "start")
	check_near(track.speed_at(1.0), 80.0, 0.001, "at 1 s")
	check_near(track.speed_at(5.0), 80.0, 0.001, "later")
	check(track.speed_at(0.5) < 190.0, "ease-out should be past the midpoint at 0.5 s")


func test_start_position() -> void:
	var track := TrackModel.new()
	check_near(track.segment, 3.5, 0.0001, "segment")
	check_near(track.lane_position(), 7.5, 0.0001, "lane position")


func test_lane_position_formula() -> void:
	var track := TrackModel.new()
	for p in [-1.0, -0.5, 0.0, 0.25, 0.999]:
		track.p = p
		check_near(track.lane_position(), (1.0 - p) * 8.0, 0.0001, "p=%f" % p)


func test_steering_rate() -> void:
	var track := TrackModel.new()
	var before := track.p
	track.step(0.5, 1.0)
	check_near(track.p - before, 0.5 * 0.75, 0.0001, "dp")
	check(track.lane_position() < 7.5, "positive steer moves to lower lanes")


func test_wraps_in_tube() -> void:
	var track := TrackModel.new()
	track.p = 0.99
	track.step(0.1, 1.0)
	check_near(track.p, 0.99 + 0.075 - 2.0, 0.0001, "wrap +1 to -1")
	track.p = -0.99
	track.step(0.1, -1.0)
	check_near(track.p, -0.99 - 0.075 + 2.0, 0.0001, "wrap -1 to +1")


func test_forward_motion_matches_speed() -> void:
	var track := TrackModel.new(80.0)
	track.elapsed = 2.0
	var before := track.segment
	track.step(1.0 / 60.0, 0.0)
	check_near(track.segment - before, (1.0 / 60.0) * 1000.0 / 80.0, 0.0001, "segments per tick")


func test_clock_caps_long_frames() -> void:
	var clock := RunClock.new()
	clock.advance(0.016)
	check_near(clock.advance(0.5), 0.016, 0.00001, "stall replaced by previous frame")
	check_near(clock.advance(0.2), 0.2, 0.00001, "200 ms is allowed")


func test_clock_scale() -> void:
	var clock := RunClock.new()
	clock.scale = 0.75
	check_near(clock.advance(0.02), 0.015, 0.00001, "scaled")


func test_response_curve_and_invert() -> void:
	var steering := Steering.new()
	check_near(steering.process(1.0), 1.0, 0.0001, "full")
	check_near(steering.process(-0.5), -pow(0.5, 0.66), 0.0001, "half left")
	check_near(steering.process(0.0), 0.0, 0.0001, "zero")
	steering.invert = true
	check_near(steering.process(1.0), -1.0, 0.0001, "inverted")


func test_lane_width_equals_segment_length() -> void:
	var a := TunnelGeometry.vertex(0, 0.0)
	var b := TunnelGeometry.vertex(1, 0.0)
	check_near(a.distance_to(b), TrackModel.SEGMENT_LENGTH, 0.0001, "lane width")
	check_near(TrackModel.SEGMENT_LENGTH, 0.390, 0.001, "≈ 0.390")
