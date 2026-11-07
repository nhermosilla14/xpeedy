class_name UiFont
## The interface typeface (ADR 0016): Orbitron at its Black weight, SIL OFL (assets/fonts/OFL.txt).

const FONT := preload("res://assets/fonts/Orbitron.ttf")

static var _cached: FontVariation


static func get_font() -> FontVariation:
	if _cached == null:
		_cached = FontVariation.new()
		_cached.base_font = FONT
		_cached.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 900.0}
	return _cached


static func apply(label: Label, size: int, colour := Color("F1F1F4")) -> void:
	label.add_theme_font_override("font", get_font())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
