extends Node3D
## Slice 0001 entry point: runs the track model at a fixed 60 Hz and draws it.

const TARGET_TPS := 80.0

var _track := TrackModel.new(TARGET_TPS)
var _clock := RunClock.new()
var _steering := Steering.new()

@onready var _tunnel: TunnelView = $Tunnel
@onready var _camera: ShipCamera = $Camera
@onready var _fps: Label = $Hud/Fps


func _ready() -> void:
	$Environment.environment = ShipCamera.make_environment()
	_refresh_view()


func _physics_process(delta: float) -> void:
	var raw := Input.get_axis("steer_left", "steer_right")
	_track.step(_clock.advance(delta), _steering.process(raw))
	_refresh_view()


func _process(_delta: float) -> void:
	_fps.text = "%d fps" % Engine.get_frames_per_second()


func _refresh_view() -> void:
	_tunnel.refresh(_track)
	_camera.follow(_track)
