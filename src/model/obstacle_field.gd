class_name ObstacleField
extends RefCounted
## All obstacles of a run, generated as segments enter the horizon (docs 04, 10; ADR 0008).
##
## Placement is driven only by `generate_to`, never by a request from a view, so the track depends on
## the seed alone. Own PRNG stream: seed ^ SEED_SALT.

## Emitted for every obstacle that is added.
signal obstacle_added(o: Obstacle)

const SEED_SALT := 0x0B57AC1E
const FIRST_PATTERN := 55
const LEVEL_SEGMENTS := 150
## A moving pattern must end before the next shape change: its longest formation is 6 segments.
const MOVING_LOOKAHEAD := 8

## Increases whenever the set of obstacles changes, so views know when to rebuild.
var version := 0

var _by_segment := {}  # int -> Array[Obstacle]
## Every roller still stored (their trails and landings are refreshed every tick).
var rollers: Array[Obstacle] = []
var _rng: XRandom
var _parts: PartSequence
var _next_point := FIRST_PATTERN
var _spikes_enabled: bool
var _rollers_enabled: bool
var _bouncers_enabled: bool

## Placement point of every pattern generated so far, in order.
var placed_points := PackedInt32Array()


func _init(run_seed: int, parts: PartSequence, spikes_enabled: bool = true, rollers_enabled := false, bouncers_enabled := false) -> void:
	_rng = XRandom.new(run_seed ^ SEED_SALT)
	_parts = parts
	_spikes_enabled = spikes_enabled
	_rollers_enabled = rollers_enabled
	_bouncers_enabled = bouncers_enabled


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
		var context := PatternLibrary.Context.new()
		context.shape = _parts.shape_at(point)
		context.spikes_enabled = _spikes_enabled
		context.rollers_enabled = _rollers_enabled
		context.bouncers_enabled = _bouncers_enabled
		context.moving_ok = (_rollers_enabled or _bouncers_enabled) \
				and _parts.index_at(point + MOVING_LOOKAHEAD) == _parts.index_at(point)
		for o in PatternLibrary.generate(level_at(point), _rng, context):
			o.seg += point
			o.shape = _parts.shape_at(o.seg)
			add(o)
		placed_points.append(point)
		_next_point = point + spacing_at(point)


func add(o: Obstacle) -> void:
	if not _by_segment.has(o.seg):
		_by_segment[o.seg] = [] as Array[Obstacle]
	_by_segment[o.seg].append(o)
	if o.kind == Obstacle.Kind.ROLLER:
		rollers.append(o)
	version += 1
	obstacle_added.emit(o)


## Marks an obstacle as destroyed (smashed); views stop drawing it.
func destroy(o: Obstacle) -> void:
	o.alive = false
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
	rollers = rollers.filter(func(o: Obstacle) -> bool: return o.seg >= seg)
	for key in _by_segment.keys():
		if key < seg:
			_by_segment.erase(key)
			dropped = true
	if dropped:
		version += 1
