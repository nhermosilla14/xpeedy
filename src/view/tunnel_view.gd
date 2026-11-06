class_name TunnelView
extends MeshInstance3D
## Draws the visible 50-segment window of the tunnel as one mesh of flat-coloured tiles.
## Rebuilt when the window scrolls or the shape changes (every tick while morphing).

const TILE_LIGHT := Color(1.0, 1.0, 1.0)
const TILE_DARK := Color(0.82, 0.82, 0.86)

var _built_from := -1
var _built_turn := NAN


func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = material


func refresh(track: TrackModel) -> void:
	var first := track.window_start()
	var turn := track.geometry.turn
	if first == _built_from and turn == _built_turn:
		return
	_built_from = first
	_built_turn = turn
	mesh = _build(track.geometry, first)


func _build(geometry: TunnelGeometry, first: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var near := geometry.ring(first)
	for s in TrackModel.VISIBLE_SEGMENTS:
		var seg := first + s
		var far := geometry.ring(seg + 1)
		for lane in TrackModel.LANES:
			var base := verts.size()
			verts.append(near[lane])
			verts.append(near[lane + 1])
			verts.append(far[lane + 1])
			verts.append(far[lane])
			var c := TILE_LIGHT if (seg + lane) % 2 == 0 else TILE_DARK
			for i in 4:
				colors.append(c)
			indices.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
		near = far
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result
