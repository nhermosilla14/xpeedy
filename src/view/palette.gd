class_name Palette
extends RefCounted
## Obstacle colours (doc 15): amber, green, lime, teal, mauve. Shared by obstacles and trails.

const OBSTACLES: Array[Color] = [
	Color("FBAF02"), Color("38C36D"), Color("94C137"), Color("47B4B3"), Color("A95795"),
]


## The palette as a shader uniform array.
static func obstacle_vectors() -> PackedVector3Array:
	var result := PackedVector3Array()
	for c in OBSTACLES:
		result.append(Vector3(c.r, c.g, c.b))
	return result
