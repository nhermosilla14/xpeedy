class_name ShipCamera
extends Camera3D
## First-person camera (doc 03): 0.1875 above the lane surface, looking 3 segments ahead, up = surface normal.

const EYE_HEIGHT := 0.1875
const LOOK_AHEAD := 3.0
const FOG_COLOR := Color(0.20, 0.06, 0.15)


func _ready() -> void:
	fov = 96.0
	keep_aspect = Camera3D.KEEP_HEIGHT
	near = 0.1
	far = 100.0


func follow(track: TrackModel) -> void:
	var lane := track.lane_position()
	var geometry := track.geometry
	var up := geometry.normal(lane, track.segment)
	var eye := geometry.surface(lane, track.segment) + up * EYE_HEIGHT
	var target := geometry.surface(lane, track.segment + LOOK_AHEAD)
	look_at_from_position(eye, target, up)


static func make_environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = FOG_COLOR
	env.fog_enabled = true
	env.fog_light_color = FOG_COLOR
	env.fog_density = 0.5
	return env
