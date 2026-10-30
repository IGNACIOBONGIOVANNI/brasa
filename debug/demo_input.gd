class_name DemoInput
extends Node
## Simula input determinista (moverse en un ocho, girar la mira y disparar sin parar).
## Sirve para capturas con Movie Maker y para corridas headless que ejerciten el gameplay.

const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]
const AIM_ACTIONS: Array[StringName] = [&"aim_left", &"aim_right", &"aim_up", &"aim_down"]

var _time: float = 0.0


func _physics_process(delta: float) -> void:
	_time += delta
	_press_vector(MOVE_ACTIONS, Vector2(cos(_time * 1.3), sin(_time * 2.6)))
	_press_vector(AIM_ACTIONS, Vector2.from_angle(_time * 1.7))
	Input.action_press(&"shoot")


func _exit_tree() -> void:
	for action: StringName in MOVE_ACTIONS + AIM_ACTIONS + [&"shoot"]:
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
