class_name StageCatalogue
extends RefCounted
## The races of Stage mode (doc 11, ADR 0024): `data/stages/stage_<S>_<R>.txt`, loaded in order until a
## file is missing or malformed.

const STAGES := 4
const RACES_PER_STAGE := 12
const DIRECTORY := "res://data/stages"

## stage (1-4) -> Array[RaceSpec]
var _races := {}


func _init(directory := DIRECTORY) -> void:
	for stage in range(1, STAGES + 1):
		var races: Array[RaceSpec] = []
		for race in range(1, RACES_PER_STAGE + 1):
			var path := "%s/stage_%d_%d.txt" % [directory, stage, race]
			if not FileAccess.file_exists(path):
				break
			var spec := RaceParser.parse(FileAccess.get_file_as_string(path))
			if spec.error != "":
				push_warning("%s: %s" % [path, spec.error])
				break
			races.append(spec)
		_races[stage] = races


func race_count(stage: int) -> int:
	return _races.get(stage, []).size()


## Race `race` (1-based) of `stage` (1-based), or null.
func race(stage: int, race_number: int) -> RaceSpec:
	var list: Array = _races.get(stage, [])
	if race_number < 1 or race_number > list.size():
		return null
	return list[race_number - 1]
