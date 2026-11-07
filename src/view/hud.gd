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

signal pause_pressed
signal fire_pressed
## One of the upgrade buttons on the left edge was pressed: "recharge", "torpedo" or "phase".
signal upgrade_pressed(kind: String)
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
## The held bonus (`SurvivalRun.Bonus`) the ring shows, and the time driving its pulse.
var shown_held := 0
## The upgrade buttons shown (ADR 0029): which are usable, the torpedoes left and the reload dial (0-1).
var shown_recharge := false
var shown_torpedo := false
var shown_phase := false
var torpedo_count := 0
var torpedo_dial := 1.0
var _pulse := 0.0
## The "best score" label: text shown (empty when none) and the seconds it stays before fading.
var best_text := ""
var best_left := 0.0

var _score_label := Label.new()
var _best_label := Label.new()
var _loss_from := 0.0
var _loss_to := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	for label in [_score_label, _best_label]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best_label.modulate.a = 0.0
	resized.connect(_layout)
	_layout()


func update(run: SurvivalRun) -> void:
	var recharge := run.can_recharge()
	var torpedo := run.config.torpedo_level > 0 and run.torpedoes_left > 0 and not run.track.crashed and not run.finished
	var phase := run.can_phase()
	var dial := run.torpedo_reload_fraction() if run.torpedoes_left > 0 else 1.0
	if recharge != shown_recharge or torpedo != shown_torpedo or phase != shown_phase \
			or run.torpedoes_left != torpedo_count or absf(dial - torpedo_dial) > 0.01:
		shown_recharge = recharge
		shown_torpedo = torpedo
		shown_phase = phase
		torpedo_count = run.torpedoes_left
		torpedo_dial = dial
		queue_redraw()
	if run.held != shown_held:
		shown_held = run.held
		queue_redraw()
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
	if shown_held != 0:
		_pulse += delta
		queue_redraw()
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


func _pause_rect() -> Rect2:
	var s := _scale()
	return Rect2(Vector2(size.x - (MARGIN + 22.0) * s, MARGIN * s), Vector2(22.0, 22.0) * s)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _pause_rect().grow(8.0 * _scale()).has_point(event.position):
			pause_pressed.emit()
			return
		var buttons := _upgrade_buttons()
		for kind in buttons:
			if buttons[kind].has_point(event.position):
				upgrade_pressed.emit(kind)
				return
		fire_pressed.emit()


## Bonus colours (doc 06): Quake red, Time Dilation blue, Space Fold green.
const BONUS_COLOURS := [Color.WHITE, Color(0.9, 0.1, 0.3), Color(0.3, 0.5, 1.0), Color(0.5, 0.8, 0.1)]


## The upgrade buttons on the left edge, stacked from the top below the held-bonus ring, only the usable ones.
func _upgrade_buttons() -> Dictionary:
	var s := _scale()
	var result := {}
	var y := (MARGIN + 34.0) * s
	for kind in ["recharge", "torpedo", "phase"]:
		var shown := shown_recharge if kind == "recharge" else (shown_torpedo if kind == "torpedo" else shown_phase)
		if shown:
			result[kind] = Rect2(Vector2(MARGIN * s, y), Vector2(26.0, 26.0) * s)
			y += 30.0 * s
	return result


func _draw_upgrade_buttons(s: float) -> void:
	var buttons := _upgrade_buttons()
	var font := UiFont.get_font()
	for kind in buttons:
		var rect: Rect2 = buttons[kind]
		draw_rect(rect, Color(0.114, 0.102, 0.243, 0.85))
		draw_rect(rect, PANEL_LINE, false, maxf(1.0, s))
		var label: String = {"recharge": "+", "torpedo": "t", "phase": "p"}[kind]
		draw_string(font, rect.position + Vector2(0.0, rect.size.y * 0.72), label, HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x, int(rect.size.y * 0.7), Color("F1F1F4"))
		if kind == "torpedo":
			draw_string(font, rect.position + Vector2(rect.size.x * 0.62, rect.size.y * 0.98), str(torpedo_count),
				HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(rect.size.y * 0.38), SHIELD_COLOUR)
			if torpedo_dial < 1.0:
				draw_arc(rect.get_center(), rect.size.x * 0.46, -PI / 2.0, -PI / 2.0 + TAU * torpedo_dial, 24,
					Color(0.6, 0.9, 1.0), maxf(2.0, 2.0 * s), true)


func _draw_held_ring(s: float) -> void:
	var colour: Color = BONUS_COLOURS[shown_held]
	var pulse := 0.5 + 0.5 * sin(_pulse * 6.0)
	var centre := Vector2((MARGIN + 14.0) * s, (MARGIN + 14.0) * s)
	draw_arc(centre, (11.0 + 2.0 * pulse) * s, 0.0, TAU, 32, Color(colour, 0.6 + 0.4 * pulse), 3.0 * s, true)
	draw_circle(centre, 6.0 * s, Color(colour, 0.35 + 0.3 * pulse))


func _draw_pause_button() -> void:
	var s := _scale()
	var rect := _pause_rect()
	draw_rect(rect, Color(0.114, 0.102, 0.243, 0.85))
	draw_rect(rect, PANEL_LINE, false, maxf(1.0, s))
	for k in 2:
		draw_rect(Rect2(rect.position + Vector2((6.0 + 6.0 * k) * s, 5.0 * s), Vector2(3.0, 12.0) * s),
			Color("F1F1F4"))


func _draw() -> void:
	var s := _scale()
	var panel := _panel_size()
	if shown_held != 0:
		_draw_held_ring(s)
	_draw_upgrade_buttons(s)
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
