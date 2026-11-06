class_name Hud
extends Control
## In-run HUD (ADR 0012): score at the bottom left, and one common shield bar at the bottom right: a
## frame split into one compartment per possible unit, with a single fill from the left that shrinks
## from the right as the shields decay (one compartment per decay period). Sized by screen height / 320,
## as the original scaled its HUD (doc 17). Read-only: it never changes the model.

const REFERENCE_HEIGHT := 320.0
const SEGMENT_SIZE := Vector2(22.0, 18.0)
const MARGIN := 8.0
const SHIELD_COLOUR := Color(1.0, 0.7, 0.2)

## What is currently shown (tests read these).
var shown_score := -1
var shown_level := -1.0
var shown_slots := 0

var _score_label := Label.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_score_label)
	resized.connect(_layout)
	_layout()


func update(run: SurvivalRun) -> void:
	var level := run.shields.level()
	if run.score != shown_score:
		shown_score = run.score
		_score_label.text = str(shown_score)
	if run.shields.max_count != shown_slots or not is_equal_approx(level, shown_level):
		shown_slots = run.shields.max_count
		shown_level = level
		queue_redraw()


func _scale() -> float:
	return maxf(size.y, 1.0) / REFERENCE_HEIGHT


func _layout() -> void:
	var s := _scale()
	_score_label.add_theme_font_size_override("font_size", int(18.0 * s))
	_score_label.position = Vector2(MARGIN * s, size.y - (MARGIN + 22.0) * s)
	queue_redraw()


func _draw() -> void:
	if shown_slots <= 0:
		return
	var s := _scale()
	var bar := Vector2(SEGMENT_SIZE.x * shown_slots, SEGMENT_SIZE.y) * s
	var frame := Rect2(Vector2(size.x - MARGIN * s - bar.x, size.y - MARGIN * s - bar.y), bar)
	draw_rect(frame, Color(0.0, 0.0, 0.0, 0.35))
	var fill := frame
	fill.size.x = bar.x * clampf(shown_level / shown_slots, 0.0, 1.0)
	draw_rect(fill, SHIELD_COLOUR)
	var line := maxf(1.0, 1.5 * s)
	for k in range(1, shown_slots):
		var x := frame.position.x + bar.x * k / shown_slots
		draw_line(Vector2(x, frame.position.y), Vector2(x, frame.end.y), Color(0.0, 0.0, 0.0, 0.7), line)
	draw_rect(frame, Color(SHIELD_COLOUR, 0.9), false, line)
