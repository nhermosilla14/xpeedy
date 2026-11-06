extends SceneTree
## End-to-end check for slice 0001: loads the real main scene, holds "steer_right" through the input
## map, and verifies the ship moves forward, steers to lower lanes and wraps across the seam.

const STEER_SECONDS := 3.0

var _main: Node
var _frames := 0
var _start_segment := 0.0
var _wrapped := false
var _last_lane := 0.0


func _initialize() -> void:
	_main = load("res://src/main.tscn").instantiate()
	root.add_child(_main)
	Input.action_press("steer_right")


func _physics_process(_delta: float) -> bool:
	var track: TrackModel = _main.get("_track")
	if _frames == 0:
		_start_segment = track.segment
		_last_lane = track.lane_position()
	_frames += 1
	var lane := track.lane_position()
	if lane > _last_lane + 8.0:
		_wrapped = true
	_last_lane = lane
	if _frames < int(STEER_SECONDS * 60.0):
		return false
	var errors: PackedStringArray = []
	if track.segment - _start_segment < 20.0:
		errors.append("ship barely moved: %f segments" % (track.segment - _start_segment))
	if not _wrapped:
		errors.append("steering right for %.1f s never wrapped from lane 0 to 15" % STEER_SECONDS)
	var camera: Camera3D = _main.get_node("Camera")
	var tunnel: MeshInstance3D = _main.get_node("Tunnel")
	if tunnel.mesh == null or tunnel.mesh.get_surface_count() != 1:
		errors.append("tunnel mesh missing")
	if camera.global_position.length() == 0.0:
		errors.append("camera never placed")
	for e in errors:
		print("  FAIL  e2e walking skeleton: " + e)
	if errors.is_empty():
		print("  ok    e2e walking skeleton (%.1f segments, wrapped)" % (track.segment - _start_segment))
	quit(1 if not errors.is_empty() else 0)
	return true
