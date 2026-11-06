class_name ShipCamera
extends Camera3D
## First-person camera (doc 03): 0.1875 above the lane surface, looking 3 segments ahead, up = surface
## normal. Banks with steering on flat parts, shakes while morphing, pitches up after a crash.

const EYE_HEIGHT := 0.1875
const LOOK_AHEAD := 3.0
const FOG_COLOR := Color(0.20, 0.06, 0.15)
const BANK_PER_STEER := PI / 25.0
const BANK_RATE := 5.0
const SHAKE := 0.015
const CRASH_PITCH := deg_to_rad(45.0)
const CRASH_PITCH_SECONDS := 1.0

var _roll := 0.0
var _decor := XRandom.new(0xDEC0)


func _ready() -> void:
	fov = 96.0
	keep_aspect = Camera3D.KEEP_HEIGHT
	near = 0.1
	far = 100.0


func reset() -> void:
	_roll = 0.0


func follow(track: TrackModel, dt: float) -> void:
	var lane := track.lane_position()
	var geometry := track.geometry
	var up := geometry.normal(lane, track.segment)
	var eye := geometry.surface(lane, track.segment) + up * EYE_HEIGHT
	var target := geometry.surface(lane, track.segment + LOOK_AHEAD)
	if track.is_morphing() and not track.crashed:
		eye += Vector3(_shake(), _shake(), _shake())
	look_at_from_position(eye, target, up)

	var target_roll := track.steer * BANK_PER_STEER * geometry.flatness()
	if track.crashed:
		target_roll = 0.0
	_roll += (target_roll - _roll) * minf(1.0, BANK_RATE * dt)
	rotate_object_local(Vector3.BACK, _roll)

	if track.crashed:
		var t := minf(track.crash_time / CRASH_PITCH_SECONDS, 1.0)
		rotate_object_local(Vector3.RIGHT, CRASH_PITCH * (1.0 - (1.0 - t) * (1.0 - t)))


func _shake() -> float:
	return _decor.range_float(-SHAKE, SHAKE)


static func make_environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = FOG_COLOR
	env.fog_enabled = true
	env.fog_light_color = FOG_COLOR
	env.fog_density = 0.5
	return env
