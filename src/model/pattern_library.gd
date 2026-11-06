class_name PatternLibrary
extends RefCounted
## Obstacle patterns ("constructs", doc 04). Returned obstacles carry segment offsets relative to the
## placement point, and are not yet positioned in a part.
##
## Only the level-0 pattern exists so far (slice 0006): a single cube or beam.
## Draw order, level 0: chance(0.5) cube-or-beam; lane range_int(0, 16); colour range_int(0, 5).


static func generate(level: int, rng: XRandom) -> Array[Obstacle]:
	var result: Array[Obstacle] = []
	var kind := Obstacle.Kind.CUBE if rng.chance(0.5) else Obstacle.Kind.BEAM
	var lane := rng.range_int(0, TrackModel.LANES)
	var colour := rng.range_int(0, Obstacle.COLOURS)
	result.append(Obstacle.make(0, lane, kind, colour))
	return result
