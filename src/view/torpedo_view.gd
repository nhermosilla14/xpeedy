class_name TorpedoView
extends Node3D
## Draws the torpedoes in flight (ADR 0029): a small bright projectile just above the tunnel surface.

const POOL := 4
const HEIGHT := 0.12

var _meshes: Array[MeshInstance3D] = []


func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.6, 0.95, 1.0)
	var sphere := SphereMesh.new()
	sphere.radius = 0.06
	sphere.height = 0.12
	sphere.material = material
	for i in POOL:
		var node := MeshInstance3D.new()
		node.mesh = sphere
		node.visible = false
		node.extra_cull_margin = 100.0
		add_child(node)
		_meshes.append(node)


## Places one projectile per torpedo in flight on the track's geometry.
func update(track: TrackModel, flying: Array[Torpedo]) -> void:
	for i in _meshes.size():
		_meshes[i].visible = i < flying.size()
		if i < flying.size():
			var lane := flying[i].lane
			var seg := flying[i].seg
			var geometry := track.geometry
			_meshes[i].position = geometry.surface(lane, seg) + geometry.normal(lane, seg) * HEIGHT
