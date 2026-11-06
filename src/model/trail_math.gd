class_name TrailMath
extends RefCounted
## Reference formulas for warning trails (doc 04). `tunnel.gdshader` repeats them on the GPU (ADR 0009);
## these are the versions the tests check against the doc.

## An obstacle's trail is invisible until the obstacle is closer than this many segments.
const VISIBLE_AHEAD := 25.0
## The trail then fades in linearly over this many segments of approach.
const FADE_SEGMENTS := 10.0
## The red-orange highlight starts at this distance and is full at HIGHLIGHT_FULL.
const HIGHLIGHT_START := 15.0
const HIGHLIGHT_FULL := 5.0
## No highlight when the ship is this many lanes or more from the centre of the trail's lane.
const HIGHLIGHT_LANES := 1.5
const WARNING := Color(0.94, 0.12, 0.05)


## How much of the obstacle's colour shows, by the obstacle's distance ahead of the ship.
static func fade(dist: float) -> float:
	return clampf((VISIBLE_AHEAD - dist) / FADE_SEGMENTS, 0.0, 1.0)


## Strength of the highlight from the obstacle's distance alone: 0 at 15 segments, 1 at 5.
static func approach(dist: float) -> float:
	return clampf((HIGHLIGHT_START - dist) / (HIGHLIGHT_START - HIGHLIGHT_FULL), 0.0, 1.0)


## How the highlight falls off with the ship's lateral distance `d` in lanes.
static func lateral(d: float) -> float:
	return sqrt(maxf(0.0, HIGHLIGHT_LANES - d))


static func highlight(dist: float, d: float) -> float:
	return clampf(approach(dist) * lateral(d), 0.0, 1.0)


## Distance in lanes from the ship to the centre of `lane`; around the ring when the seam is open.
static func lane_distance(ship_lane: float, lane: int, wrap: bool) -> float:
	var d := absf(ship_lane - (float(lane) + 0.5))
	if wrap:
		d = minf(d, float(TrackModel.LANES) - d)
	return d


## Colour of a trail tile. `weight` scales the whole trail (opposite-lane beam trails use the
## tunnel's tube-ness).
static func tile_colour(base: Color, obstacle: Color, dist: float, lateral_distance: float, weight: float = 1.0) -> Color:
	var colour := base.lerp(obstacle, fade(dist) * weight)
	return colour.lerp(WARNING, clampf(highlight(dist, lateral_distance) * weight, 0.0, 1.0))
