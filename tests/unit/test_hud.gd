extends TestCase


func test_the_font_is_orbitron_black() -> void:
	var font := UiFont.get_font()
	check_eq(font.variation_opentype.values()[0], 900.0)
	check(font.base_font != null, "base font loaded")


func test_the_best_score_label_shows_then_fades() -> void:
	var hud := Hud.new()
	hud.size = Vector2(480, 320)
	hud._ready()
	hud.show_best(1204)
	check_eq(hud.best_text, "best score: 1204")
	hud._process(Hud.BEST_SECONDS)
	check_near(hud._best_label.modulate.a, 1.0, 0.0001, "still shown")
	hud._process(Hud.BEST_FADE)
	check_near(hud._best_label.modulate.a, 0.0, 0.0001, "faded")
	hud.show_best(0)
	check_eq(hud.best_text, "")
	hud.free()


func test_the_fps_option() -> void:
	check(LaunchOptions.parse(PackedStringArray(["--fps"])).fps, "fps on")
	check(not LaunchOptions.parse(PackedStringArray([])).fps, "fps off by default")
