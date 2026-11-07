extends SceneTree
## End-to-end check for slice 0005: through the real scene, the tunnel mesh is created once while the
## ship scrolls through several segments and a full shape change, and the data the shader receives
## always matches the model (frames, cross-section, checker parity).

const Shape := PartSequence.Shape
const MAX_TICKS := 60 * 20

var _main: Node
var _ticks := 0
var _errors: PackedStringArray = []
var _checked := 0
var _morph_ticks_checked := 0
var _scrolls_seen := {}


func _initialize() -> void:
	_main = load("res://src/main.tscn").instantiate()
	_main.set("countdown_enabled", false)
	root.add_child(_main)
	_main.set("obstacles_enabled", false)


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	var track: TrackModel = _main.get("_track")
	var tunnel: TunnelView = _main.get_node("Tunnel")
	if _ticks == 1:
		var i := 1
		while track.parts.shape(i) != Shape.FLAT:
			i += 1
		track.segment = float(track.parts.start(i)) - 20.0
		track.elapsed = 5.0
		return false
	if track.crashed:
		_errors.append("crashed while driving straight")
		return _finish(tunnel)
	_scrolls_seen[track.window_start()] = true
	_check_uniforms(track, tunnel)
	if track.is_morphing():
		_morph_ticks_checked += 1
	if track.current_shape() == Shape.FLAT and not track.is_morphing() and _checked > 60 * 5:
		return _finish(tunnel)
	if _ticks > MAX_TICKS:
		_errors.append("timed out before the morph finished")
		return _finish(tunnel)
	return false


func _check_uniforms(track: TrackModel, tunnel: TunnelView) -> void:
	_checked += 1
	var material: ShaderMaterial = tunnel.material
	var binding: TrackShaderBinding = _main.get("_binding")
	var first := track.window_start()
	var section: PackedVector2Array = material.get_shader_parameter("section")
	var model_section := track.geometry.section()
	if section.size() != 17 or section != model_section:
		_error_once("cross-section differs from the model at tick %d" % _ticks)
	var positions: PackedVector3Array = material.get_shader_parameter("frame_pos")
	var rights: PackedVector3Array = material.get_shader_parameter("frame_right")
	var ups: PackedVector3Array = material.get_shader_parameter("frame_up")
	if positions.size() != 51 or rights.size() != 51 or ups.size() != 51:
		_error_once("frame arrays have the wrong size")
		return
	for i in [0, 1, 25, 49, 50]:
		if positions[i] != track.path.position(first + i) \
				or rights[i] != track.path.right(first + i) \
				or ups[i] != track.path.up(first + i):
			_error_once("frame %d differs from the model at window %d" % [i, first])
	_check_ship_uniforms(track, material)
	if binding.first_parity != (first & 1) \
			or not is_equal_approx(material.get_shader_parameter("first_parity"), float(first & 1)):
		_error_once("checker parity wrong for window starting at %d" % first)


func _check_ship_uniforms(track: TrackModel, material: ShaderMaterial) -> void:
	if not is_equal_approx(material.get_shader_parameter("ship_segment"), track.segment):
		_error_once("ship_segment differs from the model at tick %d" % _ticks)
	if not is_equal_approx(material.get_shader_parameter("ship_lane"), track.lane_position()):
		_error_once("ship_lane differs from the model at tick %d" % _ticks)
	var wrap := 1.0 if track.obstacles_wrap_seam() else 0.0
	if material.get_shader_parameter("wrap_seam") != wrap:
		_error_once("wrap_seam differs from the model at tick %d" % _ticks)
	if not is_equal_approx(material.get_shader_parameter("tube_weight"), 1.0 - track.geometry.flatness()):
		_error_once("tube_weight differs from the model at tick %d" % _ticks)


func _error_once(message: String) -> void:
	if not _errors.has(message) and _errors.size() < 5:
		_errors.append(message)


func _finish(tunnel: TunnelView) -> bool:
	if tunnel.mesh_builds != 1:
		_errors.append("mesh was built %d times, expected once" % tunnel.mesh_builds)
	var mesh: ArrayMesh = tunnel.mesh
	var arrays := mesh.surface_get_arrays(0)
	if (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() != 50 * 16 * 4:
		_errors.append("unexpected vertex count")
	if _scrolls_seen.size() < 20:
		_errors.append("window barely scrolled: %d positions" % _scrolls_seen.size())
	if _morph_ticks_checked < 60:
		_errors.append("too few morph ticks verified: %d" % _morph_ticks_checked)
	for e in _errors:
		print("  FAIL  e2e gpu tunnel: " + e)
	if _errors.is_empty():
		print("  ok    e2e gpu tunnel (mesh built once; %d ticks checked, %d scrolls, %d during morph)"
			% [_checked, _scrolls_seen.size(), _morph_ticks_checked])
	quit(1 if not _errors.is_empty() else 0)
	return true
