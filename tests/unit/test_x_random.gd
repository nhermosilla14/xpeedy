extends TestCase


func test_reference_sequence() -> void:
	# Expected values come from an independent Python implementation of the same algorithm.
	var expected := {
		0: [3809008728, 1133695204, 53579671, 2891528803, 139681546],
		12345: [518667457, 440444462, 4232892992, 3757857622, 3939018813],
	}
	for seed_value in expected:
		var rng := XRandom.new(seed_value)
		var got := []
		for i in 5:
			got.append(rng.next_u32())
		check_eq(got, expected[seed_value], "seed %d:" % seed_value)


func test_same_seed_same_sequence() -> void:
	var a := XRandom.new(42)
	var b := XRandom.new(42)
	for i in 1000:
		check_eq(a.next_u32(), b.next_u32())


func test_range_int_excludes_upper_bound() -> void:
	var rng := XRandom.new(7)
	var seen := {}
	for i in 2000:
		var v := rng.range_int(1, 3)
		check(v >= 1 and v < 3, "out of range: %d" % v)
		seen[v] = true
	check_eq(seen.size(), 2, "both values should appear")


func test_float_in_unit_interval() -> void:
	var rng := XRandom.new(99)
	for i in 2000:
		var f := rng.next_float()
		check(f >= 0.0 and f < 1.0, "out of range: %f" % f)
