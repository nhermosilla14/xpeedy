class_name Settings
extends RefCounted
## Player settings kept in a ConfigFile (ADR 0019). Missing or invalid values fall back to the defaults.

const SECTION := "steering"

## Reverse the steering direction (doc 16).
var invert := false
## Gamepad face-button layout, "nintendo" or "xbox" (ADR 0026).
var layout := InputLayout.NINTENDO
## Flip the left stick's direction for steering (ADR 0033). Off by default: gamepads reach the game through the
## virtual Xbox 360 pad, which already has the stick the right way round (ADR 0038). The d-pad and keys are never flipped.
var stick_flipped := false
## Sound effects, music and vibration (ADR 0031).
var sound := true
var music := true
var vibration := true

var _path: String


func _init(path := "user://settings.cfg") -> void:
	_path = path
	var file := ConfigFile.new()
	if file.load(_path) != OK:
		return
	var value: Variant = file.get_value(SECTION, "invert", false)
	invert = value if value is bool else false
	sound = _flag(file, "audio", "sound")
	music = _flag(file, "audio", "music")
	vibration = _flag(file, "haptics", "vibration")
	var stick_value: Variant = file.get_value("input", "stick", "")
	if stick_value is String and stick_value in ["normal", "flipped"]:
		stick_flipped = stick_value == "flipped"
	var layout_value: Variant = file.get_value("input", "layout", InputLayout.NINTENDO)
	layout = layout_value if layout_value is String and InputLayout.is_valid(layout_value) else InputLayout.NINTENDO


## A boolean setting that defaults to on and ignores values of the wrong type.
static func _flag(file: ConfigFile, section: String, key: String) -> bool:
	var value: Variant = file.get_value(section, key, true)
	return value if value is bool else true


func save() -> void:
	var file := ConfigFile.new()
	file.set_value(SECTION, "invert", invert)
	file.set_value("input", "layout", layout)
	file.set_value("input", "stick", "flipped" if stick_flipped else "normal")
	file.set_value("audio", "sound", sound)
	file.set_value("audio", "music", music)
	file.set_value("haptics", "vibration", vibration)
	file.save(_path)
