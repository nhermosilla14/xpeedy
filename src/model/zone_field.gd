class_name ZoneField
extends RefCounted
## Zone marks of a Survival run, generated as segments enter the horizon (doc 10, ADR 0023). Own PRNG
## stream: seed ^ SEED_SALT. A mark is a ring of all 16 lanes on one segment.

signal mark_added(mark: Mark)

const SEED_SALT := 0x20E5
const MAX_REROLLS := 10


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


func _init(run_seed: int, enabled_zones: Array[int], target_tps: float) -> void:
	_rng = XRandom.new(run_seed ^ SEED_SALT)
	_enabled = enabled_zones
	# 3000 / TPS segments cover the 3 s countdown.
	_gap_extra = int(3000.0 / target_tps) + 1


func _gap() -> int:
	return 200 + _rng.range_int(0, 201) + _gap_extra


func generate_to(horizon_segment: int) -> void:
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
