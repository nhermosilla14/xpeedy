class_name Spot
extends RefCounted
## A shield pick-up spot: one lane by three segments, [seg, seg + 3) (doc 06).

const LENGTH := 3

var seg := 0
var lane := 0
var collected := false


static func make(segment: int, lane_index: int) -> Spot:
	var s := Spot.new()
	s.seg = segment
	s.lane = lane_index
	return s
