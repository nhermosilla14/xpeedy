class_name Autopilot
extends RefCounted
## Debug pilot (`-- --autopilot=plough` on the command line, also the benchmark pilot of slice 0011).
## It steers into the nearest obstacle the shields can pay for, else towards the nearest shield spot,
## else straight on. Returns a raw steer value in [-1, 1], like the input device.

const LOOK_AHEAD := 40


static func plough(run: SurvivalRun) -> float:
	var target := _target_lane(run)
	if target < 0.0:
		return 0.0
	var error := target - run.track.lane_position()
	if run.track.obstacles_wrap_seam():
		error = fposmod(error + 8.0, 16.0) - 8.0
	# Positive steer moves towards lower lane numbers.
	return clampf(-error * 3.0, -1.0, 1.0)


## Lane position (a lane centre) to head for, or -1 when there is nothing worth heading for.
static func _target_lane(run: SurvivalRun) -> float:
	var first := ceili(run.track.segment)
	for seg in range(first, first + LOOK_AHEAD):
		for o in run.obstacles.at_segment(seg):
			if o.alive and run.shields.count >= o.shield_cost():
				return o.lane + 0.5
	for seg in range(first, first + LOOK_AHEAD):
		for spot in run.spots.at_segment(seg):
			if not spot.collected:
				return spot.lane + 0.5
	return -1.0
