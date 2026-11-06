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
const MORPH_SEGMENTS := 30.0
const SEAM_TO_TUBE_MIN := 0.98
const SEAM_TO_FLAT_MAX := 0.02

const Shape := PartSequence.Shape

var target_tps: float
var segment := START_SEGMENT
## Lateral position on the [-1, 1] scale; lane position = (1 - p) * 8.
var p := 1.0 - START_LANE_POSITION / 8.0
var tps := START_TPS
var elapsed := 0.0
var steer := 0.0
var crashed := false
## "wall" or "obstacle" once crashed.
var crash_reason := ""
## Game time since the crash.
var crash_time := 0.0
var seed_value: int
var parts: PartSequence
var path: PathModel
var geometry: TunnelGeometry


func _init(target_tps_ms: float = 80.0, run_seed: int = 0) -> void:
	target_tps = target_tps_ms
	seed_value = run_seed
	parts = PartSequence.new(run_seed)
	path = PathModel.new(run_seed, SEGMENT_LENGTH)
	path.bend_limit = parts.max_bend_at
	geometry = TunnelGeometry.new(path)
	_update_shape()


func lane_position() -> float:
	return (1.0 - p) * 8.0


## Advances the run by `dt` seconds of game time with the processed steer value.
func step(dt: float, steer_value: float) -> void:
	if crashed:
		crash_time += dt
		return
	elapsed += dt
	steer = steer_value
	tps = speed_at(elapsed)
	segment += dt * 1000.0 / tps
	p += dt * steer * STEER_RATE
	if p > 1.0 or p < -1.0:
		if can_cross_seam():
			p += -2.0 if p > 1.0 else 2.0
		else:
			p = clampf(p, -1.0, 1.0)
			crash("wall")
	path.forget_before(window_start())
	_update_shape()


## Ends the run; the ship stops and the crash timer starts.
func crash(reason: String) -> void:
	crashed = true
	crash_reason = reason


## Time per segment after `t` seconds: ease-out from 300 ms to the target over 1 s (doc 17).
func speed_at(t: float) -> float:
	var u := clampf(t / RAMP_SECONDS, 0.0, 1.0)
	var eased := 1.0 - (1.0 - u) * (1.0 - u)
	return lerpf(START_TPS, target_tps, eased)


## Index of the first segment of the visible window.
func window_start() -> int:
	return int(floor(segment))


## Shape the ship is morphing from (equal to current_shape() when not morphing).
func previous_shape() -> Shape:
	var i := parts.index_at(segment)
	return parts.shape(i - 1) if i > 0 else parts.shape(i)


func current_shape() -> Shape:
	return parts.shape_at(segment)


## 0 at the start of a part, 1 once 30 segments in (and always 1 in the first part).
func morph_progress() -> float:
	var i := parts.index_at(segment)
	if i == 0:
		return 1.0
	return clampf((segment - float(parts.start(i))) / MORPH_SEGMENTS, 0.0, 1.0)


func is_morphing() -> bool:
	return morph_progress() < 1.0


## Seam-crossing rules from doc 02.
func can_cross_seam() -> bool:
	var m := morph_progress()
	var from := previous_shape()
	var to := current_shape()
	if m >= 1.0:
		return to != Shape.FLAT
	if from == Shape.FLAT and to != Shape.FLAT:
		return m >= SEAM_TO_TUBE_MIN
	if from != Shape.FLAT and to == Shape.FLAT:
		return m <= SEAM_TO_FLAT_MAX
	return false


## Obstacle hit boxes and trail distances wrap across the seam on tube parts when not morphing.
func obstacles_wrap_seam() -> bool:
	return current_shape() != Shape.FLAT and not is_morphing()


static func turn_for(shape: Shape) -> float:
	match shape:
		Shape.IN:
			return TunnelGeometry.TUBE_TURN
		Shape.OUT:
			return -TunnelGeometry.TUBE_TURN
	return 0.0


func _update_shape() -> void:
	geometry.turn = lerpf(turn_for(previous_shape()), turn_for(current_shape()), morph_progress())
