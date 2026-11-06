class_name ObstacleField
extends RefCounted
## All obstacles of a run, generated as segments enter the horizon (docs 04, 10; ADR 0008).
##
## Placement is driven only by `generate_to`, never by a request from a view, so the track depends on
## the seed alone. Own PRNG stream: seed ^ SEED_SALT.

const SEED_SALT := 0x0B57AC1E
const FIRST_PATTERN := 55
const LEVEL_SEGMENTS := 150

## Increases whenever the set of obstacles changes, so views know when to rebuild.
var version := 0

var _by_segment := {}  # int -> Array[Obstacle]
var _rng: XRandom
var _parts: PartSequence
var _next_point := FIRST_PATTERN


func _init(run_seed: int, parts: PartSequence) -> void:
	_rng = XRandom.new(run_seed ^ SEED_SALT)
	_parts = parts


## Segments between pattern placements at distance `d` (doc 10).
static func spacing_at(d: int) -> int:
	return maxi(8, 12 - d / 300)


## Pattern complexity level at distance `d` (doc 10).
static func level_at(d: int) -> int:
	return d / LEVEL_SEGMENTS


## Places every pattern whose placement point is at or before `horizon_segment`.
func generate_to(horizon_segment: int) -> void:
	while _next_point <= horizon_segment:
		var point := _next_point
		for o in PatternLibrary.generate(level_at(point), _rng):
			o.seg += point
			o.shape = _parts.shape_at(o.seg)
			add(o)
		_next_point = point + spacing_at(point)


func add(o: Obstacle) -> void:
	if not _by_segment.has(o.seg):
		_by_segment[o.seg] = [] as Array[Obstacle]
	_by_segment[o.seg].append(o)
	version += 1


## Obstacles on exactly this segment (empty array if none).
func at_segment(seg: int) -> Array[Obstacle]:
	if _by_segment.has(seg):
		return _by_segment[seg]
	return [] as Array[Obstacle]


## Every stored obstacle, ordered by segment.
func all() -> Array[Obstacle]:
	var result: Array[Obstacle] = []
	var keys := _by_segment.keys()
	keys.sort()
	for key in keys:
		result.append_array(_by_segment[key])
	return result


## Drops obstacles on segments before `seg`.
func forget_before(seg: int) -> void:
	var dropped := false
	for key in _by_segment.keys():
		if key < seg:
			_by_segment.erase(key)
			dropped = true
	if dropped:
		version += 1
