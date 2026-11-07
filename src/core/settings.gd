class_name Settings
extends RefCounted
## Player settings kept in a ConfigFile (ADR 0019). Missing or invalid values fall back to the defaults.

const SECTION := "steering"

## Reverse the steering direction (doc 16).
var invert := false
## Gamepad face-button layout, "nintendo" or "xbox" (ADR 0026).
var layout := InputLayout.NINTENDO

var _path: String


func _init(path := "user://settings.cfg") -> void:
	_path = path
	var file := ConfigFile.new()
	if file.load(_path) != OK:
		return
	var value: Variant = file.get_value(SECTION, "invert", false)
	invert = value if value is bool else false
	var layout_value: Variant = file.get_value("input", "layout", InputLayout.NINTENDO)
	layout = layout_value if layout_value is String and InputLayout.is_valid(layout_value) else InputLayout.NINTENDO


func save() -> void:
	var file := ConfigFile.new()
	file.set_value(SECTION, "invert", invert)
	file.set_value("input", "layout", layout)
	file.save(_path)
