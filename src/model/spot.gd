class_name Spot
extends RefCounted
## A pick-up spot: one lane by three segments, [seg, seg + 3) (doc 06). Shield by default; bonus spots (ADR 0022).

enum Kind { SHIELD, QUAKE, TIME_DILATION, SPACE_FOLD }

const LENGTH := 3

var seg := 0
var lane := 0
var collected := false
var kind := Kind.SHIELD


static func make(segment: int, lane_index: int, spot_kind: Kind = Kind.SHIELD) -> Spot:
	var s := Spot.new()
	s.kind = spot_kind
	s.seg = segment
	s.lane = lane_index
	return s
