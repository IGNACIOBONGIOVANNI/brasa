class_name EnemyRecoverState
extends State
## Pausa después de atacar: la ventana para pegarle sin riesgo. Un movimiento de jefe pide la suya
## (Enemy.next_recover); si no, la de la fase.

var _time_left: float = 0.0

@onready var enemy: Enemy = owner as Enemy


func enter(_previous: StringName) -> void:
	_time_left = enemy.next_recover if enemy.next_recover >= 0.0 else enemy.behavior.recover_time
	enemy.next_recover = -1.0


func physics_update(delta: float) -> void:
	enemy.move_toward_velocity(Vector2.ZERO, delta)
	_time_left -= delta
	if _time_left <= 0.0:
		machine.transition_to(&"Move")
