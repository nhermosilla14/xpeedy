class_name ZoneField
extends RefCounted
## Zone marks of a Survival run, generated as segments enter the horizon (doc 10, ADR 0023). Own PRNG
## stream: seed ^ SEED_SALT. A mark is a ring of all 16 lanes on one segment.

signal mark_added(mark: Mark)

const SEED_SALT := 0x20E5
const MAX_REROLLS := 10
const RACE_FIRST_OFFSET := 50


class Mark:
	var seg := 0
	var zone := Zone.Kind.BLACKOUT
	var crossed := false


var version := 0

var _by_segment := {}  # int -> Array[Mark]
var _rng: XRandom
var _enabled: Array[int]
var _gap_extra: int
var _next_point := -1
## Stage race rules (ADR 0024), or null for Survival.
var _race: RaceSpec
var _fixed_added := 0


func _init(run_seed: int, enabled_zones: Array[int], target_tps: float, race: RaceSpec = null) -> void:
	_rng = XRandom.new(run_seed ^ SEED_SALT)
	_enabled = enabled_zones
	# 3000 / TPS segments cover the 3 s countdown.
	_gap_extra = int(3000.0 / target_tps) + 1
	_race = race


func _gap() -> int:
	return 200 + _rng.range_int(0, 201) + _gap_extra


func generate_to(horizon_segment: int) -> void:
	if _race != null:
		_generate_race_to(horizon_segment)
		return
	if _enabled.is_empty():
		return
	if _next_point < 0:
		_next_point = _gap()
	while _next_point <= horizon_segment:
		var point := _next_point
		for attempt in MAX_REROLLS:
			var zone: int = _rng.range_int(1, 6)
			if _enabled.has(zone):
				var mark := Mark.new()
				mark.seg = point
				mark.zone = zone
				add(mark)
				break
		_next_point = point + _gap()


## Race rules: marks at fixed segments, or random ones from the allowed list (doc 11).
func _generate_race_to(horizon_segment: int) -> void:
	match _race.zone_mode:
		RaceSpec.ZoneMode.FIXED:
			while _fixed_added < _race.fixed_zones.size() and _race.fixed_zones[_fixed_added].y <= horizon_segment:
				var mark := Mark.new()
				mark.zone = _race.fixed_zones[_fixed_added].x
				mark.seg = _race.fixed_zones[_fixed_added].y
				add(mark)
				_fixed_added += 1
		RaceSpec.ZoneMode.RANDOM:
			if _next_point < 0:
				_next_point = _race_spacing() + RACE_FIRST_OFFSET
			while _next_point <= horizon_segment:
				var mark := Mark.new()
				mark.seg = _next_point
				mark.zone = _race.allowed_zones[_rng.range_int(0, _race.allowed_zones.size())]
				add(mark)
				_next_point += _race_spacing() + _gap_extra


func _race_spacing() -> int:
	return _rng.range_int(_race.zone_spacing.x, _race.zone_spacing.y)


func add(mark: Mark) -> void:
	if not _by_segment.has(mark.seg):
		_by_segment[mark.seg] = [] as Array[Mark]
	_by_segment[mark.seg].append(mark)
	version += 1
	mark_added.emit(mark)


func at_segment(seg: int) -> Array[Mark]:
	if _by_segment.has(seg):
		return _by_segment[seg]
	return [] as Array[Mark]


func all() -> Array[Mark]:
	var result: Array[Mark] = []
	var keys := _by_segment.keys()
	keys.sort()
	for key in keys:
		result.append_array(_by_segment[key])
	return result


func forget_before(seg: int) -> void:
	for key in _by_segment.keys():
		if key < seg:
			_by_segment.erase(key)
			version += 1
