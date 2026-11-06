class_name RunEvent
extends RefCounted
## Something that happened during a tick that views may want to show (ADR 0008). Events never feed
## back into the model.

enum Kind { OBSTACLE_CRASH }

var kind := Kind.OBSTACLE_CRASH
var obstacle: Obstacle


static func obstacle_crash(o: Obstacle) -> RunEvent:
	var e := RunEvent.new()
	e.kind = Kind.OBSTACLE_CRASH
	e.obstacle = o
	return e
