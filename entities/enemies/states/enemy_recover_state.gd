class_name EnemyRecoverState
extends State
## Pausa después de atacar: la ventana para pegarle sin riesgo.

var _time_left: float = 0.0

@onready var enemy: Enemy = owner as Enemy


func enter(_previous: StringName) -> void:
	_time_left = enemy.behavior.recover_time


func physics_update(delta: float) -> void:
	enemy.move_toward_velocity(Vector2.ZERO, delta)
	_time_left -= delta
	if _time_left <= 0.0:
		machine.transition_to(&"Move")
