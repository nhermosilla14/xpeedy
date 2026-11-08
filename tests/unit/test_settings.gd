extends TestCase

const PATH := "user://test_settings.cfg"
const STICK := "stick: normal"


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
	check_eq(menu.page_item_texts(), ["invert: off", "buttons: nintendo", STICK, "sound: on", "music: on", "vibration: on"] as Array[String])
	menu.activate()
	check_eq(menu.page_item_texts(), ["invert: on", "buttons: nintendo", STICK, "sound: on", "music: on", "vibration: on"] as Array[String])
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


func test_the_warning_shows_on_every_launch() -> void:
	_clean()
	var menu := MenuController.new()
	menu.settings = Settings.new(PATH)
	menu._ready()
	for launch in 2:
		menu.open(MenuController.Page.MAIN, true)
		check_eq(menu.current_page(), MenuController.Page.WARNING, "launch %d" % launch)
		check_eq(menu._info.title, "warning")
		var text := " ".join(menu._info.lines)
		check(text.contains("flashes") and text.contains("visual effects") and text.contains("sensitive"), "the warning text")
		menu._on_info_chosen(0)
		check_eq(menu.current_page(), MenuController.Page.MAIN)
	check(not FileAccess.file_exists(PATH), "accepting writes nothing")
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


func test_the_about_pages_show_the_version_and_the_credits() -> void:
	var menu := MenuController.new()
	menu.settings = Settings.new(PATH)
	menu._ready()
	menu.open(MenuController.Page.MAIN)
	check("about" in menu.page_item_texts(), "about item on the main menu")
	check(not ("credits" in menu.page_item_texts()), "credits moved into about")
	menu.move(3)
	menu.activate()
	check_eq(menu.current_page(), MenuController.Page.ABOUT)
	check_eq(menu._info.title, "about")
	var version: String = ProjectSettings.get_setting("application/config/version")
	check(version.count(".") == 2, "a proper version number: %s" % version)
	check(" ".join(menu._info.lines).contains("version " + version), "page 1 shows the version")
	check_eq(menu._info.choices, ["next"] as Array[String])
	menu._on_info_chosen(0)
	check_eq(menu._info.title, "about")
	var text := " ".join(menu._info.lines)
	check(text.contains("nicolas hermosilla") and text.contains("nhermosilla14"), "author and handle")
	check(text.contains("gamelion"), "acknowledges GameLion")
	check_eq(menu._info.choices, ["back"] as Array[String])
	menu._on_info_chosen(0)
	check_eq(menu.current_page(), MenuController.Page.MAIN)
	menu.free()
	_clean()


func test_the_stick_setting_defaults_by_platform_and_is_saved() -> void:
	_clean()
	var settings := Settings.new(PATH)
	check_eq(settings.stick_flipped, Settings.default_stick_flipped())
	settings.stick_flipped = not settings.stick_flipped
	settings.save()
	check_eq(Settings.new(PATH).stick_flipped, settings.stick_flipped)
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("[input]\nstick=\"sideways\"\n")
	file.close()
	check_eq(Settings.new(PATH).stick_flipped, Settings.default_stick_flipped(), "a bad value falls back")
	_clean()


func test_the_stick_flip_reverses_only_the_stick() -> void:
	check_near(SteerInput.stick_value(0.1, false), 0.0, 0.00001, "inside the dead zone")
	check_near(SteerInput.stick_value(-0.1, true), 0.0, 0.00001, "inside the dead zone, flipped")
	check_near(SteerInput.stick_value(1.0, false), 1.0, 0.00001, "full right")
	check_near(SteerInput.stick_value(-1.0, false), -1.0, 0.00001, "full left")
	check_near(SteerInput.stick_value(1.0, true), -1.0, 0.00001, "flipped, full right becomes left")
	check_near(SteerInput.stick_value(-0.6, true), 0.5, 0.00001, "flipped and scaled past the dead zone")
	check_near(SteerInput.stick_value(0.6, false), 0.5, 0.00001, "scaled past the dead zone")
