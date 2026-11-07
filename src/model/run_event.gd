class_name RunEvent
extends RefCounted
## Something that happened during a tick that views may want to show (ADR 0008, 0012). Events never
## feed back into the model.

enum Kind { CRASH, OBSTACLE_SMASHED, SHIELD_PICKUP, RACE_STARTED, STOMP, BONUS_PICKUP, BONUS_FIRED, QUAKE, DILATION_ENDED }

var kind := Kind.CRASH
## "obstacle" or "wall" for a crash.
var reason := ""
var obstacle: Obstacle
## The bonus (`SurvivalRun.Bonus`) picked up or fired.
var bonus := 0
## The obstacles a Quake destroyed that get an explosion (the nearest, at most 8).
var destroyed: Array[Obstacle] = []
var spot: Spot
## Points awarded by a smash.
var points := 0


static func crash(crash_reason: String, o: Obstacle = null) -> RunEvent:
	var e := RunEvent.new()
	e.kind = Kind.CRASH
	e.reason = crash_reason
	e.obstacle = o
	return e


static func obstacle_smashed(o: Obstacle) -> RunEvent:
	var e := RunEvent.new()
	e.kind = Kind.OBSTACLE_SMASHED
	e.obstacle = o
	e.points = o.smash_points()
	return e


static func shield_pickup(s: Spot) -> RunEvent:
	var e := RunEvent.new()
	e.kind = Kind.SHIELD_PICKUP
	e.spot = s
	return e


static func race_started() -> RunEvent:
	var e := RunEvent.new()
	e.kind = Kind.RACE_STARTED
	return e


## A roller near the ship landed (the camera shakes).
static func stomp() -> RunEvent:
	var e := RunEvent.new()
	e.kind = Kind.STOMP
	return e


static func bonus_pickup(held: int) -> RunEvent:
	var e := RunEvent.new()
	e.kind = Kind.BONUS_PICKUP
	e.bonus = held
	return e


static func bonus_fired(fired: int) -> RunEvent:
	var e := RunEvent.new()
	e.kind = Kind.BONUS_FIRED
	e.bonus = fired
	return e


static func quake(nearest: Array[Obstacle]) -> RunEvent:
	var e := RunEvent.new()
	e.kind = Kind.QUAKE
	e.destroyed = nearest
	return e


static func dilation_ended() -> RunEvent:
	var e := RunEvent.new()
	e.kind = Kind.DILATION_ENDED
	return e
