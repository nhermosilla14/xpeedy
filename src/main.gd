extends Node3D
## Entry point: runs a Survival run at a fixed 60 Hz, draws it, and restarts after a crash.

## Tests and the benchmark can turn obstacles off before calling `start_run`.
var obstacles_enabled := true

var _run: SurvivalRun
var _track: TrackModel
var _clock: RunClock
var _steering := Steering.new()
var _binding: TrackShaderBinding
var _trail_texture := TrailTexture.new()
## Launch options; tests can set them before the scene is added to the tree.
var options: LaunchOptions
var _restart_wait := 0.0
var _shot_time := 0.0

@onready var _tunnel: TunnelView = $Tunnel
@onready var _obstacles: ObstacleView = $Obstacles
@onready var _explosions: ExplosionView = $Explosions
@onready var _camera: ShipCamera = $Camera
@onready var _fps: Label = $Hud/Fps
@onready var _message: Label = $Hud/Message
@onready var _status: Hud = $Hud/Status
@onready var _flash: ScreenFlash = $Hud/Flash
@onready var _frame_stats: FrameStats = $FrameStats


func _ready() -> void:
	$Environment.environment = ShipCamera.make_environment()
	var materials: Array[ShaderMaterial] = [_tunnel.material, _obstacles.material, _explosions.material]
	_binding = TrackShaderBinding.new(materials)
	_binding.window_changed.connect(_tunnel.on_window_changed)
	_binding.window_changed.connect(_obstacles.on_window_changed)
	_binding.window_changed.connect(_explosions.on_window_changed)
	_tunnel.material.set_shader_parameter("trail_tex", _trail_texture.texture)
	if options == null:
		options = LaunchOptions.parse(OS.get_cmdline_user_args())
	Engine.time_scale = options.timescale
	_frame_stats.extra = _state_text
	var run_seed := options.run_seed
	if run_seed < 0:
		run_seed = int(Time.get_unix_time_from_system() * 1000.0) & 0xFFFFFFFF
	start_run(run_seed)


func start_run(run_seed: int) -> void:
	var config := RunConfig.standard()
	config.generate_obstacles = obstacles_enabled and not options.clean
	config.generate_spots = not options.clean
	config.collisions_enabled = not options.ghost
	config.crash_on_obstacles = not options.invulnerable
	config.start_shields = options.shields
	config.start_segment = _start_segment(run_seed)
	_run = SurvivalRun.new(config, run_seed)
	_track = _run.track
	_clock = RunClock.new()
	_binding.reset()
	_explosions.clear()
	_camera.reset()
	_message.visible = false
	_restart_wait = 0.0
	print("[run] seed=%d" % run_seed)
	_refresh_view(0.0)


func _physics_process(delta: float) -> void:
	if _track.crashed and Input.is_action_just_pressed("restart"):
		start_run(_track.seed_value + 1)
		return
	var raw := Autopilot.plough(_run) if options.autopilot == "plough" else Input.get_axis("steer_left", "steer_right")
	var dt := _clock.advance(delta)
	if options.benchmark and _track.crashed:
		_restart_wait += dt
		if _restart_wait > 1.5:
			start_run(_track.seed_value + 1)
			return
	_run.step(dt, _steering.process(raw))
	_show_events()
	_message.visible = _track.crashed
	_refresh_view(dt)


## Feedback for what happened this tick (ADR 0010).
func _show_events() -> void:
	for event in _run.take_events():
		match event.kind:
			RunEvent.Kind.SHIELD_PICKUP:
				_flash.flash(Color(1.0, 0.7, 0.2), 0.75, 0.3)
			RunEvent.Kind.OBSTACLE_SMASHED:
				_flash.flash(Color(1.0, 0.5, 0.5), 0.75, 0.3)
				_explosions.spawn(_obstacle_centre(event.obstacle), event.obstacle.colour, _clock.time)
			RunEvent.Kind.CRASH:
				_flash.flash(Color.WHITE, 1.0, 1.0)


## World position of the middle of an obstacle, where its explosion starts.
func _obstacle_centre(o: Obstacle) -> Vector3:
	var geometry := _track.geometry
	var height := (2.5 if o.kind == Obstacle.Kind.BEAM else 0.5) * TrackModel.SEGMENT_LENGTH
	var lane := o.lane + 0.5
	var seg := o.seg + 0.5
	return geometry.surface(lane, seg) + geometry.normal(lane, seg) * height


## Where the run starts: `--start-segment`, or well inside the first part of the shape asked for with
## `--start-shape` (past the 30-segment morph).
func _start_segment(run_seed: int) -> float:
	var shapes := {"in": PartSequence.Shape.IN, "flat": PartSequence.Shape.FLAT, "out": PartSequence.Shape.OUT}
	if not shapes.has(options.start_shape):
		return options.start_segment
	if options.start_shape == "in":
		return 100.0
	var parts := PartSequence.new(run_seed)
	for i in range(1, 100):
		if parts.shape(i) == shapes[options.start_shape]:
			return float(parts.start(i)) + 50.0
	return options.start_segment


## What the benchmark log shows next to the frame rate, to tell how dense the track was.
func _state_text() -> String:
	var level := ObstacleField.level_at(maxi(_track.window_start(), 0))
	return "segment=%d level=%d obstacles=%d shields=%d score=%d" % [
		_track.window_start(), level, _run.obstacles.all().size(), _run.shields.count, _run.score]


func _process(delta: float) -> void:
	_fps.text = "%d fps" % Engine.get_frames_per_second()
	if options.screenshot_path != "":
		_shot_time += delta
		if _shot_time >= options.screenshot_seconds:
			_capture(options.screenshot_path)
			options.screenshot_path = ""


## Saves what is on screen to a PNG and quits.
func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("[screenshot] %s" % path)
	get_tree().quit()


func _refresh_view(dt: float) -> void:
	_binding.refresh(_track)
	_obstacles.refresh(_run.obstacles)
	_trail_texture.refresh(_run.trails)
	_status.update(_run)
	_explosions.set_time(_clock.time)
	_camera.follow(_track, dt)
