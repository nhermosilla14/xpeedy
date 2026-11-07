class_name MenuController
extends Control
## The menu pages and the way between them (ADR 0018): main, difficulty and, later, settings. It reads the
## navigation actions when `poll` is called and only emits names; it knows nothing of the game.

signal play_requested(difficulty: String)
signal quit_requested

enum Page { MAIN, DIFFICULTY, SETTINGS }

## The Quit item is hidden where programs do not quit (Android, web).
var can_quit := not (OS.has_feature("mobile") or OS.has_feature("web"))
## The difficulty that starts selected in the difficulty menu.
var preferred_difficulty := Difficulty.STANDARD
## The settings the Settings page edits; the owner sets it.
var settings := Settings.new()

var _stack: Array[Page] = []
var _backdrop := MenuBackdrop.new()
var _screen := MenuScreen.new()
var _main_items: Array[String] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in [_backdrop, _screen]:
		child.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(child)
	_screen.activated.connect(_on_activated)
	_screen.back_pressed.connect(back)
	_screen.gear_pressed.connect(_open_settings)


## Shows the page `page`, with the pages before it on the way back (difficulty is reached from main).
func open(page: Page) -> void:
	_stack.clear()
	_stack.append(Page.MAIN)
	if page != Page.MAIN:
		_stack.append(page)
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
		_stack.pop_back()
		_show_top()


## Reads the navigation actions: up, down, accept and back.
func poll() -> void:
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


func activate() -> void:
	_screen.activate()


func _show_top() -> void:
	var items: Array[Dictionary] = []
	match _stack.back():
		Page.MAIN:
			_main_items = ["play"]
			if can_quit:
				_main_items.append("quit")
			for text in _main_items:
				items.append({"text": text})
			_screen.show_items(items, false, true)
		Page.DIFFICULTY:
			for key in Difficulty.keys():
				items.append({"text": key, "colour": Difficulty.colour(key), "triangles": Difficulty.triangles(key)})
			_screen.show_items(items, true, false, Difficulty.keys().find(preferred_difficulty))
		Page.SETTINGS:
			items.append({"text": "invert: %s" % ("on" if settings.invert else "off")})
			_screen.show_items(items, true, false)


func _open_settings() -> void:
	_stack.append(Page.SETTINGS)
	_show_top()


func _on_activated(index: int) -> void:
	match _stack.back():
		Page.MAIN:
			if _main_items[index] == "play":
				_stack.append(Page.DIFFICULTY)
				_show_top()
			else:
				quit_requested.emit()
		Page.DIFFICULTY:
			play_requested.emit(Difficulty.keys()[index])
		Page.SETTINGS:
			settings.invert = not settings.invert
			settings.save()
			_show_top()
