extends TestCase

const PATH := "user://test_settings.cfg"


func _clean() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_defaults_without_a_file() -> void:
	_clean()
	check(not Settings.new(PATH).invert, "invert off by default")


func test_settings_are_saved_and_loaded() -> void:
	_clean()
	var settings := Settings.new(PATH)
	settings.invert = true
	settings.save()
	check(Settings.new(PATH).invert, "invert survives")
	_clean()


func test_a_corrupt_or_wrongly_typed_file_gives_the_defaults() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("[steering]\ninvert=\"maybe\"\n")
	file.close()
	check(not Settings.new(PATH).invert, "wrong type")
	file = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("not [a config")
	file.close()
	check(not Settings.new(PATH).invert, "corrupt")
	_clean()


func test_the_settings_page_toggles_and_saves() -> void:
	_clean()
	var menu := MenuController.new()
	menu.settings = Settings.new(PATH)
	menu._ready()
	menu.open(MenuController.Page.SETTINGS)
	check_eq(menu.page_item_texts(), ["invert: off"] as Array[String])
	menu.activate()
	check_eq(menu.page_item_texts(), ["invert: on"] as Array[String])
	check(Settings.new(PATH).invert, "saved")
	menu.back()
	check_eq(menu.current_page(), MenuController.Page.MAIN)
	menu.free()
	_clean()
