class_name TunnelGeometry
extends RefCounted
## Maps track coordinates (segment, lane position) to world space along the path's segment frames.
## Inside shape only (slice 0003). Lane position grows to the left, so decreasing it moves the ship to
## the right (doc 03). Lane 8's vertex sits straight "below" the centre line.

const LANE_ANGLE := TAU / TrackModel.LANES

var path: PathModel
# Per-lane-vertex (sin, cos) of the ring angle; index 16 repeats 0.
var _ring: PackedVector2Array = []


func _init(path_model: PathModel) -> void:
	path = path_model
	for k in TrackModel.LANES + 1:
		var a := (8.0 - float(k)) * LANE_ANGLE
		_ring.append(Vector2(sin(a), cos(a)))


## Ring vertex `lane_vertex` at an integer segment.
func vertex(lane_vertex: int, seg: int) -> Vector3:
	var sc := _ring[posmod(lane_vertex, TrackModel.LANES)]
	var offset := path.right(seg) * sc.x - path.up(seg) * sc.y
	return path.position(seg) + offset * TrackModel.RADIUS


## All 17 vertices of the ring at an integer segment (the last repeats the first).
func ring(seg: int) -> PackedVector3Array:
	var centre := path.position(seg)
	var r := path.right(seg) * TrackModel.RADIUS
	var u := path.up(seg) * TrackModel.RADIUS
	var result := PackedVector3Array()
	result.resize(TrackModel.LANES + 1)
	for k in TrackModel.LANES + 1:
		result[k] = centre + r * _ring[k].x - u * _ring[k].y
	return result


## Point on the lane surface at a fractional lane position and segment.
func surface(lane_pos: float, seg: float) -> Vector3:
	var s := int(floor(seg))
	return _surface_at(lane_pos, s).lerp(_surface_at(lane_pos, s + 1), seg - float(s))


## Unit normal pointing into the tube (the "up" of a ship riding inside), at a fractional segment.
func normal(lane_pos: float, seg: float) -> Vector3:
	var s := int(floor(seg))
	return _normal_at(lane_pos, s).lerp(_normal_at(lane_pos, s + 1), seg - float(s)).normalized()


func _surface_at(lane_pos: float, seg: int) -> Vector3:
	var x := fposmod(lane_pos, float(TrackModel.LANES))
	var k := int(floor(x))
	return vertex(k, seg).lerp(vertex(k + 1, seg), x - float(k))


func _normal_at(lane_pos: float, seg: int) -> Vector3:
	var k := int(floor(fposmod(lane_pos, float(TrackModel.LANES))))
	var mid := (vertex(k, seg) + vertex(k + 1, seg)) * 0.5
	return (path.position(seg) - mid).normalized()
