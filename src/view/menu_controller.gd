class_name MenuController
extends Control
## The menu pages and the way between them (ADR 0018, 0025): main, mode, difficulty, stages, the restart
## question and settings. It reads the
## navigation actions when `poll` is called and only emits names; it knows nothing of the game.

signal play_requested(difficulty: String)
signal quit_requested
## The player pressed a menu item (for the click sound), and a setting changed (the owner applies it).
signal clicked
signal settings_changed
## A stage was chosen (it starts its next unfinished race), or its restart was confirmed.
signal race_requested(stage: int)
signal restart_stage_requested(stage: int)

enum Page { MAIN, DIFFICULTY, SETTINGS, MODE, STAGES, RESTART, UPGRADES, ABOUT, WARNING, HELP, HELP_TOPIC }

const WARNING_LINES: Array[String] = [
	"this game has flashes and",
	"visual effects that may be",
	"triggering for people who",
	"are sensitive to them.",
]
## The about pages (ADR 0033): the version and licence, then the credits.
static func about_pages() -> Array:
	var version: String = ProjectSettings.get_setting("application/config/version", "dev")
	return [
		["xpeedy", "version %s" % version, "a clone of speedx 3d", "free software, gpl-3.0"],
		["developed by", "nicolas hermosilla", "github: nhermosilla14", "original idea by the great",
			"developers at gamelion", "font: orbitron, sil ofl"],
	]

## The Quit item is hidden where programs do not quit (Android, web).
var can_quit := not (OS.has_feature("mobile") or OS.has_feature("web"))
## The difficulty that starts selected in the difficulty menu.
var preferred_difficulty := Difficulty.STANDARD
## The settings the Settings page edits; the owner sets it.
var settings := Settings.new()
## The stage progress the stage list shows (bars, padlocks); the owner sets it.
var progress := StageProgress.new()
## The credits and upgrade levels the shop shows and changes; the owner sets it.
var economy := Economy.new()

var _stack: Array[Page] = []
var _backdrop := MenuBackdrop.new()
var _screen := MenuScreen.new()
## The text pages (the warning and the credits).
var _info := ScreenPanel.new()
var _main_items: Array[String] = []
var _pending_stage := 0
var _help_topic := ""
var _help_page := 0
var _about_page := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in [_backdrop, _screen, _info]:
		child.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(child)
	_screen.activated.connect(_on_activated)
	_screen.back_pressed.connect(back)
	_screen.gear_pressed.connect(_open_settings)
	_info.chosen.connect(_on_info_chosen)


## Shows the page `page`, with the pages before it on the way back (difficulty and stages are reached from
## the mode page, which is reached from main).
## With `warning` the photosensitivity warning is shown first, once, if it was not accepted yet.
func open(page: Page, warning := false) -> void:
	_stack.clear()
	_stack.append(Page.MAIN)
	if page == Page.DIFFICULTY or page == Page.STAGES:
		_stack.append(Page.MODE)
	if page != Page.MAIN:
		_stack.append(page)
	if warning:
		_stack.append(Page.WARNING)
	_show_top()


## Opens the help list and then one topic at one page (for screenshots).
func show_help_topic(topic: String, page := 0) -> void:
	open(Page.HELP)
	_help_topic = topic
	_help_page = clampi(page, 0, HelpPages.pages(topic).size() - 1)
	_stack.append(Page.HELP_TOPIC)
	_show_top()


func current_page() -> Page:
	return _stack.back()


func page_item_texts() -> Array[String]:
	var texts: Array[String] = []
	for item in _screen.items:
		texts.append(item["text"])
	return texts


func selected_index() -> int:
	return _screen.selected


## Goes up one level; does nothing on the main page.
func back() -> void:
	if _stack.size() > 1:
		clicked.emit()
		_stack.pop_back()
		_show_top()


## Reads the navigation actions: up, down, accept and back.
func poll() -> void:
	if _is_info_page():
		if Input.is_action_just_pressed("ui_accept"):
			_on_info_chosen(0)
		elif Input.is_action_just_pressed("ui_cancel") and current_page() != Page.WARNING:
			back()
		return
	if Input.is_action_just_pressed("ui_down"):
		_screen.move(1)
	elif Input.is_action_just_pressed("ui_up"):
		_screen.move(-1)
	elif Input.is_action_just_pressed("ui_accept"):
		_screen.activate()
	elif Input.is_action_just_pressed("ui_cancel"):
		back()


func move(step: int) -> void:
	_screen.move(step)


func _is_info_page() -> bool:
	return _stack.back() in [Page.WARNING, Page.ABOUT, Page.HELP_TOPIC]


func _on_info_chosen(_index: int) -> void:
	if current_page() == Page.ABOUT and _about_page + 1 < about_pages().size():
		_about_page += 1
		clicked.emit()
		_show_top()
		return
	if current_page() == Page.HELP_TOPIC and _help_page + 1 < HelpPages.pages(_help_topic).size():
		_help_page += 1
		clicked.emit()
		_show_top()
		return
	back()


func activate() -> void:
	_screen.activate()


func _show_top(selected_item := 0) -> void:
	var items: Array[Dictionary] = []
	_screen.footer = ""
	_info.close()
	_screen.visible = not _is_info_page()
	match _stack.back():
		Page.WARNING:
			_info.open("warning", WARNING_LINES, ["i understand"] as Array[String])
			return
		Page.ABOUT:
			var about := about_pages()
			var about_lines: Array[String] = []
			about_lines.assign(about[_about_page])
			_info.open("about", about_lines,
				["back" if _about_page + 1 >= about.size() else "next"] as Array[String])
			return
		Page.HELP_TOPIC:
			var pages := HelpPages.pages(_help_topic)
			var lines: Array[String] = []
			lines.assign(pages[_help_page])
			var last := _help_page + 1 >= pages.size()
			_info.open("%s %d/%d" % [_help_topic, _help_page + 1, pages.size()], lines,
				["back" if last else "next"] as Array[String])
			return
		Page.HELP:
			for topic in HelpPages.topics():
				items.append({"text": topic})
			_screen.show_items(items, true, false, selected_item)
	match _stack.back():
		Page.MAIN:
			_main_items = ["play", "upgrades", "help", "about"]
			if can_quit:
				_main_items.append("quit")
			for text in _main_items:
				items.append({"text": text})
			_screen.show_items(items, false, true)
		Page.DIFFICULTY:
			for key in Difficulty.keys():
				items.append({"text": key, "colour": Difficulty.colour(key), "triangles": Difficulty.triangles(key)})
			_screen.show_items(items, true, false, Difficulty.keys().find(preferred_difficulty))
		Page.MODE:
			items.append({"text": "single"})
			items.append({"text": "survival"})
			_screen.show_items(items, true, false)
		Page.STAGES:
			for stage in range(1, StageProgress.STAGES + 1):
				items.append({"text": "stage %02d" % stage,
					"progress": float(progress.done(stage)) / StageProgress.RACES,
					"count": "%d/%d" % [progress.done(stage), StageProgress.RACES],
					"locked": not progress.is_unlocked(stage)})
			_screen.show_items(items, true, false, selected_item)
		Page.RESTART:
			items.append({"text": "restart stage %02d" % _pending_stage})
			items.append({"text": "keep it"})
			_screen.show_items(items, true, false, 1)
		Page.UPGRADES:
			for key in Upgrade.keys():
				var lvl := economy.level(key)
				items.append({"text": Upgrade.display_name(key), "progress": float(lvl) / Upgrade.levels(key),
					"count": ("%d cr" % economy.next_price(key)) if lvl < Upgrade.levels(key) else "max",
					"locked": lvl < Upgrade.levels(key) and not economy.next_unlocked(key)})
			_screen.show_items(items, true, false, selected_item)
			_screen.footer = "credits: %d" % economy.credits()
		Page.SETTINGS:
			items.append({"text": "invert: %s" % ("on" if settings.invert else "off")})
			items.append({"text": "buttons: %s" % settings.layout})
			items.append({"text": "stick: %s" % ("flipped" if settings.stick_flipped else "normal")})
			items.append({"text": "sound: %s" % _on_off(settings.sound)})
			items.append({"text": "music: %s" % _on_off(settings.music)})
			items.append({"text": "vibration: %s" % _on_off(settings.vibration)})
			_screen.show_items(items, true, false, selected_item)


func _open_settings() -> void:
	clicked.emit()
	_stack.append(Page.SETTINGS)
	_show_top()


static func _on_off(value: bool) -> String:
	return "on" if value else "off"


func _on_activated(index: int) -> void:
	clicked.emit()
	match _stack.back():
		Page.MAIN:
			if _main_items[index] == "play":
				_stack.append(Page.MODE)
				_show_top()
			elif _main_items[index] == "help":
				_stack.append(Page.HELP)
				_show_top()
			elif _main_items[index] == "about":
				_about_page = 0
				_stack.append(Page.ABOUT)
				_show_top()
			elif _main_items[index] == "upgrades":
				_stack.append(Page.UPGRADES)
				_show_top()
			else:
				quit_requested.emit()
		Page.MODE:
			_stack.append(Page.STAGES if index == 0 else Page.DIFFICULTY)
			_show_top()
		Page.DIFFICULTY:
			play_requested.emit(Difficulty.keys()[index])
		Page.STAGES:
			var stage := index + 1
			if not progress.is_unlocked(stage):
				return
			if progress.is_complete(stage):
				_pending_stage = stage
				_stack.append(Page.RESTART)
				_show_top()
			else:
				race_requested.emit(stage)
		Page.HELP:
			_help_topic = HelpPages.topics()[index]
			_help_page = 0
			_stack.append(Page.HELP_TOPIC)
			_show_top()
		Page.UPGRADES:
			economy.buy(Upgrade.keys()[index])
			_show_top(index)
		Page.RESTART:
			if index == 0:
				restart_stage_requested.emit(_pending_stage)
			else:
				back()
		Page.SETTINGS:
			match index:
				0:
					settings.invert = not settings.invert
				1:
					settings.layout = InputLayout.XBOX if settings.layout == InputLayout.NINTENDO else InputLayout.NINTENDO
					InputLayout.apply(settings.layout)
				2:
					settings.stick_flipped = not settings.stick_flipped
				3:
					settings.sound = not settings.sound
				4:
					settings.music = not settings.music
				_:
					settings.vibration = not settings.vibration
			settings.save()
			settings_changed.emit()
			_show_top(index)
