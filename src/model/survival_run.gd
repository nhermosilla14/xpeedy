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
## The finish line is drawn this many segments before the run length.
const FINISH_LINE_BEFORE := 2

var config: RunConfig
var track: TrackModel
var obstacles: ObstacleField
var spots: SpotField
var shields: ShieldStack
var trails := TrailMap.new()
var score := 0
## A stage race is finished once the ship has travelled the run length (doc 11); the run then stops.
var finished := false
## The part of `score` that came from distance (+1 per segment); the rest are smash points.
var distance_points := 0
## Game time of the run in seconds (the sum of the steps): rollers and bouncers move with it (ADR 0020).
var game_time := 0.0
## The bonus in hand (ADR 0022) and the game seconds Time Dilation has left.
var held := Bonus.NONE
## Hazard zones (ADR 0023): the lifecycle, the pending or active zone and its timer in game seconds.
enum ZoneState { IDLE, COUNTDOWN, ACTIVE }
var zones: ZoneField
var zone_state := ZoneState.IDLE
var zone := Zone.Kind.NONE
var zone_timer := 0.0
## Seconds since the active zone started.
var zone_time := 0.0
## Plasma vortices alive.
var vortices: Array[Vector2i] = []  # (segment, lane)
var dilation_left := 0.0
## Active upgrades (ADR 0029): the Recharger and Phase Shift once per run, the torpedoes left, the ship segment
## at which the next torpedo is reloaded, the torpedoes in flight and the game seconds of Phase Shift left.
var recharger_used := false
var torpedoes_left := 0
var torpedo_ready_at := 0.0
var torpedoes: Array[Torpedo] = []
var phase_used := false
var phase_left := 0.0
var continue_used := false

## The start sequence (ADR 0017): STARTING lasts COUNTDOWN_SECONDS, then RACING. Light i starts at
## LIGHT_START + i seconds and fades over LIGHT_FADE.
enum Phase { STARTING, RACING }
enum Bonus { NONE, QUAKE, TIME_DILATION, SPACE_FOLD }
const DILATION_SECONDS := 7.0
const DILATION_SCALE := 0.75
const QUAKE_EXPLOSIONS := 8
const TORPEDO_SPEED := 2.0
const TORPEDO_RANGE := 25.0
const TORPEDO_HIT_MARGIN := 0.4
const TORPEDO_RELOAD_SEGMENTS := 100.0
const TORPEDO_RELOAD_FACTOR := 1.25
const PHASE_SECONDS_PER_LEVEL := 5.0
const COUNTDOWN_SECONDS := 3.8
const LIGHT_START := 1.3
const LIGHT_FADE := 0.5
var phase := Phase.RACING
## Game time since the run began while STARTING.
var countdown_time := 0.0

var _events: Array[RunEvent] = []
var _zone_rng: XRandom
var _vortex_rng: XRandom
var _gravity_phase1 := 0.0
var _gravity_phase2 := 0.0
var _vortex_next := 0
var _countdown_second := 0
var _finish_painted := false
var _phase_warnings := 0


func _init(run_config: RunConfig, run_seed: int) -> void:
	config = run_config
	track = TrackModel.new(config.target_tps, run_seed, config.parts)
	obstacles = ObstacleField.new(run_seed, track.parts, config.spikes_enabled, config.rollers_enabled, config.bouncers_enabled, config.race)
	obstacles.obstacle_added.connect(trails.add_obstacle)
	spots = SpotField.new(run_seed, config.quake_enabled, config.dilation_enabled, config.fold_enabled, config.race)
	spots.spot_added.connect(trails.add_spot)
	zones = ZoneField.new(run_seed, config.zones, config.target_tps, config.race)
	zones.mark_added.connect(trails.add_mark)
	_zone_rng = XRandom.new(run_seed ^ 0x6A57)
	_vortex_rng = XRandom.new(run_seed ^ 0xC10D)
	shields = ShieldStack.new(config.max_shields, config.shield_decay_seconds)
	score = config.start_score
	torpedoes_left = config.torpedo_level
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
	if finished:
		return
	if track.crashed:
		track.step(dt, steer)
		return
	var seg_before := track.segment
	var lane_before := track.lane_position()
	# Rollers and bouncers freeze during Time Dilation (doc 06).
	if dilation_left <= 0.0:
		game_time += dt
	_tick_dilation(dt)
	track.step(dt, steer + _gravity_steer())
	if track.crashed:
		_events.append(RunEvent.crash(track.crash_reason))
		return
	trails.advance(track.window_start())
	_generate()
	_update_rollers(dt)
	_tick_torpedoes(track.segment - seg_before)
	_tick_phase(dt)
	_resolve_zone_marks(seg_before)
	_tick_zone(dt)
	if config.collisions_enabled:
		_resolve_obstacles(seg_before, lane_before)
	if not track.crashed:
		_resolve_spots(seg_before, lane_before)
		_resolve_vortices(seg_before, lane_before)
		shields.tick(dt)
		if phase == Phase.STARTING:
			_tick_countdown(dt)
		else:
			_score_distance()
		_check_finish()
	obstacles.forget_before(track.window_start() - 2)
	spots.forget_before(track.window_start() - Spot.LENGTH - 2)
	zones.forget_before(track.window_start() - 2)


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


## The bonus a spot gives, kept only when the hand is empty (doc 06).
func _collect_bonus(kind: Spot.Kind) -> void:
	if held != Bonus.NONE:
		return
	held = {Spot.Kind.QUAKE: Bonus.QUAKE, Spot.Kind.TIME_DILATION: Bonus.TIME_DILATION,
		Spot.Kind.SPACE_FOLD: Bonus.SPACE_FOLD}[kind]
	_events.append(RunEvent.bonus_pickup(held))


## Fires the held bonus (doc 06); nothing happens with an empty hand.
func fire() -> void:
	if held == Bonus.NONE or track.crashed:
		return
	var fired := held
	held = Bonus.NONE
	_events.append(RunEvent.bonus_fired(fired))
	match fired:
		Bonus.QUAKE:
			_quake()
		Bonus.TIME_DILATION:
			dilation_left = DILATION_SECONDS
		Bonus.SPACE_FOLD:
			if zone_state == ZoneState.ACTIVE:
				_end_zone()


## The clock scale the view should apply: 0.75 during Time Dilation.
func time_scale() -> float:
	return DILATION_SCALE if dilation_left > 0.0 else 1.0


func _tick_dilation(dt: float) -> void:
	if dilation_left <= 0.0:
		return
	dilation_left -= dt
	if dilation_left <= 0.0:
		dilation_left = 0.0
		_events.append(RunEvent.dilation_ended())


## Destroys every obstacle in the horizon without points or shield cost (doc 06).
func _quake() -> void:
	var window_end := track.window_start() + TrackModel.VISIBLE_SEGMENTS
	var hit: Array[Obstacle] = []
	for o in obstacles.all():
		if o.alive and o.seg >= track.window_start() and o.seg < window_end:
			hit.append(o)
	hit.sort_custom(func(a: Obstacle, b: Obstacle) -> bool: return a.seg < b.seg)
	for o in hit:
		obstacles.destroy(o)
		trails.remove_obstacle(o, obstacles)
	_events.append(RunEvent.quake(hit.slice(0, QUAKE_EXPLOSIONS)))


## The steering offset of Gravity Well this tick (doc 07): 0.3 x g(t), fading out over the last second.
func _gravity_steer() -> float:
	if zone_state != ZoneState.ACTIVE or zone != Zone.Kind.GRAVITY_WELL:
		return 0.0
	return Zone.FORCE_TO_STEER * gravity_value()


## g(t) of the active Gravity Well with the final fade, 0 otherwise; the camera reads it too.
func gravity_value() -> float:
	if zone_state != ZoneState.ACTIVE or zone != Zone.Kind.GRAVITY_WELL:
		return 0.0
	var fade := clampf(zone_timer / Zone.GRAVITY_FADE_SECONDS, 0.0, 1.0)
	return Zone.gravity(zone_time, _gravity_phase1, _gravity_phase2) * fade


## Crossing a zone mark starts the countdown, unless a zone is active or counting down (doc 07).
func _resolve_zone_marks(seg_before: float) -> void:
	for s in range(ceili(seg_before), floori(track.segment) + 1):
		for mark in zones.at_segment(s):
			if mark.crossed:
				continue
			mark.crossed = true
			if zone_state == ZoneState.IDLE:
				zone_state = ZoneState.COUNTDOWN
				zone = mark.zone
				zone_timer = Zone.COUNTDOWN_SECONDS
				_countdown_second = int(Zone.COUNTDOWN_SECONDS)
				_events.append(RunEvent.zone_event(RunEvent.Kind.ZONE_WARNING, zone, _countdown_second))


func _tick_zone(dt: float) -> void:
	match zone_state:
		ZoneState.COUNTDOWN:
			zone_timer -= dt
			var second := ceili(zone_timer)
			if zone_timer <= 0.0:
				_start_zone()
			elif second < _countdown_second:
				_countdown_second = second
				_events.append(RunEvent.zone_event(RunEvent.Kind.ZONE_SECOND, zone, second))
		ZoneState.ACTIVE:
			zone_timer -= dt
			zone_time += dt
			if zone_timer <= 0.0:
				_end_zone()
			elif zone == Zone.Kind.PLASMA_CLOUD:
				_place_vortices()


## Debug (`--zone`): the zone is active now.
func start_zone_now(kind: Zone.Kind) -> void:
	zone = kind
	_start_zone()


func _start_zone() -> void:
	zone_state = ZoneState.ACTIVE
	zone_timer = Zone.DURATION_SECONDS
	zone_time = 0.0
	if zone == Zone.Kind.GRAVITY_WELL:
		_gravity_phase1 = _zone_rng.range_float(0.0, TAU)
		_gravity_phase2 = _zone_rng.range_float(0.0, TAU)
	if zone == Zone.Kind.PLASMA_CLOUD:
		_vortex_next = int(track.segment) + 10 + _vortex_rng.range_int(0, 5)
	_events.append(RunEvent.zone_event(RunEvent.Kind.ZONE_STARTED, zone))


func _end_zone() -> void:
	_events.append(RunEvent.zone_event(RunEvent.Kind.ZONE_ENDED, zone))
	for v in vortices:
		trails.remove_vortex(v.x, v.y)
	vortices.clear()
	zone_state = ZoneState.IDLE
	zone = Zone.Kind.NONE
	zone_timer = 0.0
	zone_time = 0.0


## One vortex every 5-9 segments after the last, a limited number alive at a time (doc 07).
func _place_vortices() -> void:
	var horizon := track.window_start() + TrackModel.VISIBLE_SEGMENTS
	vortices = vortices.filter(func(v: Vector2i) -> bool: return v.x >= track.window_start() - 2)
	while _vortex_next <= horizon and vortices.size() < Zone.max_vortices(config.target_tps):
		var v := Vector2i(_vortex_next, _vortex_rng.range_int(0, TrackModel.LANES))
		vortices.append(v)
		trails.add_vortex(v.x, v.y)
		_vortex_next += _vortex_rng.range_int(5, 10)


## Touching a vortex costs a shield if there is one and throws the held bonus away; it never crashes.
func _resolve_vortices(seg_before: float, lane_before: float) -> void:
	if vortices.is_empty() or phase_left > 0.0:
		return
	var swept := _swept_lanes(lane_before)
	var wrap := track.obstacles_wrap_seam()
	for v in vortices.duplicate():
		if v.x < ceili(seg_before - 1.0) or v.x > floori(track.segment + SHIP_BACK):
			continue
		if _lane_hit(v.y, swept.x, swept.y, wrap):
			vortices.erase(v)
			trails.remove_vortex(v.x, v.y)
			if shields.count > 0:
				shields.lose(1)
			held = Bonus.NONE
			_events.append(RunEvent.plasma_touched())


## Finishes a stage race at its run length.
func _check_finish() -> void:
	if config.run_length > 0 and track.segment >= config.run_length and not finished:
		finished = true
		_events.append(RunEvent.race_finished())


## Shield Recharger: once per run it adds its level in shield units and restarts the decay timer (doc 08).
func use_recharger() -> void:
	if config.recharger_level <= 0 or recharger_used or track.crashed or finished:
		return
	recharger_used = true
	for i in config.recharger_level:
		shields.add()
	_events.append(RunEvent.simple(RunEvent.Kind.RECHARGED))


func can_recharge() -> bool:
	return config.recharger_level > 0 and not recharger_used and not track.crashed and not finished


## Tachyon Torpedo: needs a torpedo left and the previous reload done (doc 08).
func can_fire_torpedo() -> bool:
	return torpedoes_left > 0 and track.segment >= torpedo_ready_at and not track.crashed and not finished


func fire_torpedo() -> void:
	if not can_fire_torpedo():
		return
	var t := Torpedo.new()
	t.seg = track.segment
	t.lane = track.lane_position()
	torpedoes.append(t)
	torpedoes_left -= 1
	if torpedoes_left > 0:
		torpedo_ready_at = track.segment + torpedo_reload_segments()
	_events.append(RunEvent.simple(RunEvent.Kind.TORPEDO_FIRED))


## Segments of travel a reload takes: 100 / 1.25^level.
func torpedo_reload_segments() -> float:
	return TORPEDO_RELOAD_SEGMENTS / pow(TORPEDO_RELOAD_FACTOR, config.torpedo_level)


## How much of the current reload is done, 0 to 1 (1 when ready), for the button's dial.
func torpedo_reload_fraction() -> float:
	return clampf(1.0 - (torpedo_ready_at - track.segment) / torpedo_reload_segments(), 0.0, 1.0)


## Phase Shift: once per run, obstacles and plasma are ignored for 5 or 10 game seconds (doc 08).
func can_phase() -> bool:
	return config.phase_level > 0 and not phase_used and not track.crashed and not finished


func use_phase_shift() -> void:
	if not can_phase():
		return
	phase_used = true
	phase_left = PHASE_SECONDS_PER_LEVEL * config.phase_level
	_phase_warnings = 0
	_events.append(RunEvent.simple(RunEvent.Kind.PHASE_STARTED))


func _tick_phase(dt: float) -> void:
	if phase_left <= 0.0:
		return
	phase_left -= dt
	if phase_left <= 0.0:
		phase_left = 0.0
		_events.append(RunEvent.simple(RunEvent.Kind.PHASE_ENDED))
	elif phase_left <= 1.0 and _phase_warnings < 2:
		_phase_warnings = 2
		_events.append(RunEvent.simple(RunEvent.Kind.PHASE_WARNING))
	elif phase_left <= 2.0 and _phase_warnings < 1:
		_phase_warnings = 1
		_events.append(RunEvent.simple(RunEvent.Kind.PHASE_WARNING))


## Moves the torpedoes (twice the ship's travel this tick) and destroys what they sweep (doc 08).
func _tick_torpedoes(ship_travel: float) -> void:
	for t in torpedoes.duplicate():
		var from_seg: float = t.seg
		t.seg += TORPEDO_SPEED * ship_travel
		for s in range(floori(from_seg - TORPEDO_HIT_MARGIN) - 1, ceili(t.seg + TORPEDO_HIT_MARGIN) + 1):
			for o in obstacles.at_segment(s):
				if not o.alive or from_seg - TORPEDO_HIT_MARGIN > o.seg + 1.0 or t.seg + TORPEDO_HIT_MARGIN < o.seg:
					continue
				if _torpedo_touches(t, o):
					obstacles.destroy(o)
					trails.remove_obstacle(o, obstacles)
					_events.append(RunEvent.torpedo_hit(o))
		if t.seg - track.segment >= TORPEDO_RANGE:
			torpedoes.erase(t)


func _torpedo_touches(t: Torpedo, o: Obstacle) -> bool:
	# A bouncer is hit on its own lane whatever its height; the others where they are.
	var lanes: Array[int] = []
	if o.kind == Obstacle.Kind.BOUNCER:
		lanes.append(o.lane)
	else:
		lanes = o.danger_lanes(game_time, config.target_tps)
	for lane in lanes:
		for shift in [0.0, float(TrackModel.LANES), -float(TrackModel.LANES)]:
			if t.lane + shift >= lane - TORPEDO_HIT_MARGIN and t.lane + shift <= lane + 1.0 + TORPEDO_HIT_MARGIN:
				return true
	return false


## Keep going (doc 13): once per run after an obstacle crash the ship resumes on the spot and a Quake clears
## the way. Returns whether it was allowed.
func can_continue() -> bool:
	return track.crashed and track.crash_reason == "obstacle" and not continue_used and not finished


func continue_run() -> bool:
	if not can_continue():
		return false
	continue_used = true
	track.crashed = false
	track.crash_reason = ""
	track.crash_time = 0.0
	_quake()
	_events.append(RunEvent.simple(RunEvent.Kind.CONTINUED))
	return true


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
	zones.generate_to(horizon)
	if config.run_length > 0 and not _finish_painted and horizon >= config.run_length - FINISH_LINE_BEFORE:
		_finish_painted = true
		trails.add_finish(config.run_length - FINISH_LINE_BEFORE)


## +1 point per whole segment travelled since the start (doc 09).
func _score_distance() -> void:
	var travelled := int(floor(track.segment - TrackModel.START_SEGMENT))
	if travelled > distance_points:
		score += travelled - distance_points
		distance_points = travelled


## The ship's hit box is swept over everything it covered this tick, so a long tick can't skip an obstacle.
## Each obstacle it touches is smashed if the shields cover its cost, in segment order, else it is a crash.
func _resolve_obstacles(seg_before: float, lane_before: float) -> void:
	if phase_left > 0.0:
		return
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
				if spot.kind != Spot.Kind.SHIELD:
					_collect_bonus(spot.kind)
					continue
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
