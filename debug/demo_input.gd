class_name DemoInput
extends Node
## Simula input determinista: moverse en un ocho, girar la mira, disparar sin parar, rodar cada
## un rato, usar un Pulso y poner una bomba de vez en cuando. Sirve para capturas con Movie Maker y
## para corridas headless que ejerciten el gameplay.

const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]
const AIM_ACTIONS: Array[StringName] = [&"aim_left", &"aim_right", &"aim_up", &"aim_down"]
const TAP_ACTIONS: Array[StringName] = [&"dodge", &"blank", &"bomb"]
const DODGE_EVERY: float = 2.2
const BLANK_EVERY: float = 6.5
const BOMB_EVERY: float = 4.1

var _time: float = 0.0
var _next_dodge: float = DODGE_EVERY
var _next_blank: float = BLANK_EVERY
var _next_bomb: float = BOMB_EVERY


func _physics_process(delta: float) -> void:
	_time += delta
	_press_vector(MOVE_ACTIONS, Vector2(cos(_time * 1.3), sin(_time * 2.6)))
	_press_vector(AIM_ACTIONS, Vector2.from_angle(_time * 1.7))
	Input.action_press(&"shoot")
	# Rodar, Pulso y bomba son toques: se aprietan un tick y se sueltan en el siguiente.
	for action: StringName in TAP_ACTIONS:
		Input.action_release(action)
	if _time >= _next_dodge:
		_next_dodge += DODGE_EVERY
		Input.action_press(&"dodge")
	if _time >= _next_blank:
		_next_blank += BLANK_EVERY
		Input.action_press(&"blank")
	if _time >= _next_bomb:
		_next_bomb += BOMB_EVERY
		Input.action_press(&"bomb")


func _exit_tree() -> void:
	for action: StringName in MOVE_ACTIONS + AIM_ACTIONS + TAP_ACTIONS + [&"shoot"]:
		Input.action_release(action)


## Presiona las acciones [izq, der, arriba, abajo] con la fuerza que corresponde al vector.
func _press_vector(actions: Array[StringName], value: Vector2) -> void:
	_press_axis(actions[0], actions[1], value.x)
	_press_axis(actions[2], actions[3], value.y)


func _press_axis(negative: StringName, positive: StringName, value: float) -> void:
	if value < 0.0:
		Input.action_press(negative, -value)
		Input.action_release(positive)
	else:
		Input.action_press(positive, value)
		Input.action_release(negative)
