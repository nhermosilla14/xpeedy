class_name SurvivalRun
extends RefCounted
## A Survival run (ADR 0008): the track and ship plus obstacles, with the rules that connect them.

## The ship is 0.6 segments long and 0.5 lanes wide (doc 04).
const SHIP_BACK := 0.6
const SHIP_HALF_WIDTH := 0.25
## A tube beam also hits the opposite lane while the tunnel is at least 80 % tube-shaped.
const BEAM_OPPOSITE_MAX_FLATNESS := 0.2

var config: RunConfig
var track: TrackModel
var obstacles: ObstacleField

var _events: Array[RunEvent] = []


func _init(run_config: RunConfig, run_seed: int) -> void:
	config = run_config
	track = TrackModel.new(config.target_tps, run_seed)
	obstacles = ObstacleField.new(run_seed, track.parts)
	_generate()


## Advances the run by `dt` seconds of game time with the processed steer value.
func step(dt: float, steer: float) -> void:
	if track.crashed:
		track.step(dt, steer)
		return
	var seg_before := track.segment
	var lane_before := track.lane_position()
	track.step(dt, steer)
	if track.crashed:
		return
	_generate()
	if config.collisions_enabled:
		_resolve_obstacles(seg_before, lane_before)
	obstacles.forget_before(track.window_start() - 2)


## Returns the events since the last call and clears them.
func take_events() -> Array[RunEvent]:
	var result := _events
	_events = []
	return result


func _generate() -> void:
	if config.generate_obstacles:
		obstacles.generate_to(track.window_start() + TrackModel.VISIBLE_SEGMENTS)


## The ship's hit box is swept over everything it covered this tick, so a long tick can't skip an obstacle.
func _resolve_obstacles(seg_before: float, lane_before: float) -> void:
	var seg_after := track.segment
	var lane_after := track.lane_position()
	# A seam crossing makes the lane position jump by ~16; keep the sweep continuous.
	if lane_after - lane_before > 8.0:
		lane_after -= TrackModel.LANES
	elif lane_before - lane_after > 8.0:
		lane_after += TrackModel.LANES
	var lane_min := minf(lane_before, lane_after) - SHIP_HALF_WIDTH
	var lane_max := maxf(lane_before, lane_after) + SHIP_HALF_WIDTH
	var wrap := track.current_shape() != PartSequence.Shape.FLAT and not track.is_morphing()
	var opposite := track.geometry.flatness() <= BEAM_OPPOSITE_MAX_FLATNESS

	for s in range(ceili(seg_before - 1.0), floori(seg_after + SHIP_BACK) + 1):
		for o in obstacles.at_segment(s):
			if o.alive and _touches(o, lane_min, lane_max, wrap, opposite):
				track.crash("obstacle")
				_events.append(RunEvent.obstacle_crash(o))
				return


static func _touches(o: Obstacle, lane_min: float, lane_max: float, wrap: bool, opposite: bool) -> bool:
	if _lane_hit(o.lane, lane_min, lane_max, wrap):
		return true
	return opposite and o.is_tube_beam() \
			and _lane_hit((o.lane + 8) % TrackModel.LANES, lane_min, lane_max, wrap)


## Does the ship's lane range [lane_min, lane_max] overlap the tile [lane, lane + 1]?
## With `wrap`, the tile is also tested one ring turn either way (the seam).
static func _lane_hit(lane: int, lane_min: float, lane_max: float, wrap: bool) -> bool:
	for shift in ([0, TrackModel.LANES, -TrackModel.LANES] if wrap else [0]):
		var lo := float(lane + shift)
		if lane_max >= lo and lane_min <= lo + 1.0:
			return true
	return false
