class_name TunnelView
extends MeshInstance3D
## Draws the visible 50-segment window of the tunnel as one mesh of flat-coloured tiles.

const TILE_LIGHT := Color(1.0, 1.0, 1.0)
const TILE_DARK := Color(0.82, 0.82, 0.86)

var _built_from := -1


func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = material


func refresh(track: TrackModel) -> void:
	var first := track.window_start()
	if first == _built_from:
		return
	_built_from = first
	mesh = _build(first)


func _build(first: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for s in TrackModel.VISIBLE_SEGMENTS:
		var seg := first + s
		for lane in TrackModel.LANES:
			var base := verts.size()
			verts.append(TunnelGeometry.vertex(lane, seg))
			verts.append(TunnelGeometry.vertex(lane + 1, seg))
			verts.append(TunnelGeometry.vertex(lane + 1, seg + 1))
			verts.append(TunnelGeometry.vertex(lane, seg + 1))
			var c := TILE_LIGHT if (seg + lane) % 2 == 0 else TILE_DARK
			for i in 4:
				colors.append(c)
			indices.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result
