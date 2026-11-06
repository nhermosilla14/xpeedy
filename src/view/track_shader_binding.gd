class_name TrackShaderBinding
extends RefCounted
## Uploads the track data that every GPU-placed object shares (ADR 0007, 0009): the 51 visible segment
## frames, the 17-point cross-section and 16 face normals, and the first visible segment. It applies
## them to every registered material, and tells views when the window moves so they can update their
## culling boxes. Uniforms a shader doesn't declare are simply ignored by Godot.

## Emitted when the window starts at a new segment; `origin` is the first frame's position.
signal window_changed(origin: Vector3)

const FRAMES := TrackModel.VISIBLE_SEGMENTS + 1

## Checker parity of the first visible segment, as last uploaded.
var first_parity := 0

var _materials: Array[ShaderMaterial] = []
var _built_from := -1
var _built_turn := NAN


func _init(materials: Array[ShaderMaterial]) -> void:
	_materials = materials


## Forgets what was uploaded, so the next refresh uploads everything (new run).
func reset() -> void:
	_built_from = -1
	_built_turn = NAN


## Uploads whatever changed since the last call.
func refresh(track: TrackModel) -> void:
	var first := track.window_start()
	var geometry := track.geometry
	if first != _built_from:
		_built_from = first
		_upload_frames(geometry.path, first)
	if geometry.turn != _built_turn:
		_built_turn = geometry.turn
		_set_all("section", geometry.section())
		_set_all("face_normal", geometry.face_normals())


func _upload_frames(path: PathModel, first: int) -> void:
	var positions := PackedVector3Array()
	var rights := PackedVector3Array()
	var ups := PackedVector3Array()
	positions.resize(FRAMES)
	rights.resize(FRAMES)
	ups.resize(FRAMES)
	for i in FRAMES:
		positions[i] = path.position(first + i)
		rights[i] = path.right(first + i)
		ups[i] = path.up(first + i)
	first_parity = first & 1
	_set_all("frame_pos", positions)
	_set_all("frame_right", rights)
	_set_all("frame_up", ups)
	_set_all("first_segment", float(first))
	_set_all("first_parity", float(first_parity))
	window_changed.emit(positions[0])


func _set_all(parameter: String, value: Variant) -> void:
	for material in _materials:
		material.set_shader_parameter(parameter, value)
