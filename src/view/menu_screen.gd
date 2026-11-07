class_name MenuScreen
extends Control
## One menu page (ADR 0018): a left-aligned stack of very large items in the interface typeface, with an
## optional back arrow (bottom-left) and gear (bottom-right). The selected or pressed item is amber. With
## a pointer an item highlights while pressed and activates on release (doc 14). The back arrow and the gear
## are the last elements of the navigation order (items, back, gear) so a gamepad can reach them.

signal activated(index: int)
signal gear_pressed
signal back_pressed

const ITEM_HEIGHT := 0.11
const TEXT_COLOUR := Color("C4BFC4")
const SELECTED_COLOUR := Color("D8A64A")
const BADGE_TRIANGLE := Color(0.1, 0.08, 0.1, 0.85)

## Each item: {"text": String} and optionally {"colour": Color, "triangles": int} for a round badge, or
## {"progress": float 0-1, "count": String, "locked": bool} for a stage: a progress bar and a padlock when locked.
var items: Array[Dictionary] = []
var has_back := false
var has_gear := false
## Index into the navigation order: the items, then the back arrow and the gear if there are any.
var selected := 0

var _pressed := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)


## Shows these items; the selection starts on `first`.
func show_items(new_items: Array[Dictionary], back: bool, gear: bool, first := 0) -> void:
	items = new_items
	has_back = back
	has_gear = gear
	selected = clampi(first, 0, element_count() - 1)
	_pressed = -1
	queue_redraw()


func element_count() -> int:
	return items.size() + (1 if has_back else 0) + (1 if has_gear else 0)


## Navigation index of the back arrow, or -1.
func back_index() -> int:
	return items.size() if has_back else -1


## Navigation index of the gear, or -1.
func gear_index() -> int:
	return items.size() + (1 if has_back else 0) if has_gear else -1


func is_gear_selected() -> bool:
	return has_gear and selected == gear_index()


func is_back_selected() -> bool:
	return has_back and selected == back_index()


## Moves the selection by `step` elements, wrapping.
func move(step: int) -> void:
	if element_count() == 0:
		return
	selected = posmod(selected + step, element_count())
	queue_redraw()


## Activates the selected element (what accept does).
func activate() -> void:
	if element_count() == 0:
		return
	if is_gear_selected():
		gear_pressed.emit()
	elif is_back_selected():
		back_pressed.emit()
	else:
		activated.emit(selected)


func _item_height() -> float:
	return size.y * ITEM_HEIGHT


func _left() -> float:
	return size.x * 0.1


func _item_rect(i: int) -> Rect2:
	var h := _item_height()
	return Rect2(0.0, h * 0.2 + i * h, size.x * 0.75, h)


func _back_rect() -> Rect2:
	var h := _item_height()
	return Rect2(size.x * 0.03, size.y - h * 1.5, h * 1.6, h * 1.4)


func _gear_rect() -> Rect2:
	var h := _item_height()
	return Rect2(size.x - h * 2.0, size.y - h * 2.0, h * 1.8, h * 1.8)


func _draw() -> void:
	var font := UiFont.get_font()
	var h := _item_height()
	var font_size := int(h * 0.72)
	for i in items.size():
		var rect := _item_rect(i)
		var colour := SELECTED_COLOUR if i == _pressed or (_pressed < 0 and i == selected) else TEXT_COLOUR
		if items[i].get("locked", false):
			colour = Color(colour, 0.45)
		var x := _left()
		if items[i].has("triangles"):
			_draw_badge(Vector2(x + h * 0.45, rect.position.y + h * 0.5), h * 0.42, items[i]["colour"], items[i]["triangles"])
			x += h * 1.05
		draw_string(font, Vector2(x, rect.position.y + h * 0.78), items[i]["text"],
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, colour)
	for i in items.size():
		if items[i].has("progress"):
			_draw_progress(i)
	if has_back:
		_draw_back(_back_rect(), SELECTED_COLOUR if is_back_selected() or _pressed == back_index() else TEXT_COLOUR)
	if has_gear:
		_draw_gear(_gear_rect(), SELECTED_COLOUR if is_gear_selected() or _pressed == gear_index() else TEXT_COLOUR)


## A stage's progress bar, its count and, when locked, a padlock (doc 11).
func _draw_progress(i: int) -> void:
	var h := _item_height()
	var rect := _item_rect(i)
	var bar := Rect2(size.x * 0.52, rect.position.y + h * 0.32, size.x * 0.24, h * 0.34)
	var locked: bool = items[i].get("locked", false)
	var tone := Color(TEXT_COLOUR, 0.45) if locked else TEXT_COLOUR
	draw_rect(bar, Color(1, 1, 1, 0.1))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * float(items[i]["progress"]), bar.size.y)), SELECTED_COLOUR if not locked else tone)
	draw_rect(bar, tone, false, maxf(1.0, size.y / 320.0))
	draw_string(UiFont.get_font(), Vector2(bar.end.x + h * 0.25, rect.position.y + h * 0.66), items[i].get("count", ""),
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(h * 0.36), tone)
	if locked:
		var c := Vector2(bar.end.x + h * 2.2, rect.position.y + h * 0.5)
		draw_rect(Rect2(c + Vector2(-h * 0.2, -h * 0.02), Vector2(h * 0.4, h * 0.3)), tone)
		draw_arc(c + Vector2(0.0, -h * 0.02), h * 0.14, PI, TAU, 12, tone, maxf(2.0, h * 0.06), true)


func _draw_badge(centre: Vector2, radius: float, colour: Color, triangles: int) -> void:
	draw_circle(centre, radius, colour)
	var rows: Array = [[1], [2], [1, 2], [2, 2], [2, 3]][clampi(triangles, 1, 5) - 1]
	var tri := radius * 0.6
	var row_h := tri * 0.92
	var top := centre.y - row_h * (rows.size() - 1) * 0.5
	for r in rows.size():
		for k in int(rows[r]):
			var cx: float = centre.x + (k - (int(rows[r]) - 1) * 0.5) * tri * 1.15
			var cy := top + r * row_h
			draw_colored_polygon(PackedVector2Array([Vector2(cx, cy - tri * 0.5),
				Vector2(cx + tri * 0.5, cy + tri * 0.45), Vector2(cx - tri * 0.5, cy + tri * 0.45)]), BADGE_TRIANGLE)


func _draw_back(rect: Rect2, colour: Color) -> void:
	var c := rect.get_center()
	var w := rect.size.x * 0.42
	var t := maxf(3.0, rect.size.y * 0.16)
	draw_polyline(PackedVector2Array([c + Vector2(-w * 0.2, -w), c + Vector2(-w, 0.0), c + Vector2(-w * 0.2, w)]),
		colour, t, true)
	draw_line(c + Vector2(-w, 0.0), c + Vector2(w, 0.0), colour, t, true)


func _draw_gear(rect: Rect2, colour: Color) -> void:
	var c := rect.get_center()
	var r := rect.size.x * 0.34
	var points := PackedVector2Array()
	for k in 32:
		var a := TAU * k / 32.0
		var rr := r * (1.3 if (k / 2) % 2 == 0 else 1.05)
		points.append(c + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(points, colour)
	draw_circle(c, r * 0.45, Color("190713"))


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var hit := -1
	for i in items.size():
		if _item_rect(i).has_point(event.position):
			hit = i
	if has_gear and _gear_rect().has_point(event.position):
		hit = gear_index()
	if has_back and _back_rect().has_point(event.position):
		hit = back_index()
	if event.pressed:
		_pressed = hit
		if hit >= 0:
			selected = hit
		queue_redraw()
		return
	var released := _pressed
	_pressed = -1
	queue_redraw()
	if released >= 0 and released == hit:
		selected = hit
		activate()
