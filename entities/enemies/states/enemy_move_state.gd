class_name EnemyMoveState
extends State
## Se mueve según behavior.move_style y, cuando pasó el cooldown y el jugador está a tiro, pasa a
## Telegraph (el aviso) antes de atacar. CHASE persigue, KEEP_DISTANCE mantiene la distancia, HOP
## avanza a saltos, FLY vuela en círculos alrededor del jugador, STAY no se mueve, BURROW persigue bajo
## tierra (asoma recién al atacar) y PHASE persigue alternando entre sólido y fantasma (solo ataca
## sólido).

## Margen alrededor de preferred_distance donde se mueve de costado en vez de acercarse o alejarse.
const DISTANCE_MARGIN: float = 14.0
const STRAFE_FACTOR: float = 0.6
## HOP: velocidad del salto en veces move_speed (después frena con su aceleración).
const HOP_BURST: float = 3.2
## FLY: radianes por segundo que gira alrededor del jugador y cuánto se bambolea.
const ORBIT_SPEED: float = 1.3
const FLUTTER: float = 0.5
const FLUTTER_SPEED: float = 7.0

var _cooldown: float = 0.0
var _strafe_sign: float = 1.0
var _hop_left: float = 0.0
var _orbit_angle: float = 0.0
var _phase_left: float = 0.0
var _time: float = 0.0

@onready var enemy: Enemy = owner as Enemy


func enter(previous: StringName) -> void:
	var rng: RandomNumberGenerator = GameRNG.stream(RngStreams.COMBAT)
	# Recién aparecido ataca antes; después de un ataque espera el cooldown completo.
	_cooldown = enemy.roll_attack_cooldown(0.5 if previous == &"Idle" else 1.0)
	_strafe_sign = 1.0 if rng.randf() < 0.5 else -1.0
	_hop_left = rng.randf_range(0.1, enemy.behavior.hop_interval)
	if enemy.has_target():
		_orbit_angle = (-enemy.to_target()).angle()
	match enemy.behavior.move_style:
		EnemyData.MoveStyle.BURROW:
			enemy.set_hidden(true)
			AudioManager.play_sfx(&"burrow", 0.1)
		EnemyData.MoveStyle.PHASE:
			enemy.set_hidden(true)
			_phase_left = enemy.behavior.ghost_time


func exit() -> void:
	# Fantasma solo mientras camina: el aviso y el ataque son siempre sólidos.
	if enemy.behavior.move_style == EnemyData.MoveStyle.PHASE:
		enemy.set_hidden(false)


func physics_update(delta: float) -> void:
	_time += delta
	if not enemy.has_target():
		enemy.move_toward_velocity(Vector2.ZERO, delta)
		return
	var offset: Vector2 = enemy.to_target()
	match enemy.behavior.move_style:
		EnemyData.MoveStyle.HOP:
			_hop(offset, delta)
		EnemyData.MoveStyle.FLY:
			_fly(delta)
		EnemyData.MoveStyle.STAY:
			enemy.move_toward_velocity(Vector2.ZERO, delta)
		_:
			enemy.move_toward_velocity(_desired_direction(offset) * enemy.behavior.move_speed, delta)
	enemy.look_at_target()
	if enemy.behavior.move_style == EnemyData.MoveStyle.PHASE:
		_update_phase(delta)
	_cooldown -= delta
	if _cooldown <= 0.0 and offset.length() <= enemy.behavior.attack_range and not _is_ghost():
		machine.transition_to(&"Telegraph")


func _is_ghost() -> bool:
	return enemy.behavior.move_style == EnemyData.MoveStyle.PHASE and enemy.is_hidden()


func _desired_direction(offset: Vector2) -> Vector2:
	var toward: Vector2 = offset.normalized()
	if enemy.behavior.move_style != EnemyData.MoveStyle.KEEP_DISTANCE:
		return toward
	var distance: float = offset.length()
	if distance > enemy.behavior.preferred_distance + DISTANCE_MARGIN:
		return toward
	if distance < enemy.behavior.preferred_distance - DISTANCE_MARGIN:
		return -toward
	return toward.orthogonal() * _strafe_sign * STRAFE_FACTOR


## Salta hacia el jugador cada hop_interval y entre salto y salto frena.
func _hop(offset: Vector2, delta: float) -> void:
	_hop_left -= delta
	if _hop_left > 0.0:
		enemy.move_toward_velocity(Vector2.ZERO, delta)
		return
	_hop_left = enemy.behavior.hop_interval
	enemy.move_velocity = offset.normalized() * enemy.behavior.move_speed * HOP_BURST
	enemy.apply_velocity()
	enemy.visual.play_hop()
	AudioManager.play_sfx(&"hop", 0.2)


## Vuela hacia un punto que gira alrededor del jugador, bamboleándose.
func _fly(delta: float) -> void:
	_orbit_angle += ORBIT_SPEED * _strafe_sign * delta
	var goal: Vector2 = enemy.target.global_position + Vector2.from_angle(_orbit_angle) * enemy.behavior.preferred_distance
	var toward: Vector2 = (goal - enemy.global_position).normalized()
	var wobble: Vector2 = toward.orthogonal() * sin(_time * FLUTTER_SPEED) * FLUTTER
	enemy.move_toward_velocity((toward + wobble).normalized() * enemy.behavior.move_speed, delta)


func _update_phase(delta: float) -> void:
	_phase_left -= delta
	if _phase_left > 0.0:
		return
	var to_ghost: bool = not enemy.is_hidden()
	enemy.set_hidden(to_ghost)
	_phase_left = enemy.behavior.ghost_time if to_ghost else enemy.behavior.solid_time
