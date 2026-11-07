class_name ScreenPanel
extends Control
## The centred translucent panel of Pause and Game Over (ADR 0016): an amber title, small white
## lines and large choices. Choices react to mouse and touch; `chosen` carries the choice's index.

signal chosen(index: int)

const REFERENCE_HEIGHT := 320.0
const FILL := Color(0.169, 0.129, 0.376, 0.72)
const BORDER := Color(0.05, 0.04, 0.12, 0.9)
const TITLE_COLOUR := Color("E2A63A")
const CHOICE_COLOUR := Color("C4BFC4")
const PRESSED_COLOUR := Color("D8A64A")

var title := ""
var lines: Array[String] = []
var choices: Array[String] = []

var _labels: Array[Label] = []
var _pressed := -1
## The choice the keyboard or gamepad has selected (shown in amber).
var selected := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	resized.connect(_layout)


## Shows the panel with the given text.
func open(new_title: String, new_lines: Array[String], new_choices: Array[String]) -> void:
	title = new_title
	lines = new_lines
	choices = new_choices
	_pressed = -1
	selected = 0
	visible = true
	_layout()


## Moves the keyboard or gamepad selection by `step` choices (wraps).
func move_selection(step: int) -> void:
	if choices.is_empty():
		return
	selected = posmod(selected + step, choices.size())
	_layout()


func close() -> void:
	visible = false


func _scale() -> float:
	return maxf(size.y, 1.0) / REFERENCE_HEIGHT


func _rect() -> Rect2:
	var panel := Vector2(size.x * 0.72, size.y * 0.62)
	return Rect2((size - panel) * 0.5, panel)


func _choice_rect(index: int) -> Rect2:
	var rect := _rect()
	var s := _scale()
	# Below the middle, or below the last line when there are many (the warning and the credits).
	var top := rect.position.y + maxf(rect.size.y * 0.5 + 6.0 * s, (56.0 + 16.0 * lines.size() + 8.0) * s)
	var h := 30.0 * s
	return Rect2(rect.position.x, top + index * h, rect.size.x, h)


func _layout() -> void:
	for label in _labels:
		label.queue_free()
	_labels.clear()
	if not visible:
		return
	var rect := _rect()
	var s := _scale()
	_add(title, Rect2(rect.position.x, rect.position.y + 6.0 * s, rect.size.x, 46.0 * s), 36, TITLE_COLOUR)
	for i in lines.size():
		_add(lines[i], Rect2(rect.position.x, rect.position.y + (56.0 + 16.0 * i) * s, rect.size.x, 16.0 * s),
			11, Color("F1F1F4"))
	for i in choices.size():
		_add(choices[i], _choice_rect(i), 20, PRESSED_COLOUR if i == _pressed or (_pressed < 0 and i == selected) else CHOICE_COLOUR)
	queue_redraw()


func _add(text: String, rect: Rect2, font_size: int, colour: Color) -> void:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = rect.position
	label.size = rect.size
	UiFont.apply(label, int(font_size * _scale()), colour)
	add_child(label)
	_labels.append(label)


func _draw() -> void:
	if not visible:
		return
	var rect := _rect()
	draw_rect(rect, FILL)
	draw_rect(rect, BORDER, false, maxf(1.0, _scale()))


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var index := -1
	for i in choices.size():
		if _choice_rect(i).has_point(event.position):
			index = i
	if event.pressed:
		_pressed = index
		_layout()
	else:
		var released := _pressed
		_pressed = -1
		_layout()
		if released >= 0 and released == index:
			chosen.emit(index)
