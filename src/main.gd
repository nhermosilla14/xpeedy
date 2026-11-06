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
var _autopilot := ""

@onready var _tunnel: TunnelView = $Tunnel
@onready var _obstacles: ObstacleView = $Obstacles
@onready var _explosions: ExplosionView = $Explosions
@onready var _camera: ShipCamera = $Camera
@onready var _fps: Label = $Hud/Fps
@onready var _message: Label = $Hud/Message
@onready var _status: Hud = $Hud/Status
@onready var _flash: ScreenFlash = $Hud/Flash


func _ready() -> void:
	$Environment.environment = ShipCamera.make_environment()
	var materials: Array[ShaderMaterial] = [_tunnel.material, _obstacles.material, _explosions.material]
	_binding = TrackShaderBinding.new(materials)
	_binding.window_changed.connect(_tunnel.on_window_changed)
	_binding.window_changed.connect(_obstacles.on_window_changed)
	_binding.window_changed.connect(_explosions.on_window_changed)
	_tunnel.material.set_shader_parameter("trail_tex", _trail_texture.texture)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--autopilot="):
			_autopilot = arg.trim_prefix("--autopilot=")
		elif arg.begins_with("--timescale="):
			Engine.time_scale = arg.trim_prefix("--timescale=").to_float()
	start_run(int(Time.get_unix_time_from_system() * 1000.0) & 0xFFFFFFFF)


func start_run(run_seed: int) -> void:
	var config := RunConfig.standard()
	config.generate_obstacles = obstacles_enabled
	config.collisions_enabled = not OS.get_cmdline_user_args().has("--ghost")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shields="):
			config.start_shields = arg.trim_prefix("--shields=").to_int()
	_run = SurvivalRun.new(config, run_seed)
	_track = _run.track
	_clock = RunClock.new()
	_binding.reset()
	_explosions.clear()
	_camera.reset()
	_message.visible = false
	print("[run] seed=%d" % run_seed)
	_refresh_view(0.0)


func _physics_process(delta: float) -> void:
	if _track.crashed and Input.is_action_just_pressed("restart"):
		start_run(_track.seed_value + 1)
		return
	var raw := Autopilot.plough(_run) if _autopilot == "plough" else Input.get_axis("steer_left", "steer_right")
	var dt := _clock.advance(delta)
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


func _process(_delta: float) -> void:
	_fps.text = "%d fps" % Engine.get_frames_per_second()


func _refresh_view(dt: float) -> void:
	_binding.refresh(_track)
	_obstacles.refresh(_run.obstacles)
	_trail_texture.refresh(_run.trails)
	_status.update(_run)
	_explosions.set_time(_clock.time)
	_camera.follow(_track, dt)
