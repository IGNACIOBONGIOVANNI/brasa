class_name EnemyMoveState
extends State
## Se mueve según data.move_style y, cuando pasó el cooldown y el jugador está a tiro, pasa a
## Telegraph (el aviso) antes de atacar.

## Margen alrededor de preferred_distance donde se mueve de costado en vez de acercarse o alejarse.
const DISTANCE_MARGIN: float = 14.0
const STRAFE_FACTOR: float = 0.6

var _cooldown: float = 0.0
var _strafe_sign: float = 1.0

@onready var enemy: Enemy = owner as Enemy


func enter(previous: StringName) -> void:
	# Recién aparecido ataca antes; después de un ataque espera el cooldown completo.
	_cooldown = enemy.roll_attack_cooldown(0.5 if previous == &"Idle" else 1.0)
	_strafe_sign = 1.0 if GameRNG.stream(RngStreams.COMBAT).randf() < 0.5 else -1.0


func physics_update(delta: float) -> void:
	if not enemy.has_target():
		enemy.move_toward_velocity(Vector2.ZERO, delta)
		return
	var offset: Vector2 = enemy.to_target()
	enemy.move_toward_velocity(_desired_direction(offset) * enemy.behavior.move_speed, delta)
	enemy.look_at_target()
	_cooldown -= delta
	if _cooldown <= 0.0 and offset.length() <= enemy.behavior.attack_range:
		machine.transition_to(&"Telegraph")


func _desired_direction(offset: Vector2) -> Vector2:
	var toward: Vector2 = offset.normalized()
	if enemy.behavior.move_style == EnemyData.MoveStyle.CHASE:
		return toward
	var distance: float = offset.length()
	if distance > enemy.behavior.preferred_distance + DISTANCE_MARGIN:
		return toward
	if distance < enemy.behavior.preferred_distance - DISTANCE_MARGIN:
		return -toward
	return toward.orthogonal() * _strafe_sign * STRAFE_FACTOR
