class_name SpotField
extends RefCounted
## Shield spot groups, generated as segments enter the horizon (doc 10; ADR 0008). Own PRNG stream:
## seed ^ SEED_SALT. Only shield spots exist so far, since bonuses are not implemented.
##
## Draw order per group at point p: skip chance(1/8); if not skipped: size, then start lane. Then
## the gap to the next group. "random(0 … x)" in doc 10 is inclusive.

signal spot_added(spot: Spot)

const SEED_SALT := 0x5B07
const FIRST_GROUP := 100
const SKIP_CHANCE := 0.125
const GROUP_LEVEL_SEGMENTS := 450
const MAX_GROUP := 3

var version := 0

var _by_segment := {}  # int -> Array[Spot]
var _rng: XRandom
var _next_point := FIRST_GROUP


func _init(run_seed: int) -> void:
	_rng = XRandom.new(run_seed ^ SEED_SALT)


func generate_to(horizon_segment: int) -> void:
	while _next_point <= horizon_segment:
		var point := _next_point
		var spacing := ObstacleField.spacing_at(point)
		if not _rng.chance(SKIP_CHANCE):
			var size := mini(MAX_GROUP, 1 + _rng.range_int(0, point / GROUP_LEVEL_SEGMENTS + 1))
			var start := _rng.range_int(0, TrackModel.LANES)
			for i in size:
				add(Spot.make(point, (start + i * TrackModel.LANES / size) % TrackModel.LANES))
		_next_point = point + 3 * spacing + _rng.range_int(0, spacing)


func add(s: Spot) -> void:
	if not _by_segment.has(s.seg):
		_by_segment[s.seg] = [] as Array[Spot]
	_by_segment[s.seg].append(s)
	version += 1
	spot_added.emit(s)


## Spots that start on exactly this segment.
func at_segment(seg: int) -> Array[Spot]:
	if _by_segment.has(seg):
		return _by_segment[seg]
	return [] as Array[Spot]


func all() -> Array[Spot]:
	var result: Array[Spot] = []
	var keys := _by_segment.keys()
	keys.sort()
	for key in keys:
		result.append_array(_by_segment[key])
	return result


## Drops spots that start before `seg`.
func forget_before(seg: int) -> void:
	for key in _by_segment.keys():
		if key < seg:
			_by_segment.erase(key)
			version += 1
