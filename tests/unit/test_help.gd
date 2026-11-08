extends TestCase


func test_the_topics_in_order() -> void:
	check_eq(HelpPages.topics(), ["controls", "obstacles", "shields", "bonuses", "zones", "upgrades", "modes"] as Array[String])
	check_eq(HelpPages.pages("nope").size(), 0)


func test_every_page_fits_the_panel() -> void:
	for topic in HelpPages.topics():
		check(HelpPages.pages(topic).size() >= 1, "%s has pages" % topic)
		for page in HelpPages.pages(topic):
			check(page.size() >= 1 and page.size() <= HelpPages.MAX_LINES, "%s: %d lines" % [topic, page.size()])
			for line in page:
				check(line.length() <= HelpPages.MAX_WIDTH, "'%s' is %d characters" % [line, line.length()])
				check_eq(line, line.to_lower(), "lowercase: " + line)


func test_the_pages_name_every_obstacle_bonus_zone_and_upgrade() -> void:
	var text := ""
	for topic in HelpPages.topics():
		for page in HelpPages.pages(topic):
			text += " ".join(page) + " "
	for word in ["cube", "beam", "spike", "roller", "bouncer", "quake", "time dilation", "space fold", "blackout",
			"gravity well", "hue shift", "dark nebula", "plasma cloud", "recharger", "torpedo", "phase shift",
			"flow", "fractal", "modulator", "survival", "keep going"]:
		check(text.contains(word), "the help mentions %s" % word)
	for key in Upgrade.keys():
		check(text.contains(Upgrade.display_name(key)), "upgrade %s" % key)


func _menu() -> MenuController:
	var menu := MenuController.new()
	menu.settings = Settings.new("user://test_help_settings.cfg")
	menu._ready()
	return menu


func test_the_main_menu_opens_the_help_list_and_the_topic_pages() -> void:
	var menu := _menu()
	menu.open(MenuController.Page.MAIN)
	check("help" in menu.page_item_texts(), "help item")
	menu.move(2)
	menu.activate()
	check_eq(menu.current_page(), MenuController.Page.HELP)
	check_eq(menu.page_item_texts(), HelpPages.topics())
	menu.move(1)
	menu.activate()
	check_eq(menu.current_page(), MenuController.Page.HELP_TOPIC)
	check_eq(menu._info.title, "obstacles 1/3")
	check_eq(menu._info.choices, ["next"] as Array[String])
	menu._on_info_chosen(0)
	check_eq(menu._info.title, "obstacles 2/3")
	menu._on_info_chosen(0)
	check_eq(menu._info.title, "obstacles 3/3")
	check_eq(menu._info.choices, ["back"] as Array[String])
	menu._on_info_chosen(0)
	check_eq(menu.current_page(), MenuController.Page.HELP, "back on the last page returns to the list")
	menu.back()
	check_eq(menu.current_page(), MenuController.Page.MAIN)
	menu.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_help_settings.cfg"))


func test_a_topic_with_one_page_goes_straight_back() -> void:
	var menu := _menu()
	menu.open(MenuController.Page.HELP)
	menu.move(2)
	menu.activate()
	check_eq(menu._info.title, "shields 1/1")
	check_eq(menu._info.choices, ["back"] as Array[String])
	menu.back()
	check_eq(menu.current_page(), MenuController.Page.HELP)
	menu.free()
