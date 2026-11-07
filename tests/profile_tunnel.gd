extends SceneTree
## Profiling (not part of tools/test.sh): CPU time per tick of the model step, obstacle generation and
## the views, grouped by shape and morph state, over 40 s of driving straight from segment 2300, where
## the pattern level is 15 and the track is at full density (collisions are skipped so the ship
## survives). Run with:
##   tools/godot.sh --headless --script res://tests/profile_tunnel.gd
## Always quits: a hung script would otherwise keep a container running.

const Shape := PartSequence.Shape
const TICKS := 60 * 40
const START_SEGMENT := 2300.0

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
	run.track.segment = START_SEGMENT
	run.track.elapsed = 5.0
	run.track.step(0.0, 0.0)
	run.obstacles.generate_to(run.track.window_start() + TrackModel.VISIBLE_SEGMENTS)
	var stats := {}
	var worst: Array = []  # [total us, tick, step us, view us, camera us, patterns placed, window changed]
	var last_window := track.window_start()
	for i in TICKS:
		var t0 := Time.get_ticks_usec()
		track.step(1.0 / 60.0, 0.0)
		var patterns_before := run.obstacles.placed_points.size()
		run.obstacles.generate_to(track.window_start() + TrackModel.VISIBLE_SEGMENTS)
		run.obstacles.forget_before(track.window_start() - 2)
		var t1 := Time.get_ticks_usec()
		binding.refresh(track)
		obstacles.refresh(run.obstacles)
		var t2 := Time.get_ticks_usec()
		camera.follow(track, 1.0 / 60.0)
		var t3 := Time.get_ticks_usec()
		var window_changed := track.window_start() != last_window
		last_window = track.window_start()
		worst.append([t3 - t0, i, t1 - t0, t2 - t1, t3 - t2, run.obstacles.placed_points.size() - patterns_before, window_changed])
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
	worst.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for k in 8:
		var w: Array = worst[k]
		print("slow tick %5d: total=%6dus step+gen=%6dus views=%6dus camera=%5dus patterns=%d new_segment=%s" % [
			w[1], w[0], w[2], w[3], w[4], w[5], str(w[6])])
	var totals: Array = worst.map(func(w: Array) -> int: return w[0])
	totals.sort()
	print("percentiles: median=%dus p99=%dus max=%dus" % [totals[totals.size() / 2], totals[int(totals.size() * 0.99)], totals[-1]])
	print("mesh builds: %d" % tunnel.mesh_builds)
	quit()
	return true
