class_name ExplosionView
extends Node3D
## Explosions of tumbling fragments for smashed obstacles (ADR 0012): a pool of small quads in one
## instanced mesh, moved by `fragments.gdshader`. The CPU only writes instances when something is
## smashed; everything else happens on the GPU, driven by the `game_time` uniform.

const POOL := 96
const PER_SMASH := 12
const CULL_MARGIN := 40.0
const FragmentShader := preload("res://src/view/fragments.gdshader")

var material := ShaderMaterial.new()
## How many explosions were spawned since the last `clear` (tests read this).
var spawn_count := 0
## The origin and colour of the most recent explosion.
var last_origin := Vector3.ZERO
var last_colour := -1

var _multimesh := MultiMesh.new()
var _next := 0
# Decoration only: it never touches a gameplay random stream (ADR 0005).
var _decor := XRandom.new(0xF2A9)


func _ready() -> void:
	material.shader = FragmentShader
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_custom_data = true
	_multimesh.mesh = _quad_mesh()
	_multimesh.instance_count = POOL
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = _multimesh
	instance.material_override = material
	add_child(instance)
	clear()


## Connect to `TrackShaderBinding.window_changed`: fragments are moved in the shader, so the culling
## box is given explicitly.
func on_window_changed(origin: Vector3) -> void:
	_multimesh.custom_aabb = AABB(origin - Vector3.ONE * CULL_MARGIN, Vector3.ONE * CULL_MARGIN * 2.0)


## Starts an explosion of `PER_SMASH` fragments at `origin` in palette colour `colour`.
func spawn(origin: Vector3, colour: int, game_time: float) -> void:
	spawn_count += 1
	last_origin = origin
	last_colour = colour
	for i in PER_SMASH:
		var index := (_next + i) % POOL
		_multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, origin))
		_multimesh.set_instance_custom_data(index, Color(game_time, float(colour), _decor.range_float(1.0, 1000.0), 1.0))
	_next = (_next + PER_SMASH) % POOL


## The shader's clock.
func set_time(game_time: float) -> void:
	material.set_shader_parameter("game_time", game_time)


## Removes every fragment (new run).
func clear() -> void:
	spawn_count = 0
	last_colour = -1
	for i in POOL:
		_multimesh.set_instance_custom_data(i, Color(0.0, 0.0, 0.0, 0.0))


static func _quad_mesh() -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(-0.5, -0.5, 0.0), Vector3(0.5, -0.5, 0.0), Vector3(0.5, 0.5, 0.0), Vector3(-0.5, 0.5, 0.0)])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
