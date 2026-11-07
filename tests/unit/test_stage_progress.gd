extends TestCase

const PATH := "user://test_stages.cfg"


func _clean() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func _config(run_length: int) -> RunConfig:
	var config := RunConfig.standard()
	config.run_length = run_length
	config.generate_obstacles = false
	config.generate_spots = false
	return config


func test_a_race_finishes_at_its_run_length_and_stops() -> void:
	var run := SurvivalRun.new(_config(60), 3)
	run.track.elapsed = 5.0
	var events := 0
	for i in 2000:
		run.step(1.0 / 60.0, 0.0)
		for e in run.take_events():
			events += 1 if e.kind == RunEvent.Kind.RACE_FINISHED else 0
		if run.finished:
			break
	check(run.finished, "finished")
	check(run.track.segment >= 60.0 and run.track.segment < 61.0, "at the run length")
	check_eq(events, 1)
	var stopped := run.track.segment
	var score := run.score
	for i in 120:
		run.step(1.0 / 60.0, 0.0)
	check_eq(run.track.segment, stopped)
	check_eq(run.score, score)
	check_eq(run.take_events().size(), 0)


func test_survival_never_finishes() -> void:
	var run := SurvivalRun.new(_config(0), 3)
	run.track.elapsed = 5.0
	for i in 600:
		run.step(1.0 / 60.0, 0.0)
	check(not run.finished, "endless")


func test_the_finish_line_is_painted_before_the_end() -> void:
	var run := SurvivalRun.new(_config(100), 3)
	run.track.segment = 60.0
	run.track.elapsed = 5.0
	run.step(1.0 / 60.0, 0.0)
	for lane in 16:
		check_eq(run.trails.texel(98, lane).a, float(TrailMap.FINISH_CODE), "lane %d" % lane)
	check_eq(run.trails.texel(97, 3).a, 0.0)


func test_the_carried_score_adds_to_the_race_score() -> void:
	var config := _config(500)
	config.start_score = 1000
	var run := SurvivalRun.new(config, 3)
	run.track.elapsed = 5.0
	for i in 300:
		run.step(1.0 / 60.0, 0.0)
	check(run.score > 1000, "distance adds to the carried score")


func test_progress_unlocking_and_next_race() -> void:
	_clean()
	var progress := StageProgress.new(PATH)
	check(progress.is_unlocked(1), "stage 1 is open")
	check(not progress.is_unlocked(2), "stage 2 is locked")
	check_eq(progress.next_race(1), 1)
	for race in range(1, 13):
		progress.finish_race(1, race, race * 100)
		check_eq(progress.done(1), race)
	check(progress.is_complete(1), "complete")
	check_eq(progress.next_race(1), 0)
	check(progress.is_unlocked(2), "stage 2 opens")
	check(not progress.is_unlocked(3), "stage 3 still locked")
	check(not progress.is_unlocked(5), "no stage 5")
	_clean()


func test_finishing_an_old_race_does_not_move_progress_back_or_forward() -> void:
	_clean()
	var progress := StageProgress.new(PATH)
	progress.finish_race(1, 1, 100)
	progress.finish_race(1, 2, 250)
	progress.finish_race(1, 1, 400)
	check_eq(progress.done(1), 2)
	progress.finish_race(1, 5, 900)
	check_eq(progress.done(1), 2)
	_clean()


func test_a_crash_resets_the_score_and_keeps_the_progress() -> void:
	_clean()
	var progress := StageProgress.new(PATH)
	progress.finish_race(2, 1, 500)
	check_eq(progress.score(2), 500)
	progress.crash(2)
	check_eq(progress.score(2), 0)
	check_eq(progress.done(2), 1)
	_clean()


func test_the_best_is_saved_on_the_last_race_and_only_if_higher() -> void:
	_clean()
	var progress := StageProgress.new(PATH)
	for race in range(1, 12):
		check(not progress.finish_race(1, race, 1000), "no best before the last race")
	check_eq(progress.best(1), 0)
	check(progress.finish_race(1, 12, 5000), "new best")
	check_eq(progress.best(1), 5000)
	progress.restart(1)
	for race in range(1, 13):
		progress.finish_race(1, race, 3000)
	check_eq(progress.best(1), 5000, "a lower score does not replace it")
	_clean()


func test_restart_resets_progress_and_score_but_keeps_the_best() -> void:
	_clean()
	var progress := StageProgress.new(PATH)
	for race in range(1, 13):
		progress.finish_race(1, race, 700)
	progress.restart(1)
	check_eq(progress.done(1), 0)
	check_eq(progress.score(1), 0)
	check_eq(progress.best(1), 700)
	check(not progress.is_unlocked(2), "stage 2 locks again")
	_clean()


func test_progress_is_saved_and_a_corrupt_file_gives_zeros() -> void:
	_clean()
	var progress := StageProgress.new(PATH)
	progress.finish_race(1, 1, 321)
	var again := StageProgress.new(PATH)
	check_eq(again.done(1), 1)
	check_eq(again.score(1), 321)
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("[stage1]\ndone=\"lots\"\nscore=-5\n")
	file.close()
	var broken := StageProgress.new(PATH)
	check_eq(broken.done(1), 0)
	check_eq(broken.score(1), 0)
	check(broken.is_unlocked(1), "stage 1 open")
	_clean()
