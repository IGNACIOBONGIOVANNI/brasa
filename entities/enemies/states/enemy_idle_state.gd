class_name EnemyIdleState
extends State
## Aparición: el enemigo se materializa durante data.spawn_delay sin moverse ni hacer daño por
## contacto, así nunca ataca apenas aparece. Un jefe que hace su entrada (BossIntro) espera a que
## termine y ataca poco después.

## Lo que espera un jefe después de su entrada.
const AFTER_INTRO: float = 0.5

var _time_left: float = 0.0

@onready var enemy: Enemy = owner as Enemy


func enter(_previous: StringName) -> void:
	_time_left = enemy.data.spawn_delay
	enemy.hitbox.active = false
	if not enemy.in_intro():
		enemy.visual.play_spawn(enemy.data.spawn_delay)


func exit() -> void:
	enemy.hitbox.active = true


func physics_update(delta: float) -> void:
	if enemy.in_intro():
		_time_left = AFTER_INTRO
		return
	enemy.move_toward_velocity(Vector2.ZERO, delta)
	_time_left -= delta
	if _time_left <= 0.0:
		machine.transition_to(&"Move")
