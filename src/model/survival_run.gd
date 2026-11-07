class_name SurvivalRun
extends RefCounted
## A Survival run (ADR 0008): the track and ship plus obstacles, with the rules that connect them.

## The ship is 0.6 segments long and 0.5 lanes wide (doc 04).
const SHIP_BACK := 0.6
const SHIP_HALF_WIDTH := 0.25
## A tube beam also hits the opposite lane while the tunnel is at least 80 % tube-shaped.
const BEAM_OPPOSITE_MAX_FLATNESS := 0.2
## Landings of rollers up to this many segments ahead shake the camera.
const STOMP_RANGE := 12.0

var config: RunConfig
var track: TrackModel
var obstacles: ObstacleField
var spots: SpotField
var shields: ShieldStack
var trails := TrailMap.new()
var score := 0
## The part of `score` that came from distance (+1 per segment); the rest are smash points.
var distance_points := 0
## Game time of the run in seconds (the sum of the steps): rollers and bouncers move with it (ADR 0020).
var game_time := 0.0

## The start sequence (ADR 0017): STARTING lasts COUNTDOWN_SECONDS, then RACING. Light i starts at
## LIGHT_START + i seconds and fades over LIGHT_FADE.
enum Phase { STARTING, RACING }
const COUNTDOWN_SECONDS := 3.8
const LIGHT_START := 1.3
const LIGHT_FADE := 0.5
var phase := Phase.RACING
## Game time since the run began while STARTING.
var countdown_time := 0.0

var _events: Array[RunEvent] = []


func _init(run_config: RunConfig, run_seed: int) -> void:
	config = run_config
	track = TrackModel.new(config.target_tps, run_seed)
	obstacles = ObstacleField.new(run_seed, track.parts, config.spikes_enabled, config.rollers_enabled, config.bouncers_enabled)
	obstacles.obstacle_added.connect(trails.add_obstacle)
	spots = SpotField.new(run_seed)
	spots.spot_added.connect(trails.add_spot)
	shields = ShieldStack.new(config.max_shields, config.shield_decay_seconds)
	for i in config.start_shields:
		shields.add()
	if config.countdown and config.start_segment <= TrackModel.START_SEGMENT:
		phase = Phase.STARTING
		track.ramp_held = true
	trails.advance(track.window_start())
	_generate()
	if config.start_segment > TrackModel.START_SEGMENT:
		_jump_to(config.start_segment)


## Advances the run by `dt` seconds of game time with the processed steer value.
func step(dt: float, steer: float) -> void:
	if track.crashed:
		track.step(dt, steer)
		return
	var seg_before := track.segment
	var lane_before := track.lane_position()
	game_time += dt
	track.step(dt, steer)
	if track.crashed:
		_events.append(RunEvent.crash(track.crash_reason))
		return
	trails.advance(track.window_start())
	_generate()
	_update_rollers(dt)
	if config.collisions_enabled:
		_resolve_obstacles(seg_before, lane_before)
	if not track.crashed:
		_resolve_spots(seg_before, lane_before)
		shields.tick(dt)
		if phase == Phase.STARTING:
			_tick_countdown(dt)
		else:
			_score_distance()
	obstacles.forget_before(track.window_start() - 2)
	spots.forget_before(track.window_start() - Spot.LENGTH - 2)


## Moves the trail of every roller in the window to its danger lanes, and reports landings near the ship.
func _update_rollers(dt: float) -> void:
	var window_end := track.window_start() + TrackModel.VISIBLE_SEGMENTS
	var stomped := false
	for o in obstacles.rollers:
		if not o.alive or o.seg >= window_end:
			continue
		var lanes := o.danger_lanes(game_time, config.target_tps)
		if lanes != o.painted:
			trails.set_lanes(o, lanes, obstacles)
		if not stomped and o.seg - track.segment <= STOMP_RANGE and o.seg >= track.segment - 2.0 \
				and MovingMath.roller_steps(game_time, o.phase, config.target_tps, o.shape) \
				> MovingMath.roller_steps(game_time - dt, o.phase, config.target_tps, o.shape):
			stomped = true
			_events.append(RunEvent.stomp())


func _tick_countdown(dt: float) -> void:
	countdown_time += dt
	if countdown_time >= COUNTDOWN_SECONDS:
		phase = Phase.RACING
		track.ramp_held = false
		distance_points = int(floor(track.segment - TrackModel.START_SEGMENT))
		_events.append(RunEvent.race_started())


## State of start light `i` (0-2): -1 before it lights, then 0 to 1 over its fade (1 = faded out).
func light_progress(i: int) -> float:
	if phase == Phase.RACING:
		return 1.0
	var age := countdown_time - (LIGHT_START + i)
	return -1.0 if age < 0.0 else clampf(age / LIGHT_FADE, 0.0, 1.0)


## Puts the ship deep into the run at full speed (benchmark and debugging), generating everything up to
## there. The score starts from zero at the new place.
func _jump_to(segment: float) -> void:
	track.segment = segment
	track.elapsed = TrackModel.RAMP_SECONDS
	step(0.0, 0.0)
	# The step above scored the whole distance; start counting from here instead.
	score = 0
	distance_points = int(floor(track.segment - TrackModel.START_SEGMENT))


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
	if travelled > distance_points:
		score += travelled - distance_points
		distance_points = travelled


## The ship's hit box is swept over everything it covered this tick, so a long tick can't skip an obstacle.
## Each obstacle it touches is smashed if the shields cover its cost, in segment order, else it is a crash.
func _resolve_obstacles(seg_before: float, lane_before: float) -> void:
	var seg_after := track.segment
	var swept := _swept_lanes(lane_before)
	var lane_min := swept.x
	var lane_max := swept.y
	var wrap := track.obstacles_wrap_seam()
	var opposite := track.geometry.flatness() <= BEAM_OPPOSITE_MAX_FLATNESS

	for s in range(ceili(seg_before - 1.0), floori(seg_after + SHIP_BACK) + 1):
		for o in obstacles.at_segment(s):
			if not (o.alive and _hits(o, lane_min, lane_max, wrap, opposite)):
				continue
			if shields.count < o.shield_cost():
				if not config.crash_on_obstacles:
					continue
				track.crash("obstacle")
				_events.append(RunEvent.crash("obstacle", o))
				return
			_smash(o)


func _smash(o: Obstacle) -> void:
	shields.lose(o.shield_cost())
	score += o.smash_points()
	obstacles.destroy(o)
	trails.remove_obstacle(o, obstacles)
	_events.append(RunEvent.obstacle_smashed(o))


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


func _hits(o: Obstacle, lane_min: float, lane_max: float, wrap: bool, opposite: bool) -> bool:
	if not o.is_moving():
		return _touches(o, lane_min, lane_max, wrap, opposite)
	for lane in o.danger_lanes(game_time, config.target_tps):
		if _lane_hit(lane, lane_min, lane_max, wrap):
			return true
	return false


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
