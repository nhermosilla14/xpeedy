extends TestCase

const SAMPLE := """
# a comment
SPEED: 130
Track: random:1400   # trailing comment
obstacles: cubes, beams, spikes, 20-30, 4
bonuses: shields, 60-100, 1-2
zones: gravity@300, nebula@1000
seed: 42
define: a, 0, true, 1,0,0,0
constructs: a@100
"""


func _parse(text: String) -> RaceSpec:
	return RaceParser.parse(text)


func test_a_full_file() -> void:
	var spec := _parse(SAMPLE)
	check_eq(spec.error, "")
	check_eq(spec.speed, 130)
	check_near(spec.target_tps(), 113.1, 0.0001, "130 is really 113 ms")
	check_eq(spec.random_length, 1400)
	check_eq(spec.run_length(), 1400)
	check(spec.cubes and spec.beams and spec.spikes and not spec.rollers and not spec.bouncers, "types")
	check_eq(spec.obstacle_spacing, Vector2i(20, 30))
	check_eq(spec.level, 4)
	check(spec.has_spots and spec.shields and not spec.bonuses, "shields only")
	check_eq(spec.spot_spacing, Vector2i(60, 100))
	check_eq(spec.group_size, Vector2i(1, 2))
	check_eq(spec.zone_mode, RaceSpec.ZoneMode.FIXED)
	check_eq(spec.fixed_zones, [Vector2i(2, 300), Vector2i(4, 1000)] as Array[Vector2i])
	check_eq(spec.seed_value, 42)


func test_an_explicit_track_sums_its_parts() -> void:
	var spec := _parse("speed: 120\ntrack: in:200, flat:60, out:200, flat:100, in:200\nobstacles: cubes, 10-30, 4\n")
	check_eq(spec.error, "")
	check_eq(spec.parts.size(), 5)
	check_eq(spec.parts[0], Vector2i(PartSequence.Shape.IN, 200))
	check_eq(spec.parts[2], Vector2i(PartSequence.Shape.OUT, 200))
	check_eq(spec.run_length(), 760)


func test_all_enables_every_obstacle_type_and_every_bonus_kind() -> void:
	var spec := _parse("speed: 80\ntrack: in:100\nobstacles: all, 8-20, 7\nbonuses: all, 20-60, 1-3\nzones: random, all, 200-250\n")
	check_eq(spec.error, "")
	check(spec.cubes and spec.beams and spec.rollers and spec.bouncers and spec.spikes, "all types")
	check(spec.shields and spec.bonuses, "all kinds")
	check_eq(spec.zone_mode, RaceSpec.ZoneMode.RANDOM)
	check_eq(spec.allowed_zones.size(), 5)
	check_eq(spec.zone_spacing, Vector2i(200, 250))


func test_random_zones_with_a_list() -> void:
	var spec := _parse("speed: 110\ntrack: in:1000\nobstacles: cubes, 15-25, 5\nzones: random, blackout, gravity, hueshift, 150-250\n")
	check_eq(spec.allowed_zones, [1, 2, 3] as Array[int])
	check_eq(spec.zone_spacing, Vector2i(150, 250))


func test_a_missing_bonuses_or_zones_line_means_none() -> void:
	var spec := _parse("speed: 130\ntrack: in:500\nobstacles: cubes, 20-30, 4\n")
	check(not spec.has_spots, "no spots")
	check_eq(spec.zone_mode, RaceSpec.ZoneMode.NONE)
	check_eq(spec.seed_value, -1)


func test_equal_range_bounds_mean_exactly_that_value() -> void:
	var spec := _parse("speed: 80\ntrack: in:100\nobstacles: cubes, 12-12, 4\nzones: random, all, 500-500\n")
	check_eq(spec.obstacle_spacing, Vector2i(12, 12))
	check_eq(spec.zone_spacing, Vector2i(500, 500))
	var rng := XRandom.new(1)
	check_eq(rng.range_int(spec.obstacle_spacing.x, spec.obstacle_spacing.y), 12)


func test_malformed_files_are_rejected_with_a_reason() -> void:
	var good := "speed: 100\ntrack: in:100\nobstacles: cubes, 10-20, 3\n"
	for bad in [
			"speed: fast\ntrack: in:100\nobstacles: cubes, 10-20, 3\n",
			"speed: 100\ntrack: sideways:100\nobstacles: cubes, 10-20, 3\n",
			"speed: 100\ntrack: in:100\nobstacles: beams, 10-20, 3\n",
			"speed: 100\ntrack: in:100\nobstacles: cubes, 10-20\n",
			"speed: 100\nspeed: 90\ntrack: in:100\nobstacles: cubes, 10-20, 3\n",
			"speed: 100\ntrack: in:100\n",
			"speed 100\n",
			good + "zones: lava@100\n",
			good + "bonuses: shields, 10-20\n",
			good + "colour: red\n",
			]:
		var spec := _parse(bad)
		check(spec.error != "", "rejected: %s" % bad.replace("\n", " | "))
	check_eq(_parse(good).error, "")


func test_all_48_races_load_in_order() -> void:
	var catalogue := StageCatalogue.new()
	for stage in range(1, 5):
		check_eq(catalogue.race_count(stage), 12, "stage %d" % stage)
	check_eq(catalogue.race(1, 1).speed, 130)
	check_eq(catalogue.race(1, 1).run_length(), 500)
	check_eq(catalogue.race(1, 3).run_length(), 760)
	check_eq(catalogue.race(2, 8).run_length(), 1800)
	check_eq(catalogue.race(3, 3).run_length(), 150 + 150 + 250 + 150 + 150 + 150 + 150 + 150 + 250 + 250 + 300)
	check_eq(catalogue.race(4, 12).run_length(), 1000 + 100 + 500 + 100 + 1000)
	check(catalogue.race(1, 13) == null, "no race 13")
	check(catalogue.race(5, 1) == null, "no stage 5")


func test_catalogue_spot_checks_against_the_table() -> void:
	var catalogue := StageCatalogue.new()
	var r12 := catalogue.race(1, 2)
	check_eq(r12.zone_mode, RaceSpec.ZoneMode.FIXED)
	check_eq(r12.fixed_zones, [Vector2i(1, 300)] as Array[Vector2i])
	var r19 := catalogue.race(1, 9)
	check_eq(r19.fixed_zones.size(), 3)
	check(r19.rollers and r19.bouncers and not r19.beams, "1-9 types")
	var r22 := catalogue.race(2, 2)
	check(r22.shields and r22.bonuses, "2-2 all kinds")
	var r23 := catalogue.race(2, 3)
	check(r23.bonuses and not r23.shields, "2-3 bonuses only")
	check_eq(r23.allowed_zones.size(), 4)
	check_eq(catalogue.race(3, 12).level, 15)
	check_eq(catalogue.race(4, 10).speed, 48)
	check_eq(catalogue.race(1, 1).has_spots, false)
	check_eq(catalogue.race(2, 9).fixed_zones.size(), 4)


func test_every_race_has_the_fields_the_generators_need() -> void:
	var catalogue := StageCatalogue.new()
	for stage in range(1, 5):
		for race in range(1, 13):
			var spec := catalogue.race(stage, race)
			check(spec != null and spec.speed > 0 and spec.run_length() > 0 and spec.cubes, "race %d-%d" % [stage, race])
			check(spec.obstacle_spacing.x >= 8 and spec.obstacle_spacing.y >= spec.obstacle_spacing.x, "spacing %d-%d" % [stage, race])
			check(spec.level >= 4 and spec.level <= 15, "level %d-%d" % [stage, race])


func test_a_missing_file_ends_a_stage() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://catalogue_test"))
	for race in [1, 2, 4]:
		var file := FileAccess.open("user://catalogue_test/stage_1_%d.txt" % race, FileAccess.WRITE)
		file.store_string("speed: 100\ntrack: in:100\nobstacles: cubes, 10-20, 3\n")
		file.close()
	var catalogue := StageCatalogue.new("user://catalogue_test")
	check_eq(catalogue.race_count(1), 2)
	check_eq(catalogue.race_count(2), 0)
	for race in [1, 2, 4]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://catalogue_test/stage_1_%d.txt" % race))
