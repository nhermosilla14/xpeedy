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
	check_eq(menu.page_item_texts(), ["invert: off", "buttons: nintendo"] as Array[String])
	menu.activate()
	check_eq(menu.page_item_texts(), ["invert: on", "buttons: nintendo"] as Array[String])
	check(Settings.new(PATH).invert, "saved")
	menu.back()
	check_eq(menu.current_page(), MenuController.Page.MAIN)
	menu.free()
	_clean()


func test_the_layout_is_saved_and_a_bad_value_falls_back() -> void:
	_clean()
	var settings := Settings.new(PATH)
	check_eq(settings.layout, "nintendo")
	settings.layout = "xbox"
	settings.save()
	check_eq(Settings.new(PATH).layout, "xbox")
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("[input]\nlayout=\"sega\"\n")
	file.close()
	check_eq(Settings.new(PATH).layout, "nintendo")
	_clean()


func test_the_settings_page_switches_the_button_layout() -> void:
	_clean()
	var menu := MenuController.new()
	menu.settings = Settings.new(PATH)
	menu._ready()
	menu.open(MenuController.Page.SETTINGS)
	menu.move(1)
	menu.activate()
	check_eq(menu.page_item_texts()[1], "buttons: xbox")
	check_eq(menu.selected_index(), 1, "the selection stays on the item")
	check_eq(InputLayout.face_button("ui_accept"), 1)
	menu.activate()
	check_eq(menu.page_item_texts()[1], "buttons: nintendo")
	check_eq(InputLayout.face_button("ui_accept"), 0)
	menu.free()
	_clean()


func test_input_layouts_swap_confirm_and_cancel_and_keep_select_as_back() -> void:
	InputLayout.apply("xbox")
	for action in ["ui_accept", "fire", "restart"]:
		check_eq(InputLayout.face_button(action), 1, action)
	check_eq(InputLayout.face_button("ui_cancel"), 0)
	InputLayout.apply("nintendo")
	for action in ["ui_accept", "fire", "restart"]:
		check_eq(InputLayout.face_button(action), 0, action)
	check_eq(InputLayout.face_button("ui_cancel"), 1)
	for layout in ["nintendo", "xbox"]:
		InputLayout.apply(layout)
		var has_select := false
		for event in InputMap.action_get_events("ui_cancel"):
			has_select = has_select or (event is InputEventJoypadButton and event.button_index == InputLayout.BACK_BUTTON)
		check(has_select, "Select cancels in %s" % layout)
	InputLayout.apply("nintendo")
	var starts := false
	for event in InputMap.action_get_events("restart"):
		starts = starts or (event is InputEventJoypadButton and event.button_index == 6)
	check(starts, "Start still restarts")


func test_the_back_arrow_is_reachable_with_the_gamepad() -> void:
	var screen := MenuScreen.new()
	var items: Array[Dictionary] = [{"text": "a"}, {"text": "b"}]
	screen.show_items(items, true, false)
	check_eq(screen.element_count(), 3)
	var backs := []
	screen.back_pressed.connect(func() -> void: backs.append(1))
	screen.move(-1)
	check(screen.is_back_selected(), "up from the first item reaches the back arrow")
	screen.activate()
	check_eq(backs.size(), 1)
	screen.show_items(items, true, true)
	check_eq(screen.element_count(), 4)
	screen.selected = 3
	check(screen.is_gear_selected() and not screen.is_back_selected(), "gear after back")
	screen.free()


func test_the_warning_shows_once_on_the_first_launch() -> void:
	_clean()
	var menu := MenuController.new()
	menu.settings = Settings.new(PATH)
	menu._ready()
	menu.open(MenuController.Page.MAIN, true)
	check_eq(menu.current_page(), MenuController.Page.WARNING)
	check_eq(menu._info.title, "warning")
	var text := " ".join(menu._info.lines)
	check(text.contains("flashes") and text.contains("visual effects") and text.contains("sensitive"), "the warning text")
	menu._on_info_chosen(0)
	check_eq(menu.current_page(), MenuController.Page.MAIN)
	check(Settings.new(PATH).warning_seen, "saved")
	menu.open(MenuController.Page.MAIN, true)
	check_eq(menu.current_page(), MenuController.Page.MAIN, "not shown again")
	menu.free()
	_clean()


func test_no_warning_unless_asked() -> void:
	_clean()
	var menu := MenuController.new()
	menu.settings = Settings.new(PATH)
	menu._ready()
	menu.open(MenuController.Page.MAIN)
	check_eq(menu.current_page(), MenuController.Page.MAIN)
	menu.free()
	_clean()


func test_the_credits_page_names_the_author_and_gamelion() -> void:
	var menu := MenuController.new()
	menu.settings = Settings.new(PATH)
	menu._ready()
	menu.open(MenuController.Page.MAIN)
	check("credits" in menu.page_item_texts(), "credits item on the main menu")
	menu.move(2)
	menu.activate()
	check_eq(menu.current_page(), MenuController.Page.CREDITS)
	var text := " ".join(menu._info.lines)
	check(text.contains("nicolas hermosilla") and text.contains("nhermosilla14"), "author and handle")
	check(text.contains("gamelion"), "acknowledges GameLion")
	menu.back()
	check_eq(menu.current_page(), MenuController.Page.MAIN)
	menu.free()
	_clean()
