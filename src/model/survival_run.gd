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
var spots: SpotField
var shields: ShieldStack
var trails := TrailMap.new()
var score := 0

var _events: Array[RunEvent] = []
var _distance_scored := 0


func _init(run_config: RunConfig, run_seed: int) -> void:
	config = run_config
	track = TrackModel.new(config.target_tps, run_seed)
	obstacles = ObstacleField.new(run_seed, track.parts)
	obstacles.obstacle_added.connect(trails.add_obstacle)
	spots = SpotField.new(run_seed)
	spots.spot_added.connect(trails.add_spot)
	shields = ShieldStack.new(config.max_shields, config.shield_decay_seconds)
	for i in config.start_shields:
		shields.add()
	trails.advance(track.window_start())
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
	trails.advance(track.window_start())
	_generate()
	if config.collisions_enabled:
		_resolve_obstacles(seg_before, lane_before)
	if not track.crashed:
		_resolve_spots(seg_before, lane_before)
		shields.tick(dt)
		_score_distance()
	obstacles.forget_before(track.window_start() - 2)
	spots.forget_before(track.window_start() - Spot.LENGTH - 2)


## Returns the events since the last call and clears them.
func take_events() -> Array[RunEvent]:
	var result := _events
	_events = []
	return result


func _generate() -> void:
	var horizon := track.window_start() + TrackModel.VISIBLE_SEGMENTS
	if config.generate_obstacles:
		obstacles.generate_to(horizon)
	if config.generate_spots:
		spots.generate_to(horizon)


## +1 point per whole segment travelled since the start (doc 09).
func _score_distance() -> void:
	var travelled := int(floor(track.segment - TrackModel.START_SEGMENT))
	if travelled > _distance_scored:
		score += travelled - _distance_scored
		_distance_scored = travelled


## The ship's hit box is swept over everything it covered this tick, so a long tick can't skip an obstacle.
func _resolve_obstacles(seg_before: float, lane_before: float) -> void:
	var seg_after := track.segment
	var swept := _swept_lanes(lane_before)
	var lane_min := swept.x
	var lane_max := swept.y
	var wrap := track.obstacles_wrap_seam()
	var opposite := track.geometry.flatness() <= BEAM_OPPOSITE_MAX_FLATNESS

	for s in range(ceili(seg_before - 1.0), floori(seg_after + SHIP_BACK) + 1):
		for o in obstacles.at_segment(s):
			if o.alive and _touches(o, lane_min, lane_max, wrap, opposite):
				track.crash("obstacle")
				_events.append(RunEvent.obstacle_crash(o))
				return


## Collects the shield spots the ship flew over this tick (same sweep as obstacles, three segments long).
func _resolve_spots(seg_before: float, lane_before: float) -> void:
	var swept := _swept_lanes(lane_before)
	var wrap := track.obstacles_wrap_seam()
	for s in range(ceili(seg_before - Spot.LENGTH), floori(track.segment + SHIP_BACK) + 1):
		for spot in spots.at_segment(s):
			if not spot.collected and _lane_hit(spot.lane, swept.x, swept.y, wrap):
				spot.collected = true
				trails.remove_spot(spot)
				shields.add()
				_events.append(RunEvent.shield_pickup(spot))


## The ship's lane range this tick including its half width, kept continuous across the seam.
func _swept_lanes(lane_before: float) -> Vector2:
	var lane_after := track.lane_position()
	if lane_after - lane_before > 8.0:
		lane_after -= TrackModel.LANES
	elif lane_before - lane_after > 8.0:
		lane_after += TrackModel.LANES
	return Vector2(minf(lane_before, lane_after) - SHIP_HALF_WIDTH, maxf(lane_before, lane_after) + SHIP_HALF_WIDTH)


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
