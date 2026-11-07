class_name RaceParser
extends RefCounted
## Reads a race description file (doc 11, ADR 0024). `parse` returns a RaceSpec; when the text is
## malformed its `error` says why. `define` and `constructs` lines are accepted and ignored.

const ZONE_NAMES := {"blackout": 1, "gravity": 2, "hueshift": 3, "nebula": 4, "plasma": 5}
const SHAPES := {"in": PartSequence.Shape.IN, "flat": PartSequence.Shape.FLAT, "out": PartSequence.Shape.OUT}
const KNOWN := ["speed", "track", "obstacles", "bonuses", "zones", "define", "constructs", "seed"]


static func parse(text: String) -> RaceSpec:
	var spec := RaceSpec.new()
	var seen := {}
	for raw in text.split("\n"):
		var line := raw.get_slice("#", 0).strip_edges()
		if line.is_empty():
			continue
		var colon := line.find(":")
		if colon < 0:
			return _fail(spec, "missing ':' in '%s'" % line)
		var key := line.substr(0, colon).strip_edges().to_lower()
		var value := line.substr(colon + 1).strip_edges()
		if not KNOWN.has(key):
			return _fail(spec, "unknown property '%s'" % key)
		if key == "define" or key == "constructs":
			continue
		if seen.has(key):
			return _fail(spec, "property '%s' appears twice" % key)
		seen[key] = true
		var problem := ""
		match key:
			"speed":
				problem = _speed(spec, value)
			"track":
				problem = _track(spec, value)
			"obstacles":
				problem = _obstacles(spec, value)
			"bonuses":
				problem = _bonuses(spec, value)
			"zones":
				problem = _zones(spec, value)
			"seed":
				problem = _seed(spec, value)
		if problem != "":
			return _fail(spec, "%s: %s" % [key, problem])
	for required in ["speed", "track", "obstacles"]:
		if not seen.has(required):
			return _fail(spec, "missing required property '%s'" % required)
	return spec


static func _fail(spec: RaceSpec, message: String) -> RaceSpec:
	spec.error = message
	return spec


static func _tokens(value: String) -> PackedStringArray:
	var result := PackedStringArray()
	for token in value.split(","):
		var t := token.strip_edges().to_lower()
		if not t.is_empty():
			result.append(t)
	return result


## "a-b" or "a" as [from, to]; empty Vector2i(-1, -1) when it is not a range.
static func _range(token: String) -> Vector2i:
	var parts := token.split("-")
	if parts.size() == 1 and token.is_valid_int():
		return Vector2i(token.to_int(), token.to_int())
	if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
		return Vector2i(parts[0].to_int(), parts[1].to_int())
	return Vector2i(-1, -1)


static func _speed(spec: RaceSpec, value: String) -> String:
	if not value.is_valid_int() or value.to_int() <= 0:
		return "expected a positive integer"
	spec.speed = value.to_int()
	return ""


static func _track(spec: RaceSpec, value: String) -> String:
	var tokens := _tokens(value)
	if tokens.is_empty():
		return "empty"
	if tokens[0].begins_with("random:"):
		var length := tokens[0].get_slice(":", 1).strip_edges()
		if tokens.size() != 1 or not length.is_valid_int() or length.to_int() <= 0:
			return "expected random:<length>"
		spec.random_length = length.to_int()
		return ""
	for token in tokens:
		var shape := token.get_slice(":", 0).strip_edges()
		var length := token.get_slice(":", 1).strip_edges()
		if not SHAPES.has(shape) or not length.is_valid_int() or length.to_int() <= 0:
			return "expected <shape>:<length> with in, flat or out, got '%s'" % token
		spec.parts.append(Vector2i(SHAPES[shape], length.to_int()))
	return ""


static func _obstacles(spec: RaceSpec, value: String) -> String:
	var tokens := _tokens(value)
	if tokens.size() < 3:
		return "expected types, a spacing range and a level"
	var level := tokens[tokens.size() - 1]
	var spacing := _range(tokens[tokens.size() - 2])
	if not level.is_valid_int() or spacing.x < 0:
		return "expected a spacing range and a level at the end"
	spec.level = level.to_int()
	spec.obstacle_spacing = spacing
	var has_cubes := false
	spec.beams = false
	for i in tokens.size() - 2:
		match tokens[i]:
			"all":
				has_cubes = true
				spec.beams = true
				spec.rollers = true
				spec.bouncers = true
				spec.spikes = true
			"cubes":
				has_cubes = true
			"beams":
				spec.beams = true
			"rollers":
				spec.rollers = true
			"bouncers":
				spec.bouncers = true
			"spikes":
				spec.spikes = true
			_:
				return "unknown obstacle type '%s'" % tokens[i]
	if not has_cubes:
		return "cubes are mandatory"
	return ""


static func _bonuses(spec: RaceSpec, value: String) -> String:
	var tokens := _tokens(value)
	if tokens.size() < 3:
		return "expected kinds, a spacing range and a group size range"
	var group := _range(tokens[tokens.size() - 1])
	var spacing := _range(tokens[tokens.size() - 2])
	if group.x < 0 or spacing.x < 0:
		return "expected two ranges at the end"
	for i in tokens.size() - 2:
		match tokens[i]:
			"shields":
				spec.shields = true
			"bonuses":
				spec.bonuses = true
			"all":
				spec.shields = true
				spec.bonuses = true
			_:
				return "unknown kind '%s'" % tokens[i]
	spec.has_spots = true
	spec.spot_spacing = spacing
	spec.group_size = group
	return ""


static func _zones(spec: RaceSpec, value: String) -> String:
	var tokens := _tokens(value)
	if tokens.is_empty():
		return "empty"
	if tokens[0] == "random":
		var spacing := _range(tokens[tokens.size() - 1])
		if tokens.size() < 3 or spacing.x < 0:
			return "expected random, zone names and a spacing range"
		for i in range(1, tokens.size() - 1):
			if tokens[i] == "all":
				for zone in ZONE_NAMES.values():
					if not spec.allowed_zones.has(zone):
						spec.allowed_zones.append(zone)
			elif ZONE_NAMES.has(tokens[i]):
				if not spec.allowed_zones.has(ZONE_NAMES[tokens[i]]):
					spec.allowed_zones.append(ZONE_NAMES[tokens[i]])
			else:
				return "unknown zone '%s'" % tokens[i]
		spec.zone_mode = RaceSpec.ZoneMode.RANDOM
		spec.zone_spacing = spacing
		return ""
	for token in tokens:
		var name := token.get_slice("@", 0).strip_edges()
		var at := token.get_slice("@", 1).strip_edges()
		if not token.contains("@") or not ZONE_NAMES.has(name) or not at.is_valid_int():
			return "expected <zone>@<segment>, got '%s'" % token
		spec.fixed_zones.append(Vector2i(ZONE_NAMES[name], at.to_int()))
	spec.zone_mode = RaceSpec.ZoneMode.FIXED
	return ""


static func _seed(spec: RaceSpec, value: String) -> String:
	if not value.is_valid_int():
		return "expected an integer"
	spec.seed_value = value.to_int()
	return ""
