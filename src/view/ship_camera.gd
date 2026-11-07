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
const NORMAL_FOV := 96.0
const GRAVITY_FOV := 80.0
const GRAVITY_YAW := deg_to_rad(15.0)
const ZONE_SHAKE := 0.4
const CRASH_PITCH := deg_to_rad(45.0)
const CRASH_PITCH_SECONDS := 1.0

var _roll := 0.0
var _shake_left := 0.0
var _zone := Zone.Kind.NONE
var _gravity := 0.0
var _decor := XRandom.new(0xDEC0)


func _ready() -> void:
	fov = NORMAL_FOV
	keep_aspect = Camera3D.KEEP_HEIGHT
	near = 0.1
	far = 100.0


func reset() -> void:
	_roll = 0.0
	_shake_left = 0.0
	apply_zone(Zone.Kind.NONE, 0.0)


## Shakes the camera for `seconds` (a roller landing nearby).
func shake(seconds: float) -> void:
	_shake_left = maxf(_shake_left, seconds)


## What the active zone does to the camera (ADR 0023): `gravity` is g(t) of Gravity Well.
func apply_zone(zone: Zone.Kind, gravity: float) -> void:
	_zone = zone
	_gravity = gravity
	fov = GRAVITY_FOV if zone == Zone.Kind.GRAVITY_WELL else NORMAL_FOV


## Exponential fog density of the world (doc 07): 0.5 normally, lighter in three zones, pulsing in Gravity Well.
static func fog_density(zone: Zone.Kind, zone_time: float) -> float:
	match zone:
		Zone.Kind.BLACKOUT, Zone.Kind.HUE_SHIFT, Zone.Kind.DARK_NEBULA:
			return 0.3
		Zone.Kind.GRAVITY_WELL:
			return 0.4 + 0.1 * sin(2.0 * zone_time)
	return 0.5


func is_shaking() -> bool:
	return _shake_left > 0.0


func follow(track: TrackModel, dt: float) -> void:
	var lane := track.lane_position()
	var geometry := track.geometry
	var up := geometry.normal(lane, track.segment)
	var eye := geometry.surface(lane, track.segment) + up * EYE_HEIGHT
	var target := geometry.surface(lane, track.segment + LOOK_AHEAD)
	_shake_left = maxf(_shake_left - dt, 0.0)
	if (track.is_morphing() or _shake_left > 0.0) and not track.crashed:
		eye += Vector3(_shake(), _shake(), _shake())
	if (_zone == Zone.Kind.GRAVITY_WELL or _zone == Zone.Kind.PLASMA_CLOUD) and not track.crashed:
		eye += Vector3(_shake(), _shake(), _shake()) * ZONE_SHAKE
	look_at_from_position(eye, target, up)
	if _zone == Zone.Kind.GRAVITY_WELL:
		rotate_object_local(Vector3.UP, GRAVITY_YAW * _gravity)

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
