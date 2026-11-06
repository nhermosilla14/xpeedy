class_name TrailMap
extends RefCounted
## Per-tile data for the warning trails (ADR 0011), a ring buffer of 64 segment rows × 16 lanes.
## Each tile is four bytes, laid out for an RGBA8 texture:
##   R = palette colour index + 1, or 0 when the tile has no trail
##   G = the obstacle's segment minus the tile's segment (0-25)
##   B = 255 for the opposite-lane trail of a tube beam, else 0
##   A = 255 when the tile is part of a shield spot (slice 0008), else 0
## Row `seg & 63` belongs to segment `seg`; a row is cleared when a different segment claims it, so
## nothing is rewritten when the window scrolls.

const ROWS := 64
const LANES := TrackModel.LANES
const TRAIL_LENGTH := 25
const BYTES_PER_TILE := 4

## The tiles, row-major: ((seg & 63) * 16 + lane) * 4.
var data := PackedByteArray()
## Increases whenever `data` changes.
var version := 0

var _first := 0
var _owner := PackedInt32Array()  # segment currently held by each row, -1 for none


func _init() -> void:
	data.resize(ROWS * LANES * BYTES_PER_TILE)
	data.fill(0)
	_owner.resize(ROWS)
	_owner.fill(-1)


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
			if _owns(seg) and _obstacle_segment(seg, lane) == o.seg:
				_clear_trail(_index(seg, lane))
	for seg in range(o.seg + 1, o.seg + TRAIL_LENGTH + 1):
		for other in field.at_segment(seg):
			if other != o and other.alive:
				add_obstacle(other)
	version += 1


## Marks the three tiles of a shield spot.
func add_spot(spot: Spot) -> void:
	_set_spot_flag(spot, 255)


## Clears the spot marks of a collected spot.
func remove_spot(spot: Spot) -> void:
	_set_spot_flag(spot, 0)


## A tile as (colour index, obstacle segment, opposite lane 0/1, spot 0/1). The colour is -1 and the
## segment 0 when the tile has no trail.
func texel(seg: int, lane: int) -> Color:
	if not _owns(seg):
		return Color(-1.0, 0.0, 0.0, 0.0)
	var i := _index(seg, lane)
	if data[i] == 0:
		return Color(-1.0, 0.0, 0.0, 1.0 if data[i + 3] != 0 else 0.0)
	return Color(float(data[i] - 1), float(seg + data[i + 1]), 1.0 if data[i + 2] != 0 else 0.0,
		1.0 if data[i + 3] != 0 else 0.0)


## The obstacle segment a tile's trail leads to, or -1 when it has none.
func _obstacle_segment(seg: int, lane: int) -> int:
	var i := _index(seg, lane)
	return seg + data[i + 1] if data[i] != 0 else -1


func _paint(lane: int, obstacle_seg: int, colour: int, opposite: bool) -> void:
	for seg in range(obstacle_seg - TRAIL_LENGTH, obstacle_seg + 1):
		if seg < _first or seg >= _first + ROWS:
			continue
		_claim(seg)
		var i := _index(seg, lane)
		# The nearest obstacle ahead of a tile owns it.
		if data[i] != 0 and seg + data[i + 1] <= obstacle_seg:
			continue
		data[i] = colour + 1
		data[i + 1] = obstacle_seg - seg
		data[i + 2] = 255 if opposite else 0
	version += 1


func _set_spot_flag(spot: Spot, value: int) -> void:
	for seg in range(spot.seg, spot.seg + Spot.LENGTH):
		if seg < _first or seg >= _first + ROWS:
			continue
		_claim(seg)
		data[_index(seg, spot.lane) + 3] = value
	version += 1


func _owns(seg: int) -> bool:
	return _owner[seg & (ROWS - 1)] == seg


func _claim(seg: int) -> void:
	var row := seg & (ROWS - 1)
	if _owner[row] != seg:
		for i in range(row * LANES * BYTES_PER_TILE, (row + 1) * LANES * BYTES_PER_TILE):
			data[i] = 0
		_owner[row] = seg
		version += 1


## Clears the trail part of a tile and leaves the spot flag alone.
func _clear_trail(i: int) -> void:
	data[i] = 0
	data[i + 1] = 0
	data[i + 2] = 0


func _index(seg: int, lane: int) -> int:
	return ((seg & (ROWS - 1)) * LANES + lane) * BYTES_PER_TILE
