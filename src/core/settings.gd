class_name Settings
extends RefCounted
## Player settings kept in a ConfigFile (ADR 0019). Missing or invalid values fall back to the defaults.

const SECTION := "steering"

## Reverse the steering direction (doc 16).
var invert := false

var _path: String


func _init(path := "user://settings.cfg") -> void:
	_path = path
	var file := ConfigFile.new()
	if file.load(_path) != OK:
		return
	var value: Variant = file.get_value(SECTION, "invert", false)
	invert = value if value is bool else false


func save() -> void:
	var file := ConfigFile.new()
	file.set_value(SECTION, "invert", invert)
	file.save(_path)
