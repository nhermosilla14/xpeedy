class_name Hud
extends Control
## In-run HUD (ADR 0012): score at the bottom left, and one common shield bar at the bottom right: a
## frame split into one compartment per possible unit, with a single fill from the left that shrinks
## from the right as the shields decay (one compartment per decay period). Sized by screen height / 320,
## as the original scaled its HUD (doc 17). Read-only: it never changes the model.

const REFERENCE_HEIGHT := 320.0
const SEGMENT_SIZE := Vector2(16.0, 14.0)
const MARGIN := 8.0
## Glass panels flush with the bottom corners (ADR 0016), as fractions of the screen.
const PANEL_WIDTH := 0.24
const PANEL_HEIGHT := 0.14
const PANEL_FILL := Color(0.114, 0.102, 0.243, 0.9)
const PANEL_TOP := Color("C9C4D5")
const PANEL_LINE := Color(0.05, 0.04, 0.12, 0.9)
const BEST_SECONDS := 3.0
const BEST_FADE := 0.5
const SHIELD_COLOUR := Color(1.0, 0.7, 0.2)
## A drop of at least this many segments in one update is a loss (decay moves 0.05 per second).
const LOSS_MIN := 0.5
const LOSS_SECONDS := 0.25

## What is currently shown (tests read these).
var shown_score := -1
var shown_level := -1.0
var shown_slots := 0
## Seconds left of the fade-out of the part of the bar that was just lost, 0 when none.
var loss_left := 0.0
## The "best score" label: text shown (empty when none) and the seconds it stays before fading.
var best_text := ""
var best_left := 0.0

var _score_label := Label.new()
var _best_label := Label.new()
var _loss_from := 0.0
var _loss_to := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for label in [_score_label, _best_label]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best_label.modulate.a = 0.0
	resized.connect(_layout)
	_layout()


func update(run: SurvivalRun) -> void:
	var level := run.shields.level()
	if run.score != shown_score:
		shown_score = run.score
		_score_label.text = str(shown_score)
	if shown_level >= 0.0 and level < shown_level - LOSS_MIN:
		_loss_from = shown_level
		_loss_to = level
		loss_left = LOSS_SECONDS
	if run.shields.max_count != shown_slots or not is_equal_approx(level, shown_level):
		shown_slots = run.shields.max_count
		shown_level = level
		queue_redraw()


## Shows "best score: N" at the bottom centre for a few seconds, then fades it out. 0 shows nothing.
func show_best(score: int) -> void:
	best_text = "best score: %d" % score if score > 0 else ""
	best_left = BEST_SECONDS + BEST_FADE if score > 0 else 0.0
	_best_label.text = best_text
	_best_label.modulate.a = 1.0 if score > 0 else 0.0


func _process(delta: float) -> void:
	if best_left > 0.0:
		best_left = maxf(best_left - delta, 0.0)
		_best_label.modulate.a = clampf(best_left / BEST_FADE, 0.0, 1.0)
	if loss_left > 0.0:
		loss_left = maxf(loss_left - delta, 0.0)
		queue_redraw()


func _scale() -> float:
	return maxf(size.y, 1.0) / REFERENCE_HEIGHT


func _layout() -> void:
	var s := _scale()
	var panel := _panel_size()
	UiFont.apply(_score_label, int(22.0 * s))
	_score_label.position = Vector2(0.0, size.y - panel.y)
	_score_label.size = Vector2(panel.x - 10.0 * s, panel.y)
	_score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiFont.apply(_best_label, int(10.0 * s), Color("9A98A4"))
	_best_label.position = Vector2(size.x * 0.25, size.y - 22.0 * s)
	_best_label.size = Vector2(size.x * 0.5, 18.0 * s)
	queue_redraw()


func _panel_size() -> Vector2:
	return Vector2(size.x * PANEL_WIDTH, size.y * PANEL_HEIGHT)


func _draw_panel(rect: Rect2) -> void:
	var line := maxf(1.0, _scale())
	draw_rect(rect, PANEL_FILL)
	draw_rect(rect, PANEL_LINE, false, line)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, line * 1.5)), PANEL_TOP)


func _draw_pause_button() -> void:
	var s := _scale()
	var rect := Rect2(Vector2(size.x - (MARGIN + 22.0) * s, MARGIN * s), Vector2(22.0, 22.0) * s)
	draw_rect(rect, Color(0.114, 0.102, 0.243, 0.85))
	draw_rect(rect, PANEL_LINE, false, maxf(1.0, s))
	for k in 2:
		draw_rect(Rect2(rect.position + Vector2((6.0 + 6.0 * k) * s, 5.0 * s), Vector2(3.0, 12.0) * s),
			Color("F1F1F4"))


func _draw() -> void:
	var s := _scale()
	var panel := _panel_size()
	_draw_panel(Rect2(Vector2(0.0, size.y - panel.y), panel))
	_draw_panel(Rect2(Vector2(size.x - panel.x, size.y - panel.y), panel))
	_draw_pause_button()
	if shown_slots <= 0:
		return
	var bar := Vector2(minf(SEGMENT_SIZE.x * shown_slots * s, panel.x - 12.0 * s), SEGMENT_SIZE.y * s)
	var frame := Rect2(Vector2(size.x - panel.x + (panel.x - bar.x) * 0.5,
		size.y - panel.y + (panel.y - bar.y) * 0.5 + s), bar)
	draw_rect(frame, Color(0.0, 0.0, 0.0, 0.35))
	var fill := frame
	fill.size.x = bar.x * clampf(shown_level / shown_slots, 0.0, 1.0)
	draw_rect(fill, SHIELD_COLOUR)
	if loss_left > 0.0:
		_draw_loss(frame)
	var line := maxf(1.0, 1.5 * s)
	for k in range(1, shown_slots):
		var x := frame.position.x + bar.x * k / shown_slots
		draw_line(Vector2(x, frame.position.y), Vector2(x, frame.end.y), Color(0.0, 0.0, 0.0, 0.7), line)
	draw_rect(frame, Color(SHIELD_COLOUR, 0.9), false, line)


## The lost part of the bar grows slightly and fades out (ADR 0012).
func _draw_loss(frame: Rect2) -> void:
	var fade := loss_left / LOSS_SECONDS
	var from_x := frame.position.x + frame.size.x * _loss_to / shown_slots
	var to_x := frame.position.x + frame.size.x * _loss_from / shown_slots
	var lost := Rect2(from_x, frame.position.y, to_x - from_x, frame.size.y)
	lost = lost.grow(frame.size.y * 0.4 * (1.0 - fade))
	draw_rect(lost, Color(1.0, 0.95, 0.8, 0.9 * fade))
