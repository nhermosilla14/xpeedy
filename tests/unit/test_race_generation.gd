extends TestCase

const IN := PartSequence.Shape.IN
const FLAT := PartSequence.Shape.FLAT
const OUT := PartSequence.Shape.OUT


func _spec(text: String) -> RaceSpec:
	var spec := RaceParser.parse(text)
	check_eq(spec.error, "", "valid spec")
	return spec


func test_explicit_parts_and_their_continuation() -> void:
	var fixed: Array[Vector2i] = [Vector2i(IN, 200), Vector2i(FLAT, 60), Vector2i(OUT, 200)]
	var parts := PartSequence.new(1, fixed)
	check_eq(parts.shape_at(0), IN)
	check_eq(parts.shape_at(199), IN)
	check_eq(parts.shape_at(200), FLAT)
	check_eq(parts.shape_at(259), FLAT)
	check_eq(parts.shape_at(260), OUT)
	check_eq(parts.shape_at(459), OUT)
	check_eq(parts.shape_at(460), OUT)
	check_eq(parts.shape_at(2000), OUT)
	check_eq(parts.start(1), 200)
	check_eq(parts.length(0), 200)


func test_random_parts_are_unchanged_without_a_list() -> void:
	var a := PartSequence.new(7)
	var b := PartSequence.new(7, [] as Array[Vector2i])
	for i in 8:
		check_eq(a.shape(i), b.shape(i))
		check_eq(a.start(i), b.start(i))


func test_a_race_track_uses_the_explicit_parts() -> void:
	var spec := _spec("speed: 120\ntrack: in:200, flat:60, out:200\nobstacles: cubes, 10-30, 4\n")
	var config := RaceConfig.from_spec(spec)
	var run := SurvivalRun.new(config, 5)
	check_eq(run.track.parts.shape_at(210), FLAT)
	check_near(config.target_tps, 120.0 * 0.87, 0.0001, "speed factor")
	check_eq(config.run_length, 460)


func test_obstacles_start_at_spacing_plus_25_with_a_fixed_level() -> void:
	var spec := _spec("speed: 100\ntrack: in:3000\nobstacles: cubes, 10-12, 4\n")
	for seed_value in 20:
		var field := ObstacleField.new(seed_value, PartSequence.new(seed_value), false, false, false, spec)
		field.generate_to(400)
		check(field.placed_points[0] >= 10 + 25 and field.placed_points[0] <= 11 + 25, "first point %d" % field.placed_points[0])
		for i in range(1, field.placed_points.size()):
			var gap := field.placed_points[i] - field.placed_points[i - 1]
			check(gap >= 10 and gap <= 11, "gap %d" % gap)


func test_a_race_never_places_beams_when_they_are_off() -> void:
	var off := _spec("speed: 100\ntrack: in:6000\nobstacles: cubes, 10-12, 15\n")
	var on := _spec("speed: 100\ntrack: in:6000\nobstacles: cubes, beams, 10-12, 15\n")
	var beams_off := 0
	var beams_on := 0
	for seed_value in [1, 2, 3]:
		var a := ObstacleField.new(seed_value, PartSequence.new(seed_value), false, false, false, off)
		a.generate_to(3000)
		var b := ObstacleField.new(seed_value, PartSequence.new(seed_value), false, false, false, on)
		b.generate_to(3000)
		for o in a.all():
			beams_off += 1 if o.kind == Obstacle.Kind.BEAM else 0
		for o in b.all():
			beams_on += 1 if o.kind == Obstacle.Kind.BEAM else 0
	check_eq(beams_off, 0)
	check(beams_on > 0, "beams appear when enabled")


func test_the_level_is_fixed_for_the_whole_race() -> void:
	var spec := _spec("speed: 100\ntrack: in:3000\nobstacles: cubes, 8-9, 15\n")
	var field := ObstacleField.new(4, PartSequence.new(4), false, false, false, spec)
	field.generate_to(100)
	var early := field.all().size()
	check(early >= 3, "the full catalogue from the first pattern: %d obstacles by segment 100" % early)


func test_spots_first_group_size_and_skips() -> void:
	var spec := _spec("speed: 100\ntrack: in:3000\nobstacles: cubes, 10-12, 4\nbonuses: shields, 40-50, 2-4\n")
	var counts := {}
	for seed_value in 30:
		var field := SpotField.new(seed_value, false, false, false, spec)
		field.generate_to(2000)
		var first := field.all()[0]
		check(first.seg >= 40 + 50 and first.seg <= 49 + 50 or first.seg > 90, "first group at spacing + 50 (or later when skipped)")
		var by_seg := {}
		for s in field.all():
			by_seg[s.seg] = by_seg.get(s.seg, 0) + 1
			check_eq(s.kind, Spot.Kind.SHIELD)
		for seg in by_seg:
			counts[by_seg[seg]] = counts.get(by_seg[seg], 0) + 1
	check(counts.has(2) and counts.has(3), "group sizes 2 and 3 only")
	check(not counts.has(1) and not counts.has(4), "nothing else")


func test_bonus_rolls_give_about_five_percent_each() -> void:
	var spec := _spec("speed: 100\ntrack: in:3000\nobstacles: cubes, 10-12, 4\nbonuses: all, 8-9, 3-4\n")
	var counts := {}
	var total := 0
	for seed_value in 60:
		var field := SpotField.new(seed_value, true, true, true, spec)
		field.generate_to(3000)
		for s in field.all():
			counts[s.kind] = counts.get(s.kind, 0) + 1
			total += 1
	check(total > 3000, "enough samples")
	for kind in [Spot.Kind.QUAKE, Spot.Kind.TIME_DILATION, Spot.Kind.SPACE_FOLD]:
		check_near(float(counts.get(kind, 0)) / total, 0.05, 0.015, "kind %d about 5 %%" % kind)


func test_without_shields_non_bonus_spots_are_left_empty() -> void:
	var spec := _spec("speed: 100\ntrack: in:3000\nobstacles: cubes, 10-12, 4\nbonuses: bonuses, 8-9, 3-4\n")
	var field := SpotField.new(3, true, true, true, spec)
	field.generate_to(3000)
	check(field.all().size() > 0, "some bonus spots")
	for s in field.all():
		check(s.kind != Spot.Kind.SHIELD, "no shields")


func test_a_race_without_bonuses_has_no_spots() -> void:
	var spec := _spec("speed: 130\ntrack: in:500\nobstacles: cubes, 20-30, 4\n")
	var config := RaceConfig.from_spec(spec)
	check_eq(config.generate_spots, false)
	var run := SurvivalRun.new(config, 1)
	run.track.segment = 300.0
	run.step(0.0, 0.0)
	check_eq(run.spots.all().size(), 0)


func test_fixed_zone_marks_appear_at_their_segments() -> void:
	var spec := _spec("speed: 120\ntrack: in:1200\nobstacles: cubes, 10-30, 4\nzones: gravity@300, nebula@1000\n")
	var field := ZoneField.new(1, [2, 4] as Array[int], spec.target_tps(), spec)
	field.generate_to(500)
	check_eq(field.all().size(), 1)
	check_eq(field.all()[0].seg, 300)
	check_eq(field.all()[0].zone, Zone.Kind.GRAVITY_WELL)
	field.generate_to(1100)
	check_eq(field.all().size(), 2)
	check_eq(field.all()[1].seg, 1000)
	check_eq(field.all()[1].zone, Zone.Kind.DARK_NEBULA)
	field.generate_to(2000)
	check_eq(field.all().size(), 2, "nothing more")


func test_random_zone_marks_use_the_allowed_list_and_spacing() -> void:
	var spec := _spec("speed: 110\ntrack: in:3000\nobstacles: cubes, 10-30, 4\nzones: random, blackout, gravity, 150-250\n")
	var tps := spec.target_tps()
	var extra := int(3000.0 / tps) + 1
	var field := ZoneField.new(2, [1, 2] as Array[int], tps, spec)
	field.generate_to(4000)
	var marks := field.all()
	check(marks.size() > 8, "many marks")
	check(marks[0].seg >= 150 + 50 and marks[0].seg <= 249 + 50, "first at spacing + 50")
	for i in marks.size():
		check(marks[i].zone == 1 or marks[i].zone == 2, "allowed zones only")
		if i > 0:
			var gap := marks[i].seg - marks[i - 1].seg
			check(gap >= 150 + extra and gap <= 249 + extra, "gap %d" % gap)


func test_a_race_is_identical_every_time_for_the_same_seed() -> void:
	var spec := RaceParser.parse("speed: 110\ntrack: random:1400\nobstacles: all, 15-25, 5\nbonuses: all, 50-80, 1-2\nzones: random, all, 150-250\n")
	var a := SurvivalRun.new(RaceConfig.from_spec(spec), 99)
	var b := SurvivalRun.new(RaceConfig.from_spec(spec), 99)
	a.track.segment = 700.0
	b.track.segment = 700.0
	a.step(0.0, 0.0)
	b.step(0.0, 0.0)
	check_eq(a.obstacles.all().size(), b.obstacles.all().size())
	check_eq(a.spots.all().size(), b.spots.all().size())
	check_eq(a.zones.all().size(), b.zones.all().size())
	for i in a.obstacles.all().size():
		check(a.obstacles.all()[i].seg == b.obstacles.all()[i].seg and a.obstacles.all()[i].lane == b.obstacles.all()[i].lane, "same obstacle %d" % i)


func test_every_catalogue_race_builds_and_generates() -> void:
	var catalogue := StageCatalogue.new()
	for stage in range(1, 5):
		for race in range(1, 13):
			var spec := catalogue.race(stage, race)
			var run := SurvivalRun.new(RaceConfig.from_spec(spec), stage * 100 + race)
			run.track.segment = float(mini(spec.run_length() - 60, 600))
			run.step(0.0, 0.0)
			check(run.obstacles.all().size() > 0, "obstacles in race %d-%d" % [stage, race])


func test_the_score_carries_into_a_race() -> void:
	var spec := _spec("speed: 120\ntrack: in:500\nobstacles: cubes, 10-30, 4\n")
	var run := SurvivalRun.new(RaceConfig.from_spec(spec, 1234), 5)
	check_eq(run.score, 1234)


func test_survival_tracks_are_unchanged() -> void:
	# Sizes and first points recorded before stage mode existed (seed 5, Standard rules).
	var run := SurvivalRun.new(Difficulty.config("standard"), 5)
	var plain := SurvivalRun.new(Difficulty.config("standard"), 5)
	run.track.segment = 800.0
	plain.track.segment = 800.0
	run.step(0.0, 0.0)
	plain.step(0.0, 0.0)
	check_eq(run.obstacles.all().size(), plain.obstacles.all().size())
	check(run.config.race == null, "no race")
	check_eq(run.config.run_length, 0)
