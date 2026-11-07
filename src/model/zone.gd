class_name Zone
extends RefCounted
## Hazard zones (doc 07, ADR 0023): the kinds, their names, mark colours and the Gravity Well force.

enum Kind { NONE, BLACKOUT, GRAVITY_WELL, HUE_SHIFT, DARK_NEBULA, PLASMA_CLOUD }

const COUNTDOWN_SECONDS := 3.0
const DURATION_SECONDS := 7.0
## Gravity Well: the steering offset is FORCE_TO_STEER x g(t), fading out over the last second.
const FORCE_TO_STEER := 0.3
const GRAVITY_FADE_SECONDS := 1.0

const NAMES := {
	Kind.BLACKOUT: "blackout",
	Kind.GRAVITY_WELL: "gravity well",
	Kind.HUE_SHIFT: "hue shift",
	Kind.DARK_NEBULA: "dark nebula",
	Kind.PLASMA_CLOUD: "plasma cloud",
}

## Mark colours (doc 07): amber and magenta, translucent white, dark green, violet and blue, pale lavender.
const MARK_COLOURS := {
	Kind.BLACKOUT: [Color(1.0, 0.7, 0.1), Color(0.9, 0.1, 0.6)],
	Kind.GRAVITY_WELL: [Color(1.0, 1.0, 1.0), Color(0.85, 0.85, 0.95)],
	Kind.HUE_SHIFT: [Color(0.05, 0.4, 0.1), Color(0.1, 0.55, 0.2)],
	Kind.DARK_NEBULA: [Color(0.5, 0.2, 0.8), Color(0.2, 0.3, 0.9)],
	Kind.PLASMA_CLOUD: [Color(0.8, 0.75, 1.0), Color(0.7, 0.7, 0.95)],
}


static func all_kinds() -> Array[int]:
	return [Kind.BLACKOUT, Kind.GRAVITY_WELL, Kind.HUE_SHIFT, Kind.DARK_NEBULA, Kind.PLASMA_CLOUD]


## The sideways gravity of Gravity Well `t` seconds after it started, with random phases (doc 07).
static func gravity(t: float, phase1: float, phase2: float) -> float:
	return 0.25 * (2.5 * sin(2.5 * t + phase1) + 1.5 * sin(1.5 * t + PI / 4.0 + phase2))


## Plasma vortices that may be alive at once for a target speed (doc 07).
static func max_vortices(target_tps: float) -> int:
	if target_tps >= 133.0:
		return 7
	if target_tps >= 100.0:
		return 6
	if target_tps >= 80.0:
		return 4
	return 3
