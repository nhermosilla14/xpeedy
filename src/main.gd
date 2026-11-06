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

@onready var _tunnel: TunnelView = $Tunnel
@onready var _obstacles: ObstacleView = $Obstacles
@onready var _camera: ShipCamera = $Camera
@onready var _fps: Label = $Hud/Fps
@onready var _message: Label = $Hud/Message
@onready var _status: Hud = $Hud/Status
@onready var _flash: ScreenFlash = $Hud/Flash


func _ready() -> void:
	$Environment.environment = ShipCamera.make_environment()
	var materials: Array[ShaderMaterial] = [_tunnel.material, _obstacles.material]
	_binding = TrackShaderBinding.new(materials)
	_binding.window_changed.connect(_tunnel.on_window_changed)
	_binding.window_changed.connect(_obstacles.on_window_changed)
	_tunnel.material.set_shader_parameter("trail_tex", _trail_texture.texture)
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
	_camera.reset()
	_message.visible = false
	print("[run] seed=%d" % run_seed)
	_refresh_view(0.0)


func _physics_process(delta: float) -> void:
	if _track.crashed and Input.is_action_just_pressed("restart"):
		start_run(_track.seed_value + 1)
		return
	var raw := Input.get_axis("steer_left", "steer_right")
	var dt := _clock.advance(delta)
	_run.step(dt, _steering.process(raw))
	_show_events()
	_message.visible = _track.crashed
	_refresh_view(dt)


## Feedback for what happened this tick (ADR 0010).
func _show_events() -> void:
	for event in _run.take_events():
		if event.kind == RunEvent.Kind.SHIELD_PICKUP:
			_flash.flash(Color(1.0, 0.7, 0.2), 0.75, 0.3)


func _process(_delta: float) -> void:
	_fps.text = "%d fps" % Engine.get_frames_per_second()


func _refresh_view(dt: float) -> void:
	_binding.refresh(_track)
	_obstacles.refresh(_run.obstacles)
	_trail_texture.refresh(_run.trails)
	_status.update(_run)
	_camera.follow(_track, dt)
