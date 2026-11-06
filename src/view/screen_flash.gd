class_name ScreenFlash
extends ColorRect
## Full-screen flash that fades out linearly (doc 15; ADR 0010). An additive flash brightens the scene.
## A new flash replaces the current one.

var _alpha := 0.0
var _duration := 0.0
var _left := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	self.material = material
	color = Color(0.0, 0.0, 0.0, 0.0)


func flash(flash_colour: Color, alpha: float, duration: float) -> void:
	_alpha = alpha
	_duration = duration
	_left = duration
	color = Color(flash_colour, alpha)


## Current opacity, 0 when no flash is showing.
func current_alpha() -> float:
	return color.a


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left = maxf(_left - delta, 0.0)
	color.a = _alpha * _left / _duration
