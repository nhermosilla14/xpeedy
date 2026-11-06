extends Node3D
## Entry point: runs the track model at a fixed 60 Hz, draws it, and restarts after a crash.

const TARGET_TPS := 80.0

var _track: TrackModel
var _clock: RunClock
var _steering := Steering.new()

@onready var _tunnel: TunnelView = $Tunnel
@onready var _camera: ShipCamera = $Camera
@onready var _fps: Label = $Hud/Fps
@onready var _message: Label = $Hud/Message


func _ready() -> void:
	$Environment.environment = ShipCamera.make_environment()
	start_run(int(Time.get_unix_time_from_system() * 1000.0) & 0xFFFFFFFF)


func start_run(run_seed: int) -> void:
	_track = TrackModel.new(TARGET_TPS, run_seed)
	_clock = RunClock.new()
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
	_track.step(dt, _steering.process(raw))
	_message.visible = _track.crashed
	_refresh_view(dt)


func _process(_delta: float) -> void:
	_fps.text = "%d fps" % Engine.get_frames_per_second()


func _refresh_view(dt: float) -> void:
	_tunnel.refresh(_track)
	_camera.follow(_track, dt)
