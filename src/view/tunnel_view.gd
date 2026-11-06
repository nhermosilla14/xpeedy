class_name TunnelView
extends MeshInstance3D
## Draws the visible 50-segment window of the tunnel (ADR 0007). The mesh is built once; a vertex
## shader places every vertex from the per-segment frames and the 17-point cross-section, which this
## node uploads when the window scrolls (frames) or the shape changes (cross-section).

const SEGMENTS := TrackModel.VISIBLE_SEGMENTS
const FRAMES := SEGMENTS + 1
## Half-size of the culling box around the first visible segment; the window is ~20 units long.
const CULL_MARGIN := 40.0
const TunnelShader := preload("res://src/view/tunnel.gdshader")

## How many times the mesh was created (always 1 after _ready).
var mesh_builds := 0
## Checker parity of the first visible segment, as last uploaded.
var first_parity := 0

var _material := ShaderMaterial.new()
var _built_from := -1
var _built_turn := NAN


func _ready() -> void:
	_material.shader = TunnelShader
	material_override = _material
	mesh = _build_mesh()
	mesh_builds += 1


## Uploads whatever changed since the last call.
func refresh(track: TrackModel) -> void:
	var first := track.window_start()
	var geometry := track.geometry
	if first != _built_from:
		_built_from = first
		_upload_frames(geometry.path, first)
	if geometry.turn != _built_turn:
		_built_turn = geometry.turn
		_material.set_shader_parameter("section", geometry.section())


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
	_material.set_shader_parameter("frame_pos", positions)
	_material.set_shader_parameter("frame_right", rights)
	_material.set_shader_parameter("frame_up", ups)
	_material.set_shader_parameter("first_parity", float(first_parity))
	# Vertices are positioned in the shader, so the mesh's own bounds mean nothing to the culler.
	var centre := positions[0]
	mesh.custom_aabb = AABB(centre - Vector3.ONE * CULL_MARGIN, Vector3.ONE * CULL_MARGIN * 2.0)


## Static mesh: vertex x = lane vertex index, y = segment offset, z unused; color.r = tile parity.
func _build_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for s in SEGMENTS:
		for lane in TrackModel.LANES:
			var base := verts.size()
			verts.append(Vector3(lane, s, 0.0))
			verts.append(Vector3(lane + 1, s, 0.0))
			verts.append(Vector3(lane + 1, s + 1, 0.0))
			verts.append(Vector3(lane, s + 1, 0.0))
			var parity := float((s + lane) % 2)
			for i in 4:
				colors.append(Color(parity, 0.0, 0.0))
			indices.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result
