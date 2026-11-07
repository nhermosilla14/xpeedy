class_name PartSequence
extends RefCounted
## Random sequence of track parts (doc 02): in, flat and out stretches whose lengths are multiples
## of 120 segments. Generated lazily; parts never change once a later part exists.
##
## Draw order when appending a part: after IN, repeated 50 % "extend" draws until one fails;
## after FLAT, one draw choosing the tube shape; after OUT, none.

enum Shape { IN, FLAT, OUT }

const PART_UNIT := 120
const FIRST_PART_LENGTH := 240  # the first multiple of 120 that is at least 200
const EXTEND_CHANCE := 0.5
const IN_AFTER_OUT_CHANCE := 0.75
const SEED_SALT := 0x5EED0001
const FLAT_MAX_BEND := 30.0
const TUBE_MAX_BEND := 50.0

var _rng: XRandom
var _shapes: PackedInt32Array = [Shape.IN]
var _starts: PackedInt32Array = [0]
var _lengths: PackedInt32Array = [FIRST_PART_LENGTH]
var _last_tube := Shape.IN
## An explicit sequence (stage races): the last shape continues in parts of PART_UNIT segments.
var _fixed := false


## `fixed` is an optional explicit sequence of Vector2i(shape, length); without it the parts are random.
func _init(run_seed: int, fixed: Array[Vector2i] = []) -> void:
	_rng = XRandom.new(run_seed ^ SEED_SALT)
	if fixed.is_empty():
		return
	_fixed = true
	_shapes = PackedInt32Array()
	_starts = PackedInt32Array()
	_lengths = PackedInt32Array()
	var at := 0
	for part in fixed:
		_shapes.append(part.x)
		_starts.append(at)
		_lengths.append(part.y)
		at += part.y


## Index of the part containing `seg`.
func index_at(seg: float) -> int:
	var s := int(floor(seg))
	_ensure(s)
	var i := _starts.size() - 1
	while i > 0 and _starts[i] > s:
		i -= 1
	return i


func shape(index: int) -> Shape:
	_ensure_index(index)
	return _shapes[index] as Shape


func start(index: int) -> int:
	_ensure_index(index)
	return _starts[index]


func length(index: int) -> int:
	_ensure_index(index)
	return _lengths[index]


func shape_at(seg: float) -> Shape:
	return shape(index_at(seg))


## Largest path bend allowed at a control point on `seg` (doc 02): 30° flat, 50° in tubes.
func max_bend_at(seg: int) -> float:
	return FLAT_MAX_BEND if shape_at(seg) == Shape.FLAT else TUBE_MAX_BEND


## Makes sure the part containing `seg` exists and is followed by another part, so its length is final.
func _ensure(seg: int) -> void:
	while _starts.size() < 2 or _starts[_starts.size() - 1] <= seg:
		_append_next()


## Makes sure part `index` exists and is followed by another part.
func _ensure_index(index: int) -> void:
	while _shapes.size() <= index + 1:
		_append_next()


func _append_next() -> void:
	var last := _shapes.size() - 1
	if _fixed:
		_shapes.append(_shapes[last])
		_starts.append(_starts[last] + _lengths[last])
		_lengths.append(PART_UNIT)
		return
	var next := Shape.FLAT
	match _shapes[last]:
		Shape.IN:
			while _rng.chance(EXTEND_CHANCE):
				_lengths[last] += PART_UNIT
		Shape.FLAT:
			var in_chance := IN_AFTER_OUT_CHANCE if _last_tube == Shape.OUT else 0.5
			next = Shape.IN if _rng.chance(in_chance) else Shape.OUT
			_last_tube = next
	_shapes.append(next)
	_starts.append(_starts[last] + _lengths[last])
	_lengths.append(PART_UNIT)
