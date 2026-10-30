extends SceneTree
## Escribe el Input Map por defecto en project.godot. Es la fuente de verdad de los controles:
## para cambiar un binding, editarlo acá y volver a correrlo (pisa solo las acciones de esta lista).
## Uso: <godot_console> --headless --path . -s res://tools/setup_input_map.gd

const MOVE_DEADZONE: float = 0.2
const AIM_DEADZONE: float = 0.3
const DEFAULT_DEADZONE: float = 0.5


func _initialize() -> void:
	_action(&"move_left", [_key(KEY_A), _axis(JOY_AXIS_LEFT_X, -1.0), _button(JOY_BUTTON_DPAD_LEFT)], MOVE_DEADZONE)
	_action(&"move_right", [_key(KEY_D), _axis(JOY_AXIS_LEFT_X, 1.0), _button(JOY_BUTTON_DPAD_RIGHT)], MOVE_DEADZONE)
	_action(&"move_up", [_key(KEY_W), _axis(JOY_AXIS_LEFT_Y, -1.0), _button(JOY_BUTTON_DPAD_UP)], MOVE_DEADZONE)
	_action(&"move_down", [_key(KEY_S), _axis(JOY_AXIS_LEFT_Y, 1.0), _button(JOY_BUTTON_DPAD_DOWN)], MOVE_DEADZONE)

	_action(&"aim_left", [_axis(JOY_AXIS_RIGHT_X, -1.0)], AIM_DEADZONE)
	_action(&"aim_right", [_axis(JOY_AXIS_RIGHT_X, 1.0)], AIM_DEADZONE)
	_action(&"aim_up", [_axis(JOY_AXIS_RIGHT_Y, -1.0)], AIM_DEADZONE)
	_action(&"aim_down", [_axis(JOY_AXIS_RIGHT_Y, 1.0)], AIM_DEADZONE)

	_action(&"shoot", [_mouse(MOUSE_BUTTON_LEFT), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_action(&"dodge", [_key(KEY_SPACE), _mouse(MOUSE_BUTTON_RIGHT), _button(JOY_BUTTON_A), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_action(&"use_active", [_key(KEY_Q), _button(JOY_BUTTON_RIGHT_SHOULDER)])
	_action(&"bomb", [_key(KEY_E), _button(JOY_BUTTON_X)])
	_action(&"blank", [_key(KEY_F), _button(JOY_BUTTON_Y)])
	_action(&"reload", [_key(KEY_R), _button(JOY_BUTTON_B)])
	_action(&"swap_weapon", [_key(KEY_TAB), _mouse(MOUSE_BUTTON_WHEEL_UP), _mouse(MOUSE_BUTTON_WHEEL_DOWN), _button(JOY_BUTTON_LEFT_SHOULDER)])
	_action(&"pause", [_key(KEY_ESCAPE), _button(JOY_BUTTON_START)])

	_action(&"debug_overlay", [_key(KEY_F1)])
	_action(&"debug_hitboxes", [_key(KEY_F2)])
	_action(&"debug_menu", [_key(KEY_F3)])

	var err: Error = ProjectSettings.save()
	print("setup_input_map: %s" % error_string(err))
	quit(0 if err == OK else 1)


func _action(action_name: StringName, events: Array, deadzone: float = DEFAULT_DEADZONE) -> void:
	ProjectSettings.set_setting("input/" + action_name, {"deadzone": deadzone, "events": events})


func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.device = -1
	event.physical_keycode = code
	return event


func _mouse(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.device = -1
	event.button_index = button
	return event


func _button(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = -1
	event.button_index = button
	return event


func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = -1
	event.axis = axis
	event.axis_value = value
	return event
