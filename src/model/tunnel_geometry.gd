class_name TunnelGeometry
extends RefCounted
## Maps track coordinates (segment, lane position) to world space (ADR 0006).
##
## The cross-section is a chain of 16 faces anchored at lane vertex 8, directly below the centre line.
## Each face turns by `turn` radians relative to its neighbour: +TUBE_TURN inside, 0 flat, -TUBE_TURN
## outside. Lane position grows to the left, so decreasing it moves the ship to the right (doc 03).

const TUBE_TURN := TAU / 16.0
const ANCHOR_VERTEX := 8

var path: PathModel
## Current face turn angle for the whole visible tunnel.
var turn := TUBE_TURN:
	set(value):
		if value != turn:
			turn = value
			_build_chain()

# Cross-section in the frame's (right, up) plane: 17 vertices and 16 face normals.
var _local: PackedVector2Array = []
var _normals: PackedVector2Array = []


func _init(path_model: PathModel) -> void:
	path = path_model
	_build_chain()


## 0 in tubes, 1 when flat; in between while morphing.
func flatness() -> float:
	return 1.0 - absf(turn) / TUBE_TURN


## Ring vertex `lane_vertex` (0–16) at an integer segment.
func vertex(lane_vertex: int, seg: int) -> Vector3:
	return _to_world(_local[lane_vertex], seg)


## All 17 vertices of the cross-section at an integer segment.
func ring(seg: int) -> PackedVector3Array:
	var centre := path.position(seg)
	var r := path.right(seg)
	var u := path.up(seg)
	var result := PackedVector3Array()
	result.resize(_local.size())
	for k in _local.size():
		result[k] = centre + r * _local[k].x + u * _local[k].y
	return result


## Point on the lane surface at a fractional lane position and segment.
func surface(lane_pos: float, seg: float) -> Vector3:
	var s := int(floor(seg))
	return _surface_at(lane_pos, s).lerp(_surface_at(lane_pos, s + 1), seg - float(s))


## Unit normal on the ship's side of the surface, at a fractional segment.
func normal(lane_pos: float, seg: float) -> Vector3:
	var s := int(floor(seg))
	var n := _normals[_face(lane_pos)]
	return (_dir_to_world(n, s).lerp(_dir_to_world(n, s + 1), seg - float(s))).normalized()


func _surface_at(lane_pos: float, seg: int) -> Vector3:
	var k := _face(lane_pos)
	var x := clampf(lane_pos - float(k), 0.0, 1.0)
	return _to_world(_local[k].lerp(_local[k + 1], x), seg)


static func _face(lane_pos: float) -> int:
	return clampi(int(floor(fposmod(lane_pos, float(TrackModel.LANES)))), 0, TrackModel.LANES - 1)


func _to_world(p: Vector2, seg: int) -> Vector3:
	return path.position(seg) + path.right(seg) * p.x + path.up(seg) * p.y


func _dir_to_world(d: Vector2, seg: int) -> Vector3:
	return path.right(seg) * d.x + path.up(seg) * d.y


func _build_chain() -> void:
	var w := TrackModel.SEGMENT_LENGTH
	_local.resize(TrackModel.LANES + 1)
	_local[ANCHOR_VERTEX] = Vector2(0.0, -TrackModel.RADIUS)
	for j in range(1, ANCHOR_VERTEX + 1):
		var theta := (float(j) - 0.5) * turn
		# Lower lane numbers lie to the right (+x), higher ones to the left (-x).
		_local[ANCHOR_VERTEX - j] = _local[ANCHOR_VERTEX - j + 1] + w * Vector2(cos(theta), sin(theta))
		_local[ANCHOR_VERTEX + j] = _local[ANCHOR_VERTEX + j - 1] + w * Vector2(-cos(theta), sin(theta))
	_normals.resize(TrackModel.LANES)
	for k in TrackModel.LANES:
		var e := _local[k + 1] - _local[k]
		_normals[k] = Vector2(e.y, -e.x).normalized()
