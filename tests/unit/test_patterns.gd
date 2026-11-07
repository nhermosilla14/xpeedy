extends TestCase

const Shape := PartSequence.Shape
const Kind := Obstacle.Kind
const SAMPLES := 600

## Formation names that exist for each index (ADR 0013).
const NAMES := {
	0: ["single_cube"],
	1: ["single_beam"],
	2: ["wall2_cubes", "wall2_beams", "apart2x8_cubes"],
	3: ["wall3_spikes", "wall3_cubes", "apart3x5_cubes", "diagonal3_cubes"],
	4: ["walls2x2_spikes", "diagonals2x2_cubes"],
	5: ["diagonal2_beams", "apart3x3_cubes"],
	6: ["spread3_cubes", "spread3_cubes_mixed"],
	7: ["pendulum", "diagonals3x2_cubes_two_colours"],
	8: ["apart3x3_cubes"],
	9: ["wall4_spikes", "wall4_cubes", "cross", "spread4_cubes"],
	10: ["wall4_spikes", "wall4_cubes", "spread4_cubes"],
	11: ["diagonals2x3_cubes"],
	12: ["diagonal3_beams", "diagonals2x2_beams"],
	13: ["diagonal8_cubes"],
	14: ["diagonals3x2_cubes_two_colours"],
	15: ["walls3x2_spikes", "wall6_spikes", "walls2x3_spikes", "spread6_cubes"],
}
## Solid cube and beam walls: only generated on flat and outside parts.
const SOLID_WALLS := ["wall2_cubes", "wall2_beams", "wall3_cubes", "wall4_cubes"]
## Formations that wrap around the ring on every shape.
const RING_PREFIXES := ["apart", "spread", "cross"]


func _context(shape: Shape = Shape.IN, spikes: bool = true) -> PatternLibrary.Context:
	var context := PatternLibrary.Context.new()
	context.shape = shape
	context.spikes_enabled = spikes
	return context


func _patterns(index: int, shape: Shape, spikes: bool = true, count: int = SAMPLES, seed_value: int = 1) -> Array[PatternLibrary.Pattern]:
	var rng := XRandom.new(seed_value)
	var context := _context(shape, spikes)
	var result: Array[PatternLibrary.Pattern] = []
	for i in count:
		result.append(PatternLibrary.generate_for_index(index, rng, context))
	return result


func _is_ring(name: String) -> bool:
	for prefix in RING_PREFIXES:
		if name.begins_with(prefix):
			return true
	return false


## Is `lane` at lane offset `offset` from `base`, wrapping around the ring or not?
func _at(lane: int, base: int, offset: int, ring: bool) -> bool:
	if ring:
		return posmod(lane - base - offset, 16) == 0
	return lane - base == offset


func _kind_of(suffix: String) -> Kind:
	match suffix:
		"beams":
			return Kind.BEAM
		"spikes":
			return Kind.SPIKE
	return Kind.CUBE


## Describes why a pattern does not match its formation, or "" when it does.
func _problem(p: PatternLibrary.Pattern, ring: bool) -> String:
	var obstacles := p.obstacles
	var name := p.name
	var base := obstacles[0].lane
	var regex := RegEx.new()
	var colours := {}
	for o in obstacles:
		colours[o.colour] = true
		if o.colour < 0 or o.colour > 4 or o.lane < 0 or o.lane > 15 or o.seg < 0 or o.seg > 8:
			return "%s: out of range (%d, %d, colour %d)" % [name, o.seg, o.lane, o.colour]
	var kinds_ok := func(kind: Kind) -> bool:
		for o in obstacles:
			if o.kind != kind:
				return false
		return true

	if name.begins_with("single_"):
		return "" if obstacles.size() == 1 and obstacles[0].seg == 0 else "%s: not a single obstacle" % name

	regex.compile("^wall(\\d+)_(cubes|beams|spikes)$")
	var m := regex.search(name)
	if m:
		var width := m.get_string(1).to_int()
		if obstacles.size() != width or not kinds_ok.call(_kind_of(m.get_string(2))) or colours.size() != 1:
			return "%s: wrong size, kind or colours" % name
		for i in width:
			if obstacles[i].seg != 0 or not _at(obstacles[i].lane, base, i, ring):
				return "%s: not contiguous at %d" % [name, i]
		return ""

	regex.compile("^walls(\\d+)x(\\d+)_spikes$")
	m = regex.search(name)
	if m:
		var width := m.get_string(1).to_int()
		var starts := [0, 8] if m.get_string(2).to_int() == 2 else [0, 5, 10]
		if obstacles.size() != width * starts.size() or not kinds_ok.call(Kind.SPIKE) or colours.size() != 1:
			return "%s: wrong size, kind or colours" % name
		var i := 0
		for start in starts:
			for w in width:
				if obstacles[i].seg != 0 or not _at(obstacles[i].lane, base, start + w, ring):
					return "%s: wrong lane at %d" % [name, i]
				i += 1
		return ""

	regex.compile("^apart(\\d+)x(\\d+)_cubes$")
	m = regex.search(name)
	if m:
		var count := m.get_string(1).to_int()
		var gap := m.get_string(2).to_int()
		if obstacles.size() != count or not kinds_ok.call(Kind.CUBE) or colours.size() != 1:
			return "%s: wrong size, kind or colours" % name
		for i in count:
			if obstacles[i].seg != 0 or not _at(obstacles[i].lane, base, i * gap, true):
				return "%s: wrong lane at %d" % [name, i]
		return ""

	regex.compile("^diagonals?(\\d+)(?:x(\\d+))?_(cubes|beams)(_two_colours)?$")
	m = regex.search(name)
	if m:
		var length := m.get_string(1).to_int()
		var count := 1 if m.get_string(2) == "" else m.get_string(2).to_int()
		var starts := [0] if count == 1 else ([0, 8] if count == 2 else [0, 5, 10])
		var two_colours := m.get_string(4) != ""
		if obstacles.size() != length * count or not kinds_ok.call(_kind_of(m.get_string(3))):
			return "%s: wrong size or kind" % name
		var direction := 1 if _at(obstacles[1].lane, base, 1, ring) else -1
		if direction == -1 and not _at(obstacles[1].lane, base, -1, ring):
			return "%s: not a diagonal" % name
		var i := 0
		for s in count:
			for k in length:
				if obstacles[i].seg != k or not _at(obstacles[i].lane, base, starts[s] + direction * k, ring):
					return "%s: off the diagonal at %d/%d" % [name, s, k]
				if obstacles[i].colour != obstacles[s * length].colour:
					return "%s: a diagonal changes colour" % name
				i += 1
		if not two_colours and colours.size() != 1:
			return "%s: should be one colour" % name
		return ""

	regex.compile("^spread(\\d+)_cubes(_mixed)?$")
	m = regex.search(name)
	if m:
		var count := m.get_string(1).to_int()
		var mixed := m.get_string(2) != ""
		if obstacles.size() % count != 0 or not kinds_ok.call(Kind.CUBE):
			return "%s: wrong size or kind" % name
		var repeat := obstacles.size() / count
		if repeat < 1 or repeat > (4 if count <= 4 else 1):
			return "%s: repeated %d times" % [name, repeat]
		for r in repeat:
			for i in count:
				var o := obstacles[r * count + i]
				if o.seg != r or not _at(o.lane, base, i * 16 / count, true):
					return "%s: wrong place at %d/%d" % [name, r, i]
		if not mixed and colours.size() != 1:
			return "%s: should be one colour" % name
		return ""

	if name == "pendulum":
		if obstacles.size() != 3 or colours.size() != 1:
			return "pendulum: wrong size or colours"
		var expected := [[0, 0, Kind.CUBE], [1, 4, Kind.BEAM], [2, 8, Kind.CUBE]]
		for i in 3:
			if obstacles[i].seg != expected[i][0] or obstacles[i].kind != expected[i][2] \
					or not _at(obstacles[i].lane, base, expected[i][1], ring):
				return "pendulum: wrong at %d" % i
		return ""

	if name == "cross":
		if obstacles.size() != 2 or colours.size() != 1 or not kinds_ok.call(Kind.BEAM):
			return "cross: wrong size, kind or colours"
		if obstacles[0].seg != 0 or obstacles[1].seg != 1 or not _at(obstacles[1].lane, base, 4, true):
			return "cross: wrong places"
		return ""

	return "unknown formation %s" % name


# --- Choosing the pattern (doc 04, 10) ---

func test_the_index_follows_the_level() -> void:
	var expected := {
		1: range(0, 2), 3: range(0, 4), 5: range(0, 6),
		6: range(1, 7), 10: range(1, 11), 15: range(1, 16), 20: range(1, 16), 40: range(1, 16),
	}
	for level in expected:
		var rng := XRandom.new(level)
		var seen := {}
		for i in 1500:
			seen[PatternLibrary.pick_index(level, rng)] = true
		var keys := seen.keys()
		keys.sort()
		check_eq(keys, expected[level], "indexes at level %d" % level)


func test_single_cubes_stop_after_level_five() -> void:
	var rng := XRandom.new(2)
	for i in 3000:
		check(PatternLibrary.pick_index(6 + i % 20, rng) != 0, "index 0 at level ≥ 6")


func test_level_zero_patterns_are_singles() -> void:
	var rng := XRandom.new(3)
	for i in 200:
		var p := PatternLibrary.generate_detailed(0, rng, _context())
		check(p.name == "single_cube" or p.name == "single_beam", p.name)


# --- Formations ---

func test_every_index_only_generates_its_documented_formations() -> void:
	for index in 16:
		for shape in [Shape.IN, Shape.FLAT, Shape.OUT]:
			for spikes in [true, false]:
				var seen := {}
				for p in _patterns(index, shape, spikes):
					check(NAMES[index].has(p.name), "index %d produced %s" % [index, p.name])
					check_eq(p.index, index)
					seen[p.name] = true
				for name in seen:
					check(spikes or not name.contains("spikes"), "spikes are off but %s appeared" % name)
					check(shape != Shape.IN or not SOLID_WALLS.has(name), "%s in an IN part" % name)


func test_every_documented_formation_appears() -> void:
	for index in 16:
		var seen := {}
		for shape in [Shape.IN, Shape.FLAT]:
			for p in _patterns(index, shape, true, 900, index + 10):
				seen[p.name] = true
		for name in NAMES[index]:
			check(seen.has(name), "index %d never produced %s" % [index, name])


func test_formations_have_the_documented_structure() -> void:
	for index in 16:
		for shape in [Shape.IN, Shape.OUT, Shape.FLAT]:
			for p in _patterns(index, shape, true, 300, index + 40):
				var problem := _problem(p, shape != Shape.FLAT or _is_ring(p.name))
				check(problem == "", problem)


func test_fitting_formations_do_not_wrap_on_flat_parts() -> void:
	var checked := 0
	for index in range(2, 16):
		for p in _patterns(index, Shape.FLAT, true, 400, index + 70):
			if _is_ring(p.name):
				continue
			checked += 1
			var problem := _problem(p, false)
			check(problem == "", "flat part, " + problem)
	check(checked > 1500, "many fitting formations were checked: %d" % checked)


func test_ring_formations_wrap_on_every_shape() -> void:
	var seen_wrap := false
	for index in [2, 3, 5, 6, 8, 9, 10, 15]:
		for p in _patterns(index, Shape.FLAT, true, 600, index + 90):
			if not _is_ring(p.name):
				continue
			check(_problem(p, true) == "", _problem(p, true))
			var lanes := p.obstacles.map(func(o: Obstacle) -> int: return o.lane)
			seen_wrap = seen_wrap or (lanes.max() - lanes.min() > 11)
	check(seen_wrap, "ring formations do use lanes on both sides of the seam")


func test_solid_walls_only_appear_on_flat_and_outside_parts() -> void:
	for shape in [Shape.FLAT, Shape.OUT]:
		var seen := {}
		for index in [2, 3, 9, 10]:
			for p in _patterns(index, shape, true, 400, index + 100):
				seen[p.name] = true
		for name in SOLID_WALLS:
			check(seen.has(name), "%s never appeared on shape %d" % [name, shape])
	for index in [2, 3, 9, 10]:
		for p in _patterns(index, Shape.IN, true, 600, index + 110):
			check(not SOLID_WALLS.has(p.name), "%s in an IN part" % p.name)


func test_variant_chances() -> void:
	var spike_share := func(index: int, shape: Shape, spikes: bool) -> float:
		var patterns := _patterns(index, shape, spikes, 3000, index + 120)
		return float(patterns.filter(func(p: PatternLibrary.Pattern) -> bool: return p.variant == "spike").size()) / 3000.0
	var wall_share := func(index: int, shape: Shape, spikes: bool) -> float:
		var patterns := _patterns(index, shape, spikes, 3000, index + 130)
		return float(patterns.filter(func(p: PatternLibrary.Pattern) -> bool: return p.variant == "wall").size()) / 3000.0
	for index in [3, 4, 9, 10, 15]:
		check_near(spike_share.call(index, Shape.IN, true), 1.0 / 3.0, 0.04, "spike share, index %d" % index)
		check_near(spike_share.call(index, Shape.IN, false), 0.0, 0.0001, "no spikes when disabled, index %d" % index)
	for index in [0, 1, 2, 5, 6, 7, 8, 11, 12, 13, 14]:
		check_near(spike_share.call(index, Shape.FLAT, true), 0.0, 0.0001, "no spike formation at index %d" % index)
	check_near(wall_share.call(3, Shape.FLAT, true), 2.0 / 9.0, 0.04, "walls after the spike draw: 2/3 × 1/3")
	check_near(wall_share.call(3, Shape.FLAT, false), 1.0 / 3.0, 0.04, "walls without spikes: 1/3")
	check_near(wall_share.call(3, Shape.IN, true), 0.0, 0.0001, "no walls in IN parts")
	check_near(wall_share.call(2, Shape.OUT, true), 1.0 / 3.0, 0.04, "walls on outside parts")
	check_near(wall_share.call(5, Shape.FLAT, true), 0.0, 0.0001, "no wall formation at index 5")


func test_colour_rules() -> void:
	var mixed_with_variety := 0
	var two_colour_with_variety := 0
	var checked := 0
	for p in _patterns(6, Shape.IN, true, 600, 7):
		checked += 1
		if p.name == "spread3_cubes_mixed" and (p.obstacles.map(func(o: Obstacle) -> int: return o.colour) as Array).any(func(c: int) -> bool: return c != p.obstacles[0].colour):
			mixed_with_variety += 1
	for p in _patterns(14, Shape.IN, true, 600, 8):
		if p.obstacles.any(func(o: Obstacle) -> bool: return o.colour != p.obstacles[0].colour):
			two_colour_with_variety += 1
	check(checked > 0 and mixed_with_variety > 100, "mixed spreads use several colours: %d" % mixed_with_variety)
	check(two_colour_with_variety > 300, "two-colour diagonals use two colours: %d" % two_colour_with_variety)


func test_no_pattern_blocks_a_whole_ring() -> void:
	for index in 16:
		for shape in [Shape.IN, Shape.OUT, Shape.FLAT]:
			for p in _patterns(index, shape, true, 400, index + 140):
				var blocked := {}
				for o in p.obstacles:
					o.shape = shape
					var lanes := blocked.get(o.seg, []) as Array
					lanes.append(o.lane)
					if o.is_tube_beam():
						lanes.append((o.lane + 8) % 16)
					blocked[o.seg] = lanes
				for seg in blocked:
					var distinct := {}
					for lane in blocked[seg]:
						distinct[lane] = true
					check(distinct.size() <= 12, "%s blocks %d lanes on segment %d" % [p.name, distinct.size(), seg])


func test_the_same_seed_gives_the_same_patterns() -> void:
	for level in [0, 3, 8, 20]:
		var a := XRandom.new(level + 5)
		var b := XRandom.new(level + 5)
		for i in 100:
			var pa := PatternLibrary.generate_detailed(level, a, _context(Shape.FLAT))
			var pb := PatternLibrary.generate_detailed(level, b, _context(Shape.FLAT))
			check_eq(pa.name, pb.name)
			check_eq(pa.obstacles.map(func(o: Obstacle) -> Array: return [o.seg, o.lane, o.kind, o.colour]),
				pb.obstacles.map(func(o: Obstacle) -> Array: return [o.seg, o.lane, o.kind, o.colour]))


# --- In a run (doc 10) ---

## Number of obstacles per pattern, keyed by the pattern's placement point.
func _sizes(field: ObstacleField) -> Dictionary:
	var sizes := {}
	var points := field.placed_points
	for o in field.all():
		var point := 0
		for p in points:
			if p <= o.seg:
				point = p
		sizes[point] = sizes.get(point, 0) + 1
	return sizes


func test_the_run_starts_with_singles_and_gets_denser() -> void:
	var field := ObstacleField.new(4, PartSequence.new(4))
	field.generate_to(5000)
	var sizes := _sizes(field)
	var early := 0
	var early_count := 0
	var late := 0
	var late_count := 0
	for point in sizes:
		if point < 150:
			check_eq(sizes[point], 1, "level 0 pattern at %d" % point)
			early += sizes[point]
			early_count += 1
		elif point >= 2250:
			late += sizes[point]
			late_count += 1
	check(early_count > 5, "several early patterns")
	check(float(late) / late_count > 3.0, "later patterns are bigger: %f obstacles each" % (float(late) / late_count))


func test_single_cubes_disappear_from_segment_900() -> void:
	for seed_value in range(1, 6):
		var field := ObstacleField.new(seed_value, PartSequence.new(seed_value))
		field.generate_to(6000)
		var sizes := _sizes(field)
		var singles_before := 0
		for o in field.all():
			if sizes[_point_of(field, o)] == 1 and o.kind == Kind.CUBE:
				check(o.seg < 900, "a single cube at %d" % o.seg)
				singles_before += 1
		check(singles_before > 0 or seed_value > 1, "single cubes do appear early")


func _point_of(field: ObstacleField, o: Obstacle) -> int:
	var point := 0
	for p in field.placed_points:
		if p <= o.seg:
			point = p
	return point


func test_the_instance_budget_is_enough() -> void:
	for seed_value in range(1, 5):
		var field := ObstacleField.new(seed_value, PartSequence.new(seed_value))
		field.generate_to(8000)
		var by_segment := {}
		for o in field.all():
			by_segment[o.seg] = by_segment.get(o.seg, []) + [o.kind]
		for first in range(0, 8000, 5):
			var counts := [0, 0, 0]
			for seg in range(first, first + TrackModel.VISIBLE_SEGMENTS + 8):
				for kind in by_segment.get(seg, []):
					counts[kind] += 1
			for kind in 3:
				check(counts[kind] <= ObstacleView.MAX_INSTANCES, "%d of kind %d from segment %d" % [counts[kind], kind, first])


func test_spikes_can_be_turned_off_for_a_run() -> void:
	var field := ObstacleField.new(6, PartSequence.new(6), false)
	field.generate_to(8000)
	for o in field.all():
		check(o.kind != Kind.SPIKE, "spike at %d with spikes disabled" % o.seg)
	var with_spikes := ObstacleField.new(6, PartSequence.new(6), true)
	with_spikes.generate_to(8000)
	check(with_spikes.all().any(func(o: Obstacle) -> bool: return o.kind == Kind.SPIKE), "spikes appear when enabled")
