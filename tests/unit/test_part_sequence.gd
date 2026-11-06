extends TestCase

const Shape := PartSequence.Shape
const PARTS := 400


func _sequence(seed_value: int) -> PartSequence:
	var seq := PartSequence.new(seed_value)
	seq.index_at(1_000_000)  # force generation of many parts
	return seq


func _count(seq: PartSequence) -> int:
	var n := 0
	while seq.start(n) < 1_000_000:
		n += 1
	return n


func test_first_part_is_in_and_long_enough() -> void:
	for seed_value in [1, 2, 3, 4, 5]:
		var seq := _sequence(seed_value)
		check_eq(seq.shape(0), Shape.IN, "seed %d" % seed_value)
		check(seq.length(0) >= 200, "first part length %d" % seq.length(0))


func test_lengths_are_multiples_of_120_and_parts_contiguous() -> void:
	var seq := _sequence(11)
	for i in _count(seq) - 1:
		check_eq(seq.length(i) % 120, 0, "part %d length" % i)
		check_eq(seq.start(i + 1), seq.start(i) + seq.length(i), "part %d contiguous" % i)


func test_transition_rules() -> void:
	var seq := _sequence(12)
	for i in _count(seq) - 1:
		var a := seq.shape(i)
		var b := seq.shape(i + 1)
		check(a != b, "consecutive parts differ (in is extended instead), part %d" % i)
		if a == Shape.OUT or a == Shape.IN:
			check_eq(b, Shape.FLAT, "after a tube comes flat, part %d" % i)
		check(not (a == Shape.FLAT and b == Shape.FLAT), "no flat after flat")


func test_tube_choice_after_flat() -> void:
	var seq := _sequence(13)
	var after_in := [0, 0]   # [in, out] chosen when the previous tube was in
	var after_out := [0, 0]  # same, previous tube out
	var last_tube := Shape.IN
	for i in _count(seq):
		var s := seq.shape(i)
		if s == Shape.FLAT:
			continue
		if i > 0:
			var bucket: Array = after_out if last_tube == Shape.OUT else after_in
			bucket[0 if s == Shape.IN else 1] += 1
		last_tube = s
	var in_share_after_in: float = float(after_in[0]) / (after_in[0] + after_in[1])
	var in_share_after_out: float = float(after_out[0]) / (after_out[0] + after_out[1])
	check(after_in[0] + after_in[1] > 300, "enough samples")
	check_near(in_share_after_in, 0.5, 0.08, "in after flat (prev in)")
	check_near(in_share_after_out, 0.75, 0.08, "in after flat (prev out)")


func test_in_parts_extend_half_the_time() -> void:
	var seq := _sequence(14)
	var in_parts := 0
	var units := 0
	for i in range(1, _count(seq) - 1):
		if seq.shape(i) == Shape.IN:
			in_parts += 1
			units += seq.length(i) / 120
	# Geometric: mean number of 120-blocks = 1 / (1 - 0.5) = 2.
	check_near(float(units) / in_parts, 2.0, 0.25, "mean in-part blocks")


func test_same_seed_same_sequence() -> void:
	var a := _sequence(77)
	var b := _sequence(77)
	for i in 200:
		check_eq([a.shape(i), a.start(i)], [b.shape(i), b.start(i)], "part %d" % i)


func test_order_of_requests_does_not_matter() -> void:
	var a := PartSequence.new(5)
	var b := PartSequence.new(5)
	for seg in [10, 500, 2000, 5000]:
		a.index_at(seg)
	b.index_at(5000)
	for i in 30:
		check_eq([a.shape(i), a.start(i)], [b.shape(i), b.start(i)], "part %d" % i)
