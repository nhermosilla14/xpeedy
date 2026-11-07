class_name RunEvent
extends RefCounted
## Something that happened during a tick that views may want to show (ADR 0008, 0012). Events never
## feed back into the model.

enum Kind { CRASH, OBSTACLE_SMASHED, SHIELD_PICKUP, RACE_STARTED, STOMP, BONUS_PICKUP, BONUS_FIRED, QUAKE, DILATION_ENDED, ZONE_WARNING, ZONE_SECOND, ZONE_STARTED, ZONE_ENDED, PLASMA_TOUCHED, RACE_FINISHED, RECHARGED, TORPEDO_FIRED, TORPEDO_HIT, PHASE_STARTED,
	PHASE_WARNING, PHASE_ENDED, CONTINUED }

var kind := Kind.CRASH
## "obstacle" or "wall" for a crash.
var reason := ""
var obstacle: Obstacle
## The bonus (`SurvivalRun.Bonus`) picked up or fired.
var bonus := 0
## The zone (`Zone.Kind`) of a zone event, and the countdown second of ZONE_SECOND.
var zone := 0
var seconds := 0
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


static func zone_event(event_kind: Kind, zone_kind: int, countdown_seconds := 0) -> RunEvent:
	var e := RunEvent.new()
	e.kind = event_kind
	e.zone = zone_kind
	e.seconds = countdown_seconds
	return e


static func plasma_touched() -> RunEvent:
	var e := RunEvent.new()
	e.kind = Kind.PLASMA_TOUCHED
	return e


## The ship travelled the run length of a stage race.
static func race_finished() -> RunEvent:
	var e := RunEvent.new()
	e.kind = Kind.RACE_FINISHED
	return e


static func simple(event_kind: Kind) -> RunEvent:
	var e := RunEvent.new()
	e.kind = event_kind
	return e


static func torpedo_hit(o: Obstacle) -> RunEvent:
	var e := RunEvent.new()
	e.kind = Kind.TORPEDO_HIT
	e.obstacle = o
	return e
