class_name Obstacle
extends RefCounted
## A single obstacle on one tile: lanes [lane, lane + 1) × segments [seg, seg + 1) (doc 04).

enum Kind { CUBE, BEAM, SPIKE }

const COLOURS := 5

var seg := 0
var lane := 0
var kind := Kind.CUBE
var colour := 0
## Shape of the part at its segment when it was generated: a beam is a tube beam only inside IN parts.
var shape := PartSequence.Shape.IN
var alive := true


static func make(segment: int, lane_index: int, obstacle_kind: Kind, colour_index: int) -> Obstacle:
	var o := Obstacle.new()
	o.seg = segment
	o.lane = lane_index
	o.kind = obstacle_kind
	o.colour = colour_index
	return o


## True for a beam that also occupies the opposite lane while the tunnel is tube-shaped.
func is_tube_beam() -> bool:
	return kind == Kind.BEAM and shape == PartSequence.Shape.IN


## Shield units needed to smash it (doc 04): a beam needs 2, everything else 1.
func shield_cost() -> int:
	return 2 if kind == Kind.BEAM else 1


## Points for smashing it (doc 04, 09).
func smash_points() -> int:
	return 300 if kind == Kind.BEAM else 100
