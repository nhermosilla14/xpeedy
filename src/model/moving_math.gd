class_name MovingMath
extends RefCounted
## Closed-form motion of rollers and bouncers as a function of the run's game time (ADR 0020, doc 04).
## `obstacle.gdshader` repeats these formulas (ADR 0021); keep them in step.

const ROLLER_REST := 0.2
const ROLLER_TURN_BASE := 290.0
const BOUNCER_NEAR := 0.29
const BOUNCER_RANGE := 1.57
const BOUNCER_RANGE_TUBE := 1.96
## Step progress (0-1) below which only the current lane is dangerous, and above which only the destination.
const DANGER_FROM := 0.3
const DANGER_TO := 0.7

const Shape := PartSequence.Shape


## Degrees a roller turns in one step: 60 inside, 90 flat, 120 outside.
static func step_angle(shape: Shape) -> float:
	match shape:
		Shape.FLAT:
			return 90.0
		Shape.OUT:
			return 120.0
	return 60.0


## Seconds one step takes at the target `tps` (ms per segment): the roller turns (290 - tps) degrees per second.
static func roller_step_seconds(tps: float, shape: Shape) -> float:
	return step_angle(shape) / (ROLLER_TURN_BASE - tps)


## Steps a roller has completed at game time `t` (a rest after a step counts as completed).
static func roller_steps(t: float, phase: float, tps: float, shape: Shape) -> int:
	var step := roller_step_seconds(tps, shape)
	var cycle := step + ROLLER_REST
	var shifted := maxf(t + phase, 0.0)
	var n := int(floor(shifted / cycle))
	return n + 1 if shifted - n * cycle >= step else n


## Progress of the step in course, 0 to 1, or -1 while the roller rests.
static func roller_progress(t: float, phase: float, tps: float, shape: Shape) -> float:
	var step := roller_step_seconds(tps, shape)
	var cycle := step + ROLLER_REST
	var shifted := maxf(t + phase, 0.0)
	var u: float = shifted - floor(shifted / cycle) * cycle
	return u / step if u < step else -1.0


## The roller's lane after `steps` steps from `start`: it wraps around a tube and reverses at lane 0 and 15
## on a flat part.
static func roller_lane(start: int, direction: int, steps: int, shape: Shape) -> int:
	if shape == Shape.FLAT:
		var x := posmod(start + direction * steps, 30)
		return x if x <= 15 else 30 - x
	return posmod(start + direction * steps, TrackModel.LANES)


## The lanes a roller is dangerous on (and paints its trail on) at game time `t`.
static func roller_danger(start: int, direction: int, t: float, phase: float, tps: float, shape: Shape) -> Array[int]:
	var k := roller_steps(t, phase, tps, shape)
	var progress := roller_progress(t, phase, tps, shape)
	var here := roller_lane(start, direction, k, shape)
	if progress < 0.0 or progress < DANGER_FROM:
		return [here] as Array[int]
	var there := roller_lane(start, direction, k + 1, shape)
	if progress <= DANGER_TO:
		return [here, there] as Array[int]
	return [there] as Array[int]


## Half the period of a bouncer's up-and-down wave, in seconds.
static func bouncer_half_period(tps: float) -> float:
	return (1000.0 - 4.0 * (tps - 100.0)) / 1000.0


static func bouncer_range(shape: Shape) -> float:
	return BOUNCER_RANGE_TUBE if shape == Shape.IN else BOUNCER_RANGE


## Distance of a bouncer from its tile's surface at game time `t`, in world units.
static func bouncer_height(t: float, phase: float, tps: float, shape: Shape) -> float:
	var half := bouncer_half_period(tps)
	return bouncer_range(shape) * 0.5 * (1.0 - cos(PI * (t + phase) / half))


## The lanes a bouncer is dangerous on: its own while near the surface, and inside a tube the opposite
## lane while it is near the far side.
static func bouncer_danger(lane: int, t: float, phase: float, tps: float, shape: Shape) -> Array[int]:
	var lanes: Array[int] = []
	var h := bouncer_height(t, phase, tps, shape)
	if h < BOUNCER_NEAR:
		lanes.append(lane)
	if shape == Shape.IN and h > bouncer_range(shape) - BOUNCER_NEAR:
		lanes.append((lane + TrackModel.LANES / 2) % TrackModel.LANES)
	return lanes
