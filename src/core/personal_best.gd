class_name PersonalBest
extends RefCounted
## Personal best scores, one integer per mode key, kept in a ConfigFile (ADR 0017). A missing or
## corrupt file counts as no best.

const SECTION := "best"

## The key of a Survival difficulty ("survival_standard" is the first one ever saved).
static func key(difficulty: String) -> String:
	return "survival_" + difficulty

var _path: String
var _scores := {}


func _init(path := "user://best.cfg") -> void:
	_path = path
	var file := ConfigFile.new()
	if file.load(_path) != OK or not file.has_section(SECTION):
		return
	for key in file.get_section_keys(SECTION):
		var value: Variant = file.get_value(SECTION, key)
		if value is int and value > 0:
			_scores[key] = value


func get_best(key: String) -> int:
	return _scores.get(key, 0)


## Records `score` if it beats the best and saves. Returns true when it is a new best.
func submit(key: String, score: int) -> bool:
	if score <= get_best(key):
		return false
	_scores[key] = score
	var file := ConfigFile.new()
	for k in _scores:
		file.set_value(SECTION, k, _scores[k])
	file.save(_path)
	return true
