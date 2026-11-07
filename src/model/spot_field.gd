class_name SpotField
extends RefCounted
## Shield spot groups, generated as segments enter the horizon (doc 10; ADR 0008). Own PRNG stream:
## seed ^ SEED_SALT. Spots are shields or, when enabled, bonuses (ADR 0022).
##
## Draw order per group at point p: skip chance(1/8); if not skipped: size, then start lane. Then
## the gap to the next group. "random(0 … x)" in doc 10 is inclusive. With a bonus enabled, each spot also
## draws its kind right after the group's start lane: Quake, then Time Dilation, then Space Fold.

signal spot_added(spot: Spot)

const SEED_SALT := 0x5B07
const FIRST_GROUP := 100
const SKIP_CHANCE := 0.125
## The first group of a race is at spacing + 50 (doc 11); a spot rolls for a bonus half of the time, and the
## roll gives Quake, Time Dilation or Space Fold 10 % each.
const RACE_FIRST_OFFSET := 50
const RACE_BONUS_CHANCE := 0.5
const RACE_BONUS_STEP := 0.1
const GROUP_LEVEL_SEGMENTS := 450
const MAX_GROUP := 3
const QUAKE_CHANCE := 0.1
const LATE_QUAKE_SEGMENT := 750
const LATE_QUAKE_CHANCE := 0.2
const DILATION_FROM_SEGMENT := 300
const DILATION_CHANCE := 1.0 / 6.0
const FOLD_CHANCE := 1.0 / 6.0

var version := 0

var _by_segment := {}  # int -> Array[Spot]
var _rng: XRandom
var _next_point := FIRST_GROUP
var _quake: bool
var _dilation: bool
var _fold: bool
## Stage race rules (ADR 0024), or null for Survival.
var _race: RaceSpec


func _init(run_seed: int, quake := false, dilation := false, fold := false, race: RaceSpec = null) -> void:
	_rng = XRandom.new(run_seed ^ SEED_SALT)
	_quake = quake
	_dilation = dilation
	_fold = fold
	_race = race
	if race != null:
		_next_point = _rng.range_int(race.spot_spacing.x, race.spot_spacing.y) + RACE_FIRST_OFFSET


func generate_to(horizon_segment: int) -> void:
	if _race != null:
		_generate_race_to(horizon_segment)
		return
	while _next_point <= horizon_segment:
		var point := _next_point
		var spacing := ObstacleField.spacing_at(point)
		if not _rng.chance(SKIP_CHANCE):
			var size := mini(MAX_GROUP, 1 + _rng.range_int(0, point / GROUP_LEVEL_SEGMENTS + 1))
			var start := _rng.range_int(0, TrackModel.LANES)
			for i in size:
				add(Spot.make(point, (start + i * TrackModel.LANES / size) % TrackModel.LANES, _draw_kind(point)))
		_next_point = point + 3 * spacing + _rng.range_int(0, spacing)


## Race rules: groups of a size range, spacing range, 1 in 8 skipped; spots are shields only when enabled.
func _generate_race_to(horizon_segment: int) -> void:
	while _next_point <= horizon_segment:
		var point := _next_point
		if not _rng.chance(SKIP_CHANCE):
			var size := _rng.range_int(_race.group_size.x, _race.group_size.y)
			var start := _rng.range_int(0, TrackModel.LANES)
			for i in size:
				var kind := _race_kind()
				if kind >= 0:
					add(Spot.make(point, (start + i * TrackModel.LANES / maxi(size, 1)) % TrackModel.LANES, kind))
		_next_point = point + _rng.range_int(_race.spot_spacing.x, _race.spot_spacing.y)


## The kind of a race spot, or -1 when it is left empty.
func _race_kind() -> int:
	if _race.bonuses and _rng.chance(RACE_BONUS_CHANCE):
		var roll := _rng.next_float()
		if roll < RACE_BONUS_STEP:
			return Spot.Kind.QUAKE
		if roll < 2.0 * RACE_BONUS_STEP:
			return Spot.Kind.TIME_DILATION
		if roll < 3.0 * RACE_BONUS_STEP:
			return Spot.Kind.SPACE_FOLD
	return Spot.Kind.SHIELD if _race.shields else -1


## The kind of one spot placed at `point` (doc 10).
func _draw_kind(point: int) -> Spot.Kind:
	if not (_quake or _dilation or _fold):
		return Spot.Kind.SHIELD
	var quake_chance := LATE_QUAKE_CHANCE if point > LATE_QUAKE_SEGMENT else QUAKE_CHANCE
	if _rng.chance(quake_chance):
		return Spot.Kind.QUAKE if _quake else Spot.Kind.SHIELD
	if point > DILATION_FROM_SEGMENT:
		if _rng.chance(DILATION_CHANCE):
			return Spot.Kind.TIME_DILATION if _dilation else Spot.Kind.SHIELD
		if _rng.chance(FOLD_CHANCE):
			return Spot.Kind.SPACE_FOLD if _fold else Spot.Kind.SHIELD
	return Spot.Kind.SHIELD


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
