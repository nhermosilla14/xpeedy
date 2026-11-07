class_name RaceSpec
extends RefCounted
## A stage race as described by its file (doc 11, ADR 0024). Ranges are stored as [from, to] with an
## exclusive upper bound; draw them with `XRandom.range_int(from, to)`.

enum ZoneMode { NONE, RANDOM, FIXED }

const SPEED_FACTOR := 0.87

## The reason the file was rejected, empty when it is valid.
var error := ""

var speed := 0
## Run length of a random track, or 0 when `parts` is given.
var random_length := 0
## Explicit track: Vector2i(shape, length) in order.
var parts: Array[Vector2i] = []

var cubes := true
var beams := false
var rollers := false
var bouncers := false
var spikes := false
var obstacle_spacing := Vector2i(10, 11)
var level := 0

var has_spots := false
var shields := false
var bonuses := false
var spot_spacing := Vector2i(10, 11)
var group_size := Vector2i(1, 2)

var zone_mode := ZoneMode.NONE
var allowed_zones: Array[int] = []
var zone_spacing := Vector2i(10, 11)
## Fixed marks: Vector2i(zone, segment).
var fixed_zones: Array[Vector2i] = []

var seed_value := -1


## Segments travelled to finish the race.
func run_length() -> int:
	if random_length > 0:
		return random_length
	var total := 0
	for part in parts:
		total += part.y
	return total


## Target ms per segment: the file's speed times the stage factor (doc 11).
func target_tps() -> float:
	return speed * SPEED_FACTOR
