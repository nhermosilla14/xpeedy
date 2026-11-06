class_name TrailMap
extends RefCounted
## Per-tile data for the warning trails (ADR 0009), a ring buffer of 64 segment rows × 16 lanes.
## Each texel is four floats, laid out for the GPU:
##   R = palette colour index, or -1 when the tile has no trail
##   G = absolute segment of the obstacle the trail leads to
##   B = 1 when this is the opposite-lane trail of a tube beam
##   A = 1 when the tile is part of a shield spot (slice 0008)
## Row `seg & 63` belongs to segment `seg`; a row is cleared when a different segment claims it, so
## nothing is rewritten when the window scrolls.

const ROWS := 64
const LANES := TrackModel.LANES
const TRAIL_LENGTH := 25
const FLOATS_PER_TEXEL := 4

## The texels, row-major: ((seg & 63) * 16 + lane) * 4.
var data := PackedFloat32Array()
## Increases whenever `data` changes.
var version := 0

var _first := 0
var _owner := PackedInt32Array()  # segment currently held by each row, -1 for none


func _init() -> void:
	data.resize(ROWS * LANES * FLOATS_PER_TEXEL)
	_owner.resize(ROWS)
	for row in ROWS:
		_clear_row(row)
		_owner[row] = -1


## Moves the window: rows of the segments that came into view are claimed (and cleared if stale).
func advance(first: int) -> void:
	_first = first
	for seg in range(first, first + TrackModel.VISIBLE_SEGMENTS):
		_claim(seg)


## Paints the trail of `o` on its lane, and on the opposite lane for a tube beam.
func add_obstacle(o: Obstacle) -> void:
	_paint(o.lane, o.seg, o.colour, false)
	if o.is_tube_beam():
		_paint((o.lane + LANES / 2) % LANES, o.seg, o.colour, true)


## Removes the trail of `o`. Trails of farther obstacles it was covering are painted again.
func remove_obstacle(o: Obstacle, field: ObstacleField) -> void:
	var lanes := [o.lane]
	if o.is_tube_beam():
		lanes.append((o.lane + LANES / 2) % LANES)
	for lane in lanes:
		for seg in range(o.seg - TRAIL_LENGTH, o.seg + 1):
			if _owns(seg) and data[_index(seg, lane)] >= 0.0 and int(data[_index(seg, lane) + 1]) == o.seg:
				_clear_texel(_index(seg, lane))
	for seg in range(o.seg + 1, o.seg + TRAIL_LENGTH + 1):
		for other in field.at_segment(seg):
			if other != o and other.alive:
				add_obstacle(other)
	version += 1


## The texel for a tile as (colour, obstacle segment, opposite, spot); colour is -1 for no trail.
func texel(seg: int, lane: int) -> Color:
	if not _owns(seg):
		return Color(-1.0, 0.0, 0.0, 0.0)
	var i := _index(seg, lane)
	return Color(data[i], data[i + 1], data[i + 2], data[i + 3])


func _paint(lane: int, obstacle_seg: int, colour: int, opposite: bool) -> void:
	for seg in range(obstacle_seg - TRAIL_LENGTH, obstacle_seg + 1):
		if seg < _first or seg >= _first + ROWS:
			continue
		_claim(seg)
		var i := _index(seg, lane)
		# The nearest obstacle ahead of a tile owns it.
		if data[i] >= 0.0 and int(data[i + 1]) <= obstacle_seg:
			continue
		data[i] = float(colour)
		data[i + 1] = float(obstacle_seg)
		data[i + 2] = 1.0 if opposite else 0.0
	version += 1


func _owns(seg: int) -> bool:
	return _owner[seg & (ROWS - 1)] == seg


func _claim(seg: int) -> void:
	var row := seg & (ROWS - 1)
	if _owner[row] != seg:
		_clear_row(row)
		_owner[row] = seg
		version += 1


func _clear_row(row: int) -> void:
	for lane in LANES:
		_clear_texel((row * LANES + lane) * FLOATS_PER_TEXEL)


func _clear_texel(i: int) -> void:
	data[i] = -1.0
	data[i + 1] = 0.0
	data[i + 2] = 0.0
	data[i + 3] = 0.0


func _index(seg: int, lane: int) -> int:
	return ((seg & (ROWS - 1)) * LANES + lane) * FLOATS_PER_TEXEL
