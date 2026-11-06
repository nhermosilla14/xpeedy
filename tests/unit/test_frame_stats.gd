extends TestCase


func test_describe_steady_30fps() -> void:
	var times := PackedFloat32Array()
	for i in 300:
		times.append(1.0 / 30.0)
	check_eq(FrameStats.describe(times), "avg=30.0 fps low1%=30.0 fps frames=300")


func test_one_percent_low_catches_hitches() -> void:
	var times := PackedFloat32Array()
	for i in 95:
		times.append(1.0 / 60.0)
	for i in 5:
		times.append(0.1)
	var text := FrameStats.describe(times)
	check(text.contains("low1%=10.0 fps"), text)


func test_empty() -> void:
	check_eq(FrameStats.describe(PackedFloat32Array()), "no frames")
