class_name RunEvent
extends RefCounted
## Something that happened during a tick that views may want to show (ADR 0008, 0012). Events never
## feed back into the model.

enum Kind { CRASH, OBSTACLE_SMASHED, SHIELD_PICKUP, RACE_STARTED }

var kind := Kind.CRASH
## "obstacle" or "wall" for a crash.
var reason := ""
var obstacle: Obstacle
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
