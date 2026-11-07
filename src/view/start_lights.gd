class_name StartLights
extends Control
## The three start indicators at the top centre (ADR 0016, 0017): a ring around a disc of small dots.
## Each lights at its time, swells to 1.6x and fades out. Procedural, no image assets.

const REFERENCE_HEIGHT := 320.0
const RADIUS := 14.0
const SWELL := 1.6

## Per light: -1 not lit yet, 0-1 progress of the swell and fade (SurvivalRun.light_progress).
var progress: Array[float] = [-1.0, -1.0, -1.0]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func update(run: SurvivalRun) -> void:
	var changed := false
	for i in 3:
		var value := run.light_progress(i)
		if not is_equal_approx(value, progress[i]):
			progress[i] = value
			changed = true
	visible = run.phase == SurvivalRun.Phase.STARTING
	if changed:
		queue_redraw()


func _draw() -> void:
	var s := maxf(size.y, 1.0) / REFERENCE_HEIGHT
	for i in 3:
		var centre := Vector2(size.x * 0.5 + (i - 1) * 40.0 * s, 34.0 * s)
		var t := progress[i]
		if t < 0.0:
			_disc(centre, RADIUS * s, Color(1, 1, 1, 0.25))
		elif t < 1.0:
			_disc(centre, RADIUS * s * lerpf(1.0, SWELL, t), Color(1, 1, 1, 1.0 - t))


func _disc(centre: Vector2, radius: float, colour: Color) -> void:
	var line := maxf(1.0, radius * 0.12)
	draw_arc(centre, radius, 0.0, TAU, 32, colour, line, true)
	var step := radius * 0.28
	var rows := int(radius / step)
	for row in range(-rows, rows + 1):
		for col in range(-rows, rows + 1):
			var p := Vector2((col + 0.5 * (row & 1)) * step, row * step * 0.866)
			if p.length() < radius * 0.72:
				draw_circle(centre + p, step * 0.3, colour)
