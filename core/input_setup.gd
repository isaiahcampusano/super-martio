class_name InputSetup
extends RefCounted


static func ensure_default_actions() -> void:
	_add_action(&"move_left", [_key(KEY_A), _key(KEY_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)])
	_add_action(&"move_right", [_key(KEY_D), _key(KEY_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)])
	_add_action(&"jump", [_key(KEY_SPACE), _key(KEY_W), _key(KEY_UP), _joy_button(JOY_BUTTON_A)])
	_add_action(&"sprint", [_key(KEY_SHIFT), _key(KEY_Z), _joy_button(JOY_BUTTON_X)])
	_add_action(&"crouch", [_key(KEY_S), _key(KEY_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)])
	_add_action(&"pause", [_key(KEY_ESCAPE), _joy_button(JOY_BUTTON_START)])


static func _add_action(action: StringName, events: Array[InputEvent]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	if not InputMap.action_get_events(action).is_empty():
		return
	for event in events:
		InputMap.action_add_event(action, event)


static func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	return event


static func _joy_button(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	return event


static func _joy_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event

