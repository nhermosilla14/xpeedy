class_name PathModel
extends RefCounted
## The tunnel's centre line (doc 02), generated on demand as one frame per segment.
##
## Control points are 10–20 segment lengths apart and joined by cubic Hermite pieces, so the direction
## is continuous. Each piece is resampled at equal arc length so every segment has the same length.
## The "up" vector is carried with minimal rotation, so the tunnel never rolls by itself.

const STRAIGHT_START := 30.0
const MIN_SPACING := 10.0
const MAX_SPACING := 20.0
const STRAIGHT_CHANCE := 0.5
const MIN_BEND_DEG := 10.0
const MAX_ATTEMPTS := 6
const SAMPLES_PER_PIECE := 64

## Largest accepted bend in degrees; 50 in tubes, 30 on flat parts (set by the shape model later).
var max_bend_deg := 50.0
## Accepted bends and spacings, in generation order (for tests and debugging).
var turn_log: PackedFloat32Array = []
var spacing_log: PackedFloat32Array = []

var _rng: XRandom
var _seg_len: float

# Segment frames, indexed from _base.
var _base := 0
var _pos: PackedVector3Array = []
var _fwd: PackedVector3Array = []
var _up: PackedVector3Array = []

# Generator state: end of the last piece, and the walk along the dense polyline.
var _cp_pos := Vector3.ZERO
var _cp_dir := Vector3.FORWARD
var _cp_up := Vector3.UP
var _carry := 0.0  # distance already walked past the last emitted segment point
var _last_sample := Vector3.ZERO
var _last_up := Vector3.UP
var _last_fwd := Vector3.FORWARD


func _init(seed_value: int, segment_length: float) -> void:
	_rng = XRandom.new(seed_value)
	_seg_len = segment_length
	_pos.append(Vector3.ZERO)
	_fwd.append(Vector3.FORWARD)
	_up.append(Vector3.UP)
	_append_piece(_cp_dir, STRAIGHT_START * _seg_len)


func position(seg: int) -> Vector3:
	_ensure(seg)
	return _pos[seg - _base]


func forward(seg: int) -> Vector3:
	_ensure(seg)
	return _fwd[seg - _base]


func up(seg: int) -> Vector3:
	_ensure(seg)
	return _up[seg - _base]


func right(seg: int) -> Vector3:
	return forward(seg).cross(up(seg))


## Drops frames before `seg`; they can't be requested again.
func forget_before(seg: int) -> void:
	var drop := mini(seg - _base, _pos.size() - 1)
	if drop <= 0:
		return
	_pos = _pos.slice(drop)
	_fwd = _fwd.slice(drop)
	_up = _up.slice(drop)
	_base += drop


func _ensure(seg: int) -> void:
	assert(seg >= _base, "segment %d was already forgotten" % seg)
	while seg - _base >= _pos.size():
		_next_piece()


func _next_piece() -> void:
	var spacing := _rng.range_float(MIN_SPACING, MAX_SPACING)
	spacing_log.append(spacing)
	var new_dir := _cp_dir
	if not _rng.chance(STRAIGHT_CHANCE):
		new_dir = _choose_turn()
	_append_piece(new_dir, spacing * _seg_len)


## Random yaw and pitch, each up to a random 60°–90°; accepted only if the bend is in range.
func _choose_turn() -> Vector3:
	var right_axis := _cp_dir.cross(_cp_up).normalized()
	for attempt in MAX_ATTEMPTS:
		var limit := deg_to_rad(_rng.range_float(60.0, 90.0))
		var yaw := _rng.range_float(-limit, limit)
		var pitch := _rng.range_float(-limit, limit)
		var dir := _cp_dir.rotated(_cp_up, yaw).rotated(right_axis, pitch).normalized()
		var bend := rad_to_deg(_cp_dir.angle_to(dir))
		if bend > MIN_BEND_DEG and bend < max_bend_deg:
			turn_log.append(bend)
			return dir
	return _cp_dir


## Adds a Hermite piece from the current control point to a new one, emitting segment frames.
func _append_piece(new_dir: Vector3, length: float) -> void:
	var p0 := _cp_pos
	var d0 := _cp_dir
	var mid := (d0 + new_dir).normalized()
	var p1 := p0 + mid * length
	var t0 := d0 * length
	var t1 := new_dir * length
	for i in range(1, SAMPLES_PER_PIECE + 1):
		var t := float(i) / SAMPLES_PER_PIECE
		var sample := _hermite(p0, t0, p1, t1, t)
		var tangent := _hermite_tangent(p0, t0, p1, t1, t).normalized()
		_last_up = _transport(_last_up, _last_fwd, tangent)
		_last_fwd = tangent
		var step := _last_sample.distance_to(sample)
		while _carry + step >= _seg_len:
			var f := (_seg_len - _carry) / step
			var point := _last_sample.lerp(sample, f)
			_pos.append(point)
			_fwd.append(tangent)
			_up.append(_last_up)
			step -= _seg_len - _carry
			_carry = 0.0
			_last_sample = point
		_carry += step
		_last_sample = sample
	_cp_pos = p1
	_cp_up = _last_up
	_cp_dir = new_dir


## Rotates `up` by the smallest rotation taking `from_dir` to `to_dir`, then re-orthogonalises.
static func _transport(up_vec: Vector3, from_dir: Vector3, to_dir: Vector3) -> Vector3:
	var axis := from_dir.cross(to_dir)
	if axis.length_squared() > 1e-12:
		up_vec = up_vec.rotated(axis.normalized(), from_dir.angle_to(to_dir))
	return (up_vec - to_dir * up_vec.dot(to_dir)).normalized()


static func _hermite(p0: Vector3, t0: Vector3, p1: Vector3, t1: Vector3, t: float) -> Vector3:
	var t2 := t * t
	var t3 := t2 * t
	return (2.0 * t3 - 3.0 * t2 + 1.0) * p0 + (t3 - 2.0 * t2 + t) * t0 \
		+ (-2.0 * t3 + 3.0 * t2) * p1 + (t3 - t2) * t1


static func _hermite_tangent(p0: Vector3, t0: Vector3, p1: Vector3, t1: Vector3, t: float) -> Vector3:
	var t2 := t * t
	return (6.0 * t2 - 6.0 * t) * p0 + (3.0 * t2 - 4.0 * t + 1.0) * t0 \
		+ (-6.0 * t2 + 6.0 * t) * p1 + (3.0 * t2 - 2.0 * t) * t1
