class_name TrackModel
extends RefCounted
## Gameplay state of the tunnel and the ship (docs 02, 03). Independent of scene nodes.

const LANES := 16
const RADIUS := 1.0
## Lane width and segment length: the side of a 16-gon of radius 1.
static var SEGMENT_LENGTH := 2.0 * sin(PI / 16.0)
const VISIBLE_SEGMENTS := 50
const START_SEGMENT := 3.5
const START_LANE_POSITION := 7.5
const START_TPS := 300.0
const RAMP_SECONDS := 1.0
const STEER_RATE := 0.75

var target_tps: float
var segment := START_SEGMENT
## Lateral position on the [-1, 1] scale; lane position = (1 - p) * 8.
var p := 1.0 - START_LANE_POSITION / 8.0
var tps := START_TPS
var elapsed := 0.0


func _init(target_tps_ms: float = 80.0) -> void:
	target_tps = target_tps_ms


func lane_position() -> float:
	return (1.0 - p) * 8.0


## Advances the run by `dt` seconds of game time with the processed steer value.
func step(dt: float, steer: float) -> void:
	elapsed += dt
	tps = speed_at(elapsed)
	segment += dt * 1000.0 / tps
	p += dt * steer * STEER_RATE
	if p > 1.0:
		p -= 2.0
	elif p < -1.0:
		p += 2.0


## Time per segment after `t` seconds: ease-out from 300 ms to the target over 1 s (doc 17).
func speed_at(t: float) -> float:
	var u := clampf(t / RAMP_SECONDS, 0.0, 1.0)
	var eased := 1.0 - (1.0 - u) * (1.0 - u)
	return lerpf(START_TPS, target_tps, eased)


## Index of the first segment of the visible window.
func window_start() -> int:
	return int(floor(segment))
