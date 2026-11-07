class_name MenuBackdrop
extends Control
## The menu background (ADR 0018): near-black maroon with a few dark cubes with neon edges that rotate and
## drift slowly. Drawn in 2D from a handful of projected polygons; no assets.

const BACKGROUND := Color("190713")
const COLOURS := [Color("C8661E"), Color("1E9AA8"), Color("C8661E"), Color("8A3AA8"), Color("1E9AA8")]
const CUBE_COUNT := 5
const CORNERS := [Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(-1, 1, -1),
	Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1)]
const FACES := [[0, 1, 2, 3], [4, 5, 6, 7], [0, 1, 5, 4], [2, 3, 7, 6], [1, 2, 6, 5], [0, 3, 7, 4]]

var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if visible:
		_time += delta
		queue_redraw()


## Where cube `i` is (0-1 across and down the screen), its size (fraction of the height) and its spin.
func _cube(i: int) -> Dictionary:
	var speed := 0.012 + 0.006 * i
	var x := fposmod(0.2 + 0.23 * i + _time * speed, 1.3) - 0.15
	return {"x": x, "y": 0.2 + 0.14 * ((i * 7) % 5), "size": 0.05 + 0.025 * (i % 3),
		"a": _time * (0.15 + 0.05 * i) + i, "b": _time * (0.11 + 0.04 * i) + 2.0 * i}


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	for i in CUBE_COUNT:
		_draw_cube(_cube(i), COLOURS[i])


func _draw_cube(cube: Dictionary, colour: Color) -> void:
	var centre := Vector2(float(cube["x"]) * size.x, float(cube["y"]) * size.y)
	var scale: float = cube["size"] * size.y
	var projected: Array[Vector3] = []
	for corner in CORNERS:
		var p: Vector3 = corner.rotated(Vector3.UP, cube["a"]).rotated(Vector3.RIGHT, cube["b"])
		projected.append(Vector3(centre.x + p.x * scale, centre.y + p.y * scale, p.z))
	for face in FACES:
		var pts := PackedVector2Array()
		for k in face:
			pts.append(Vector2(projected[k].x, projected[k].y))
		var depth := 0.0
		for k in face:
			depth += projected[k].z
		if depth > 0.0:
			continue
		draw_colored_polygon(pts, colour * 0.18)
		pts.append(pts[0])
		draw_polyline(pts, Color(colour, 0.55), maxf(1.0, size.y / 320.0), true)
