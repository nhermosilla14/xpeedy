class_name StageProgress
extends RefCounted
## Stage mode progress kept on the device (ADR 0025): per stage the races done, the running score and the
## personal best. Missing or corrupt files give zeros.

const RACES := StageCatalogue.RACES_PER_STAGE
const STAGES := StageCatalogue.STAGES

var _path: String
var _done := {}
var _score := {}
var _best := {}


func _init(path := "user://stages.cfg") -> void:
	_path = path
	var file := ConfigFile.new()
	if file.load(_path) != OK:
		return
	for stage in range(1, STAGES + 1):
		var section := "stage%d" % stage
		_done[stage] = clampi(_int(file.get_value(section, "done", 0)), 0, RACES)
		_score[stage] = maxi(_int(file.get_value(section, "score", 0)), 0)
		_best[stage] = maxi(_int(file.get_value(section, "best", 0)), 0)


static func _int(value: Variant) -> int:
	return value if value is int else 0


func done(stage: int) -> int:
	return _done.get(stage, 0)


func score(stage: int) -> int:
	return _score.get(stage, 0)


func best(stage: int) -> int:
	return _best.get(stage, 0)


func is_complete(stage: int) -> bool:
	return done(stage) >= RACES


## Stage 1 is always open; stage n opens when every race of the earlier stages is done (doc 11).
func is_unlocked(stage: int) -> bool:
	for earlier in range(1, stage):
		if not is_complete(earlier):
			return false
	return stage >= 1 and stage <= STAGES


## The next unfinished race of a stage (1-based), or 0 when every race is done.
func next_race(stage: int) -> int:
	return 0 if is_complete(stage) else done(stage) + 1


## Records a finished race: progress advances when it is the next one, the running score becomes
## `total_score`, and the last race of a stage saves the personal best when it is higher. Returns true when
## that was a new best.
func finish_race(stage: int, race: int, total_score: int) -> bool:
	if race == done(stage) + 1:
		_done[stage] = race
	_score[stage] = maxi(total_score, 0)
	var new_best := false
	if race == RACES and total_score > best(stage):
		_best[stage] = total_score
		new_best = true
	save()
	return new_best


## A crash resets the running score and keeps the progress (doc 11).
func crash(stage: int) -> void:
	_score[stage] = 0
	save()


## Starts the stage over: progress and running score back to zero (the best stays).
func restart(stage: int) -> void:
	_done[stage] = 0
	_score[stage] = 0
	save()


func save() -> void:
	var file := ConfigFile.new()
	for stage in range(1, STAGES + 1):
		var section := "stage%d" % stage
		file.set_value(section, "done", done(stage))
		file.set_value(section, "score", score(stage))
		file.set_value(section, "best", best(stage))
	file.save(_path)
