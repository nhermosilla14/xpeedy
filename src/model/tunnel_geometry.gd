class_name TunnelGeometry
extends RefCounted
## Maps track coordinates (segment, lane position) to world space. Slice 0001: straight path, inside
## shape only. Lane position grows to the left, so decreasing it moves the ship to the right (doc 03).

const LANE_ANGLE := TAU / TrackModel.LANES


static func vertex(lane_vertex: int, seg: float) -> Vector3:
	var a := (8.0 - float(lane_vertex)) * LANE_ANGLE
	return Vector3(sin(a), -cos(a), -seg * TrackModel.SEGMENT_LENGTH) * Vector3(TrackModel.RADIUS, TrackModel.RADIUS, 1.0)


## Point on the lane surface at a fractional lane position.
static func surface(lane_pos: float, seg: float) -> Vector3:
	var x := fposmod(lane_pos, float(TrackModel.LANES))
	var k := int(floor(x))
	return vertex(k, seg).lerp(vertex(k + 1, seg), x - float(k))


## Unit normal of the lane face pointing into the tube (the "up" of a ship riding inside).
static func normal(lane_pos: float, seg: float) -> Vector3:
	var k := int(floor(fposmod(lane_pos, float(TrackModel.LANES))))
	var mid := (vertex(k, seg) + vertex(k + 1, seg)) * 0.5
	var centre := Vector3(0.0, 0.0, -seg * TrackModel.SEGMENT_LENGTH)
	return (centre - mid).normalized()
