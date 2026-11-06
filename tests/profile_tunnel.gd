extends SceneTree
## Profiling (not part of tools/test.sh): CPU time per tick of the model step, obstacle generation and
## the views, grouped by shape and morph state, over 40 s of driving straight (collisions are skipped
## so the ship survives). Run with:
##   tools/godot.sh --headless --script res://tests/profile_tunnel.gd
## Always quits: a hung script would otherwise keep a container running.

const Shape := PartSequence.Shape
const TICKS := 60 * 40

var _main: Node
var _done := false


func _initialize() -> void:
	_main = load("res://src/main.tscn").instantiate()
	root.add_child(_main)


func _physics_process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	var run: SurvivalRun = _main.get("_run")
	var track: TrackModel = run.track
	var binding: TrackShaderBinding = _main.get("_binding")
	var tunnel: TunnelView = _main.get_node("Tunnel")
	var obstacles: ObstacleView = _main.get_node("Obstacles")
	var camera: ShipCamera = _main.get_node("Camera")
	var stats := {}
	for i in TICKS:
		var t0 := Time.get_ticks_usec()
		track.step(1.0 / 60.0, 0.0)
		run.obstacles.generate_to(track.window_start() + TrackModel.VISIBLE_SEGMENTS)
		run.obstacles.forget_before(track.window_start() - 2)
		var t1 := Time.get_ticks_usec()
		binding.refresh(track)
		obstacles.refresh(run.obstacles)
		var t2 := Time.get_ticks_usec()
		camera.follow(track, 1.0 / 60.0)
		var t3 := Time.get_ticks_usec()
		var key := "%s%s" % [Shape.keys()[track.current_shape()], "-morph" if track.is_morphing() else ""]
		var s: Array = stats.get(key, [0, 0, 0, 0])
		s[0] += 1
		s[1] += t1 - t0
		s[2] += t2 - t1
		s[3] += t3 - t2
		stats[key] = s
	for key in stats:
		var s: Array = stats[key]
		print("%-10s ticks=%5d step=%6.1fus views=%7.1fus camera=%6.1fus" % [
			key, s[0], float(s[1]) / s[0], float(s[2]) / s[0], float(s[3]) / s[0]])
	print("mesh builds: %d" % tunnel.mesh_builds)
	quit()
	return true
