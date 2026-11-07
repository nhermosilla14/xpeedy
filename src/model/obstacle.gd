class_name Obstacle
extends RefCounted
## A single obstacle on one tile: lanes [lane, lane + 1) × segments [seg, seg + 1) (doc 04).

enum Kind { CUBE, BEAM, SPIKE, ROLLER, BOUNCER }

const COLOURS := 5

var seg := 0
var lane := 0
var kind := Kind.CUBE
var colour := 0
## Shape of the part at its segment when it was generated: a beam is a tube beam only inside IN parts.
var shape := PartSequence.Shape.IN
var alive := true
## Rollers and bouncers (ADR 0020): +1 or -1 turning direction (rollers) and the motion's phase in seconds.
var direction := 1
var phase := 0.0
## The lanes a roller's trail is painted on right now (kept by the run).
var painted: Array[int] = []


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


func is_moving() -> bool:
	return kind == Kind.ROLLER or kind == Kind.BOUNCER


## The lanes it is dangerous on at game time `t` with the run's target speed `tps` (ADR 0020).
func danger_lanes(t: float, tps: float) -> Array[int]:
	match kind:
		Kind.ROLLER:
			return MovingMath.roller_danger(lane, direction, t, phase, tps, shape)
		Kind.BOUNCER:
			return MovingMath.bouncer_danger(lane, t, phase, tps, shape)
	var lanes: Array[int] = [lane]
	if is_tube_beam():
		lanes.append((lane + TrackModel.LANES / 2) % TrackModel.LANES)
	return lanes


## The lanes its trail is painted on, as (lane, is the opposite lane of a tube beam) pairs of the form [lane, flag].
func trail_lanes() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	match kind:
		Kind.BOUNCER:
			pass
		Kind.ROLLER:
			for l in painted:
				result.append(Vector2i(l, 0))
		_:
			result.append(Vector2i(lane, 0))
			if is_tube_beam():
				result.append(Vector2i((lane + TrackModel.LANES / 2) % TrackModel.LANES, 1))
	return result


## Shield units needed to smash it (doc 04): a beam needs 2, everything else 1.
func shield_cost() -> int:
	return 2 if kind == Kind.BEAM else 1


## Points for smashing it (doc 04, 09).
func smash_points() -> int:
	match kind:
		Kind.BEAM:
			return 300
		Kind.ROLLER, Kind.BOUNCER:
			return 200
	return 100
