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

# Cross-section in the frame's (right, up) plane: 17 vertices, 16 face normals and 17 vertex normals.
var _local: PackedVector2Array = []
var _normals: PackedVector2Array = []
var _vertex_normals: PackedVector2Array = []


func _init(path_model: PathModel) -> void:
	path = path_model
	_build_chain()


## 0 in tubes, 1 when flat; in between while morphing.
func flatness() -> float:
	return 1.0 - absf(turn) / TUBE_TURN


## Ring vertex `lane_vertex` (0–16) at an integer segment.
func vertex(lane_vertex: int, seg: int) -> Vector3:
	return _to_world(_local[lane_vertex], seg)


## The 17 cross-section points in the frame's (right, up) plane, for the current turn angle.
func section() -> PackedVector2Array:
	return _local


## Point on the lane surface at a fractional lane position and segment.
func surface(lane_pos: float, seg: float) -> Vector3:
	var s := int(floor(seg))
	return _surface_at(lane_pos, s).lerp(_surface_at(lane_pos, s + 1), seg - float(s))


## Unit normal on the ship's side of the surface, at a fractional segment. It is blended across the
## face between vertex normals, so it turns smoothly from lane to lane instead of jumping by the face
## angle at every lane boundary; at the centre of a lane it equals the face normal.
func normal(lane_pos: float, seg: float) -> Vector3:
	var s := int(floor(seg))
	var n := smooth_normal_2d(lane_pos)
	return (_dir_to_world(n, s).lerp(_dir_to_world(n, s + 1), seg - float(s))).normalized()


## The blended normal in the cross-section plane.
func smooth_normal_2d(lane_pos: float) -> Vector2:
	var f := _face_and_fraction(lane_pos)
	var k := int(f.x)
	return _vertex_normals[k].slerp(_vertex_normals[k + 1], f.y).normalized()


func _surface_at(lane_pos: float, seg: int) -> Vector3:
	var f := _face_and_fraction(lane_pos)
	var k := int(f.x)
	return _to_world(_local[k].lerp(_local[k + 1], f.y), seg)


## Face index and position across it, for a lane position in [0, 16]. 16 is the far edge of face 15
## (the left edge on flat parts), not lane 0.
## Returned as (face, fraction); the face is a whole number.
static func _face_and_fraction(lane_pos: float) -> Vector2:
	var lanes := float(TrackModel.LANES)
	if lane_pos >= lanes:
		return Vector2(lanes - 1.0, 1.0)
	var x := maxf(lane_pos, 0.0)
	var k := floorf(x)
	return Vector2(k, x - k)


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
	# Inner vertices average their two faces. The seam vertices do so only when the chain is closed
	# (a full tube); otherwise they are edges and keep their single face's normal.
	_vertex_normals.resize(TrackModel.LANES + 1)
	for k in range(1, TrackModel.LANES):
		_vertex_normals[k] = (_normals[k - 1] + _normals[k]).normalized()
	var closed := _local[0].distance_to(_local[TrackModel.LANES]) < 0.001
	var seam := (_normals[TrackModel.LANES - 1] + _normals[0]).normalized()
	_vertex_normals[0] = seam if closed else _normals[0]
	_vertex_normals[TrackModel.LANES] = seam if closed else _normals[TrackModel.LANES - 1]
