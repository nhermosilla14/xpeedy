class_name InputLayout
extends RefCounted
## Gamepad button layout (ADR 0026): which of the two face buttons confirms and which cancels. "nintendo"
## is the layout the game always had (confirm on joypad button 0, cancel on button 1), "xbox" swaps them.
## The Select / Back button (joypad button 4) always cancels, whatever the layout.

const NINTENDO := "nintendo"
const XBOX := "xbox"
const CONFIRM_ACTIONS := ["ui_accept", "fire", "restart"]
const CANCEL_ACTIONS := ["ui_cancel"]
const BACK_BUTTON := 4


static func is_valid(layout: String) -> bool:
	return layout == NINTENDO or layout == XBOX


## Puts the face buttons on the actions for `layout` (an unknown name counts as "nintendo").
static func apply(layout: String) -> void:
	var confirm := 1 if layout == XBOX else 0
	for action in CONFIRM_ACTIONS:
		_set_face_button(action, confirm)
	for action in CANCEL_ACTIONS:
		_set_face_button(action, 1 - confirm)
		_ensure_button(action, BACK_BUTTON)


## The face button (0 or 1) an action has, or -1.
static func face_button(action: String) -> int:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and (event.button_index == 0 or event.button_index == 1):
			return event.button_index
	return -1


static func _set_face_button(action: String, index: int) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and (event.button_index == 0 or event.button_index == 1):
			InputMap.action_erase_event(action, event)
	_ensure_button(action, index)


static func _ensure_button(action: String, index: int) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == index:
			return
	var button := InputEventJoypadButton.new()
	button.button_index = index
	InputMap.action_add_event(action, button)
