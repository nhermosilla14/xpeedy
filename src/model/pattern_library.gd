class_name PatternLibrary
extends RefCounted
## Obstacle patterns ("constructs", doc 04) as fixed in ADR 0013. A pattern is a set of obstacles with
## segment offsets relative to its placement point.
##
## Draw order per pattern: level-0 kind or the index; spike chance; wall chance; regular-formation
## choice; formation-specific draws (wall kind, diagonal direction, spread mixed flag and repeat);
## colour; extra colours; per-cell colours of mixed spreads; lane start.

const SPIKE_CHANCE := 1.0 / 3.0
const WALL_CHANCE := 1.0 / 3.0
const MAX_INDEX := 15
## From the level after this one, the single cube (index 0) is no longer drawn.
const LAST_SINGLE_LEVEL := 5
const HALF_RING := TrackModel.LANES / 2


## What the generator needs to know about where the pattern is placed.
class Context:
	var shape := PartSequence.Shape.IN
	var spikes_enabled := true


## A generated pattern with what chose it, for tests and debugging.
class Pattern:
	var index := -1  # -1 for the level-0 single obstacle
	var name := ""
	var variant := "regular"  # "spike", "wall" or "regular"
	var obstacles: Array[Obstacle] = []


class Cell:
	var dseg: int
	var offset: int
	var kind: Obstacle.Kind
	var colour_slot: int

	func _init(segment_offset: int, lane_offset: int, obstacle_kind: Obstacle.Kind, slot: int) -> void:
		dseg = segment_offset
		offset = lane_offset
		kind = obstacle_kind
		colour_slot = slot


class Formation:
	var name := ""
	var cells: Array[Cell] = []
	## Ring formations wrap around the tunnel on every shape; the others must fit the ribbon on flat parts.
	var wraps := false
	var extra_colours := 0
	## Every cell draws its own colour.
	var mixed := false

	func _init(formation_name: String) -> void:
		name = formation_name

	func add(segment_offset: int, lane_offset: int, kind: Obstacle.Kind, slot: int = 0) -> void:
		cells.append(Cell.new(segment_offset, lane_offset, kind, slot))


static func generate(level: int, rng: XRandom, context: Context) -> Array[Obstacle]:
	return generate_detailed(level, rng, context).obstacles


static func generate_detailed(level: int, rng: XRandom, context: Context) -> Pattern:
	if level <= 0:
		var pattern := Pattern.new()
		var formation := _single(Obstacle.Kind.CUBE if rng.chance(0.5) else Obstacle.Kind.BEAM)
		pattern.name = formation.name
		pattern.obstacles = _place(formation, rng, context)
		return pattern
	return generate_for_index(pick_index(level, rng), rng, context)


## A pattern of a given index (0-15), choosing its formation as ADR 0013 says.
static func generate_for_index(index: int, rng: XRandom, context: Context) -> Pattern:
	var pattern := Pattern.new()
	pattern.index = index
	var choice := _choose(index, rng, context)
	var formation: Formation = choice[0]
	pattern.variant = choice[1]
	pattern.name = formation.name
	pattern.obstacles = _place(formation, rng, context)
	return pattern


## Pattern index for a level of 1 or more (ADR 0013).
static func pick_index(level: int, rng: XRandom) -> int:
	var top := mini(level, MAX_INDEX)
	if level > LAST_SINGLE_LEVEL:
		return rng.range_int(1, top + 1)
	return rng.range_int(0, top + 1)


## Chooses the formation of an index: spike, then wall, then regular (ADR 0013).
static func _choose(index: int, rng: XRandom, context: Context) -> Array:
	var alternatives := _alternatives(index)
	var spike: Array = alternatives.get("spike", [])
	var wall: Array = alternatives.get("wall", [])
	var regular: Array = alternatives["regular"]
	if not spike.is_empty() and context.spikes_enabled and rng.chance(SPIKE_CHANCE):
		return [_pick(spike, rng).call(rng), "spike"]
	if not wall.is_empty() and context.shape != PartSequence.Shape.IN and rng.chance(WALL_CHANCE):
		return [_pick(wall, rng).call(rng), "wall"]
	return [_pick(regular, rng).call(rng), "regular"]


static func _pick(options: Array, rng: XRandom) -> Callable:
	if options.size() == 1:
		return options[0]
	return options[rng.range_int(0, options.size())]


## The doc 04 table: formation builders per index, split into spike, wall and regular ones.
static func _alternatives(index: int) -> Dictionary:
	var cube := Obstacle.Kind.CUBE
	var beam := Obstacle.Kind.BEAM
	var spike := Obstacle.Kind.SPIKE
	match index:
		0:
			return {"regular": [func(_r: XRandom) -> Formation: return PatternLibrary._single(cube)]}
		1:
			return {"regular": [func(_r: XRandom) -> Formation: return PatternLibrary._single(beam)]}
		2:
			return {
				"wall": [func(r: XRandom) -> Formation:
					return PatternLibrary._walls(2, [0], beam if r.chance(0.5) else cube)],
				"regular": [func(_r: XRandom) -> Formation: return PatternLibrary._apart(2, HALF_RING, cube)],
			}
		3:
			return {
				"spike": [func(_r: XRandom) -> Formation: return PatternLibrary._walls(3, [0], spike)],
				"wall": [func(_r: XRandom) -> Formation: return PatternLibrary._walls(3, [0], cube)],
				"regular": [
					func(_r: XRandom) -> Formation: return PatternLibrary._apart(3, 5, cube),
					func(r: XRandom) -> Formation: return PatternLibrary._diagonals(3, [0], cube, r),
				],
			}
		4:
			return {
				"spike": [func(_r: XRandom) -> Formation: return PatternLibrary._walls(2, [0, HALF_RING], spike)],
				"regular": [func(r: XRandom) -> Formation: return PatternLibrary._diagonals(2, [0, HALF_RING], cube, r)],
			}
		5:
			return {"regular": [
				func(r: XRandom) -> Formation: return PatternLibrary._diagonals(2, [0], beam, r),
				func(_r: XRandom) -> Formation: return PatternLibrary._apart(3, 3, cube),
			]}
		6:
			return {"regular": [func(r: XRandom) -> Formation:
				return PatternLibrary._spread(3, cube, r, r.chance(0.5))]}
		7:
			return {"regular": [
				func(_r: XRandom) -> Formation: return PatternLibrary._pendulum(),
				func(r: XRandom) -> Formation: return PatternLibrary._diagonals(3, [0, HALF_RING], cube, r, true),
			]}
		8:
			return {"regular": [func(_r: XRandom) -> Formation: return PatternLibrary._apart(3, 3, cube)]}
		9:
			return {
				"spike": [func(_r: XRandom) -> Formation: return PatternLibrary._walls(4, [0], spike)],
				"wall": [func(_r: XRandom) -> Formation: return PatternLibrary._walls(4, [0], cube)],
				"regular": [
					func(_r: XRandom) -> Formation: return PatternLibrary._cross(),
					func(r: XRandom) -> Formation: return PatternLibrary._spread(4, cube, r),
				],
			}
		10:
			return {
				"spike": [func(_r: XRandom) -> Formation: return PatternLibrary._walls(4, [0], spike)],
				"wall": [func(_r: XRandom) -> Formation: return PatternLibrary._walls(4, [0], cube)],
				"regular": [func(r: XRandom) -> Formation: return PatternLibrary._spread(4, cube, r)],
			}
		11:
			return {"regular": [func(r: XRandom) -> Formation:
				return PatternLibrary._diagonals(2, [0, 5, 10], cube, r)]}
		12:
			return {"regular": [
				func(r: XRandom) -> Formation: return PatternLibrary._diagonals(3, [0], beam, r),
				func(r: XRandom) -> Formation: return PatternLibrary._diagonals(2, [0, HALF_RING], beam, r),
			]}
		13:
			return {"regular": [func(r: XRandom) -> Formation: return PatternLibrary._diagonals(8, [0], cube, r)]}
		14:
			return {"regular": [func(r: XRandom) -> Formation:
				return PatternLibrary._diagonals(3, [0, HALF_RING], cube, r, true)]}
		_:
			return {
				"spike": [
					func(_r: XRandom) -> Formation: return PatternLibrary._walls(3, [0, HALF_RING], spike),
					func(_r: XRandom) -> Formation: return PatternLibrary._walls(6, [0], spike),
					func(_r: XRandom) -> Formation: return PatternLibrary._walls(2, [0, 5, 10], spike),
				],
				"regular": [func(r: XRandom) -> Formation: return PatternLibrary._spread(6, cube, r)],
			}


# --- Formation builders ---

static func _kind_name(kind: Obstacle.Kind) -> String:
	match kind:
		Obstacle.Kind.BEAM:
			return "beams"
		Obstacle.Kind.SPIKE:
			return "spikes"
	return "cubes"


static func _single(kind: Obstacle.Kind) -> Formation:
	var f := Formation.new("single_beam" if kind == Obstacle.Kind.BEAM else "single_cube")
	f.add(0, 0, kind)
	return f


## Solid walls `width` lanes wide, one starting at each lane offset in `starts`.
static func _walls(width: int, starts: Array, kind: Obstacle.Kind) -> Formation:
	var name := "wall%d_%s" % [width, _kind_name(kind)]
	if starts.size() > 1:
		name = "walls%dx%d_%s" % [width, starts.size(), _kind_name(kind)]
	var f := Formation.new(name)
	for start in starts:
		for i in width:
			f.add(0, start + i, kind)
	return f


## `count` obstacles on one segment, `gap` lanes apart.
static func _apart(count: int, gap: int, kind: Obstacle.Kind) -> Formation:
	var f := Formation.new("apart%dx%d_%s" % [count, gap, _kind_name(kind)])
	f.wraps = true
	for i in count:
		f.add(0, i * gap, kind)
	return f


## Diagonals of `length` segments, one per lane offset in `starts`, all moving one lane per segment in
## a direction drawn 50/50. Two-colour diagonals colour their second diagonal differently.
static func _diagonals(length: int, starts: Array, kind: Obstacle.Kind, rng: XRandom, two_colours: bool = false) -> Formation:
	var direction := 1 if rng.chance(0.5) else -1
	var name := "diagonal%d_%s" % [length, _kind_name(kind)]
	if starts.size() > 1:
		name = "diagonals%dx%d_%s" % [length, starts.size(), _kind_name(kind)]
	if two_colours:
		name += "_two_colours"
	var f := Formation.new(name)
	f.extra_colours = 1 if two_colours else 0
	for s in starts.size():
		for k in length:
			f.add(k, starts[s] + direction * k, kind, s if two_colours else 0)
	return f


## `count` obstacles evenly spread around the ring; up to four may repeat on 1-4 consecutive segments.
static func _spread(count: int, kind: Obstacle.Kind, rng: XRandom, mixed: bool = false) -> Formation:
	var repeat := 1
	if count <= 4 and rng.chance(0.5):
		repeat = rng.range_int(1, 5)
	var f := Formation.new("spread%d_%s%s" % [count, _kind_name(kind), "_mixed" if mixed else ""])
	f.wraps = true
	f.mixed = mixed
	for r in repeat:
		for i in count:
			f.add(r, i * TrackModel.LANES / count, kind)
	return f


static func _pendulum() -> Formation:
	var f := Formation.new("pendulum")
	f.add(0, 0, Obstacle.Kind.CUBE)
	f.add(1, 4, Obstacle.Kind.BEAM)
	f.add(2, HALF_RING, Obstacle.Kind.CUBE)
	return f


static func _cross() -> Formation:
	var f := Formation.new("cross")
	f.wraps = true
	f.add(0, 0, Obstacle.Kind.BEAM)
	f.add(1, 4, Obstacle.Kind.BEAM)
	return f


## Draws the colours and the start lane, and turns the formation into obstacles.
static func _place(f: Formation, rng: XRandom, context: Context) -> Array[Obstacle]:
	var colours: Array[int] = [rng.range_int(0, Obstacle.COLOURS)]
	for i in f.extra_colours:
		colours.append(rng.range_int(0, Obstacle.COLOURS))
	var cell_colours: Array[int] = []
	var lowest := f.cells[0].offset
	var highest := f.cells[0].offset
	for cell in f.cells:
		cell_colours.append(rng.range_int(0, Obstacle.COLOURS) if f.mixed else colours[cell.colour_slot])
		lowest = mini(lowest, cell.offset)
		highest = maxi(highest, cell.offset)
	var start: int
	if not f.wraps and context.shape == PartSequence.Shape.FLAT:
		# The ribbon doesn't wrap: every lane must stay in 0-15.
		start = rng.range_int(-lowest, TrackModel.LANES - highest)
	else:
		start = rng.range_int(0, TrackModel.LANES)
	var result: Array[Obstacle] = []
	for i in f.cells.size():
		var cell := f.cells[i]
		result.append(Obstacle.make(cell.dseg, posmod(start + cell.offset, TrackModel.LANES), cell.kind, cell_colours[i]))
	return result
