class_name RunEvent
extends RefCounted
## Something that happened during a tick that views may want to show (ADR 0008). Events never feed
## back into the model.

enum Kind { OBSTACLE_CRASH, SHIELD_PICKUP }

var kind := Kind.OBSTACLE_CRASH
var obstacle: Obstacle
var spot: Spot


static func obstacle_crash(o: Obstacle) -> RunEvent:
	var e := RunEvent.new()
	e.kind = Kind.OBSTACLE_CRASH
	e.obstacle = o
	return e


static func shield_pickup(s: Spot) -> RunEvent:
	var e := RunEvent.new()
	e.kind = Kind.SHIELD_PICKUP
	e.spot = s
	return e
