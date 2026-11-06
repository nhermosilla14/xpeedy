class_name TunnelView
extends MeshInstance3D
## Draws the visible 50-segment window of the tunnel (ADR 0007). The mesh is built once; a vertex
## shader places every vertex from data that `TrackShaderBinding` uploads to this node's material.

const SEGMENTS := TrackModel.VISIBLE_SEGMENTS
## Half-size of the culling box around the first visible segment; the window is ~20 units long.
const CULL_MARGIN := 40.0
const TunnelShader := preload("res://src/view/tunnel.gdshader")

## How many times the mesh was created (always 1 after _ready).
var mesh_builds := 0
var material := ShaderMaterial.new()


func _ready() -> void:
	material.shader = TunnelShader
	material_override = material
	mesh = _build_mesh()
	mesh_builds += 1


## Connect to `TrackShaderBinding.window_changed`: vertices are positioned in the shader, so the
## mesh's own bounds mean nothing to the culler.
func on_window_changed(origin: Vector3) -> void:
	mesh.custom_aabb = AABB(origin - Vector3.ONE * CULL_MARGIN, Vector3.ONE * CULL_MARGIN * 2.0)


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
