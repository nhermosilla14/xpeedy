class_name Hud
extends Control
## In-run HUD (ADR 0010): score at the bottom left, one slot per possible shield unit at the bottom
## right. Filled slots show the remaining decay time as their fill level. Sized by screen height / 320,
## as the original scaled its HUD (doc 17). Read-only: it never changes the model.

const REFERENCE_HEIGHT := 320.0
const SLOT_SIZE := Vector2(14.0, 22.0)
const SLOT_GAP := 4.0
const MARGIN := 8.0
const SHIELD_COLOUR := Color(1.0, 0.7, 0.2)

## What is currently shown (tests read these).
var shown_score := -1
var shown_shields := -1
var shown_slots := 0
var shown_fraction := 0.0

var _score_label := Label.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_score_label)
	resized.connect(_layout)
	_layout()


func update(run: SurvivalRun) -> void:
	var fraction := run.shields.fraction()
	if run.score != shown_score:
		shown_score = run.score
		_score_label.text = str(shown_score)
	if run.shields.count != shown_shields or run.shields.max_count != shown_slots \
			or not is_equal_approx(fraction, shown_fraction):
		shown_shields = run.shields.count
		shown_slots = run.shields.max_count
		shown_fraction = fraction
		queue_redraw()


func _scale() -> float:
	return maxf(size.y, 1.0) / REFERENCE_HEIGHT


func _layout() -> void:
	var s := _scale()
	_score_label.add_theme_font_size_override("font_size", int(18.0 * s))
	_score_label.position = Vector2(MARGIN * s, size.y - (MARGIN + 22.0) * s)
	queue_redraw()


func _draw() -> void:
	var s := _scale()
	var slot := SLOT_SIZE * s
	var total_width := shown_slots * slot.x + maxi(shown_slots - 1, 0) * SLOT_GAP * s
	var origin := Vector2(size.x - MARGIN * s - total_width, size.y - MARGIN * s - slot.y)
	for i in shown_slots:
		var rect := Rect2(origin + Vector2(i * (slot.x + SLOT_GAP * s), 0.0), slot)
		if i < shown_shields:
			var filled := rect
			filled.size.y = slot.y * maxf(shown_fraction, 0.15)
			filled.position.y = rect.end.y - filled.size.y
			draw_rect(filled, SHIELD_COLOUR)
		draw_rect(rect, Color(SHIELD_COLOUR, 0.8), false, maxf(1.0, 1.5 * s))
