class_name ObstacleView
extends Node3D
## Draws obstacles with three instanced meshes (cube, beam, spike) placed by `obstacle.gdshader`
## (ADR 0009). The instance buffers are rewritten only when the set of obstacles changes.

const MAX_INSTANCES := 160
const FLOATS_PER_INSTANCE := 16  # 12 transform + 4 custom data
const CULL_MARGIN := 40.0
const BEAM_HEIGHT := 1.96  # units; doc 04
const SPIKE_HEIGHT := BEAM_HEIGHT / 4.0
const ObstacleShader := preload("res://src/view/obstacle.gdshader")

var material := ShaderMaterial.new()

var _multimeshes: Array[MultiMesh] = []
var _data: Array[PackedFloat32Array] = []
var _built_for := 0
var _built_version := -1


func _ready() -> void:
	material.shader = ObstacleShader
	material.set_shader_parameter("lane_width", TrackModel.SEGMENT_LENGTH)
	var lane_width := TrackModel.SEGMENT_LENGTH
	var meshes: Array[ArrayMesh] = [
		_prism_mesh(0.0, 1.0),
		_prism_mesh(0.15, BEAM_HEIGHT / lane_width),
		_spike_mesh(SPIKE_HEIGHT / lane_width),
		_prism_mesh(0.0, 1.0),
		_prism_mesh(0.0, 1.0),
	]
	for mesh in meshes:
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_custom_data = true
		multimesh.mesh = mesh
		multimesh.instance_count = MAX_INSTANCES
		multimesh.visible_instance_count = 0
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		instance.material_override = material
		add_child(instance)
		_multimeshes.append(multimesh)
		_data.append(PackedFloat32Array())


## Connect to `TrackShaderBinding.window_changed`: positions are computed in the shader, so the
## instances' bounds must be given explicitly.
func on_window_changed(origin: Vector3) -> void:
	for multimesh in _multimeshes:
		multimesh.custom_aabb = AABB(origin - Vector3.ONE * CULL_MARGIN, Vector3.ONE * CULL_MARGIN * 2.0)


## Rewrites the instance buffers if the obstacles changed since the last call.
func refresh(field: ObstacleField) -> void:
	var id := field.get_instance_id()
	if id == _built_for and field.version == _built_version:
		return
	_built_for = id
	_built_version = field.version
	var counts := [0, 0, 0, 0, 0]
	for kind in _multimeshes.size():
		var buffer := PackedFloat32Array()
		buffer.resize(MAX_INSTANCES * FLOATS_PER_INSTANCE)
		_data[kind] = buffer
	for o in field.all():
		var kind: int = o.kind
		if not o.alive or counts[kind] >= MAX_INSTANCES:
			continue
		_write_instance(_data[kind], counts[kind], o)
		counts[kind] += 1
	for kind in _multimeshes.size():
		_multimeshes[kind].buffer = _data[kind]
		_multimeshes[kind].visible_instance_count = counts[kind]


## Number of drawn instances per obstacle kind.
func instance_counts() -> Array[int]:
	var result: Array[int] = []
	for multimesh in _multimeshes:
		result.append(multimesh.visible_instance_count)
	return result


## What was last written for `kind`: 16 floats per instance (identity transform, then lane,
## absolute segment, colour, alive). Headless runs use a dummy renderer that stores nothing, so
## tests read this copy.
func instance_data(kind: int) -> PackedFloat32Array:
	return _data[kind]


## The third custom value (ADR 0021): colour index, plus 8 x shape, 24 if turning towards +lane, and
## 48 for a roller or 96 for a bouncer. Static obstacles are just their colour index.
static func code(o: Obstacle) -> float:
	var value := o.colour
	if o.kind == Obstacle.Kind.ROLLER or o.kind == Obstacle.Kind.BOUNCER:
		value += 8 * o.shape + (24 if o.direction > 0 else 0)
		value += 48 if o.kind == Obstacle.Kind.ROLLER else 96
	return float(value)


static func _write_instance(buffer: PackedFloat32Array, index: int, o: Obstacle) -> void:
	var base := index * FLOATS_PER_INSTANCE
	buffer[base + 0] = 1.0
	buffer[base + 5] = 1.0
	buffer[base + 10] = 1.0
	buffer[base + 12] = float(o.lane)
	buffer[base + 13] = float(o.seg)
	buffer[base + 14] = code(o)
	buffer[base + 15] = 1.0 + o.phase


## A box over the tile footprint inset by `inset` on every side, `height` lane widths tall.
## Vertices are (u, v, h); UV.x is the face brightness.
static func _prism_mesh(inset: float, height: float) -> ArrayMesh:
	var lo := inset
	var hi := 1.0 - inset
	var corners := [Vector2(lo, lo), Vector2(hi, lo), Vector2(hi, hi), Vector2(lo, hi)]
	var verts := PackedVector3Array()
	var shades := PackedVector2Array()
	var extra := PackedVector2Array()
	var indices := PackedInt32Array()
	var add_quad := func(a: Vector3, b: Vector3, c: Vector3, d: Vector3, brightness: float) -> void:
		var base := verts.size()
		verts.append_array([a, b, c, d])
		for i in 4:
			shades.append(Vector2(brightness, 0.0))
			extra.append(Vector2(inset, height))
		indices.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
	add_quad.call(Vector3(lo, lo, height), Vector3(hi, lo, height), Vector3(hi, hi, height),
		Vector3(lo, hi, height), 1.0)
	var side_brightness := [0.75, 0.6, 0.85, 0.65]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		add_quad.call(Vector3(a.x, a.y, 0.0), Vector3(b.x, b.y, 0.0), Vector3(b.x, b.y, height),
			Vector3(a.x, a.y, height), side_brightness[i])
	return _to_mesh(verts, shades, extra, indices)


## A four-sided pyramid on the whole tile, `height` lane widths tall.
static func _spike_mesh(height: float) -> ArrayMesh:
	var corners := [Vector2(0.05, 0.05), Vector2(0.95, 0.05), Vector2(0.95, 0.95), Vector2(0.05, 0.95)]
	var apex := Vector3(0.5, 0.5, height)
	var brightness := [0.75, 0.6, 0.85, 0.65]
	var verts := PackedVector3Array()
	var shades := PackedVector2Array()
	var extra := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var base := verts.size()
		verts.append_array([Vector3(a.x, a.y, 0.0), Vector3(b.x, b.y, 0.0), apex])
		for j in 3:
			shades.append(Vector2(brightness[i], 1.0))
		extra.append_array([Vector2(1, 0), Vector2(0, 1), Vector2(0, 0)])
		indices.append_array([base, base + 1, base + 2])
	return _to_mesh(verts, shades, extra, indices)


static func _to_mesh(verts: PackedVector3Array, shades: PackedVector2Array, extra: PackedVector2Array, indices: PackedInt32Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = shades
	arrays[Mesh.ARRAY_TEX_UV2] = extra
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
