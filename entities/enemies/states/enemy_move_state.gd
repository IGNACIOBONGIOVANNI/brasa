class_name EnemyMoveState
extends State
## Se mueve según behavior.move_style y, cuando pasó el cooldown y el jugador está a tiro, pasa a
## Telegraph (el aviso) antes de atacar. CHASE persigue, KEEP_DISTANCE mantiene la distancia, HOP
## avanza a saltos, FLY vuela en círculos alrededor del jugador, STAY no se mueve, BURROW persigue bajo
## tierra (asoma recién al atacar) y PHASE persigue alternando entre sólido y fantasma (solo ataca
## sólido), BOUNCE rueda derecho rebotando en paredes, rocas y fosos y PROWL ronda al jugador por el
## piso (si algo tapa el camino, lo rodea). Los que caminan rodean rocas y fosos
## (Enemy.route_direction) y los que embisten solo avisan si tienen el camino libre: así no se quedan
## embistiendo contra un foso o una roca. Los que embisten en línea recta (`charge_axis_only`) esperan
## a que el jugador quede en su fila o columna.
## Un jefe con movimientos propios pasa a BossAttack en vez de Telegraph.

## Margen alrededor de preferred_distance donde se mueve de costado en vez de acercarse o alejarse.
const DISTANCE_MARGIN: float = 14.0
const STRAFE_FACTOR: float = 0.6
## HOP: velocidad del salto en veces move_speed (después frena con su aceleración).
const HOP_BURST: float = 3.2
## FLY: radianes por segundo que gira alrededor del jugador y cuánto se bambolea.
const ORBIT_SPEED: float = 1.3
const FLUTTER: float = 0.5
const FLUTTER_SPEED: float = 7.0
## charge_axis_only: cuánto puede estar corrido el jugador de la fila o la columna (px).
const AXIS_TOLERANCE: float = 10.0

## Fracción del cooldown después de un cambio de fase.
const PHASE_RUSH: float = 0.2

var _cooldown: float = 0.0
var _strafe_sign: float = 1.0
var _hop_left: float = 0.0
var _orbit_angle: float = 0.0
var _phase_left: float = 0.0
var _time: float = 0.0
## BOUNCE: hacia dónde rueda (queda entre ataque y ataque).
var _roll_direction: Vector2 = Vector2.ZERO

@onready var enemy: Enemy = owner as Enemy


func enter(previous: StringName) -> void:
	var rng: RandomNumberGenerator = GameRNG.stream(RngStreams.COMBAT)
	# Recién aparecido ataca antes; un jefe que acaba de cambiar de fase, enseguida (así se ve lo nuevo);
	# después de un ataque espera el cooldown completo.
	var factor: float = 1.0
	if previous == &"Idle":
		factor = 0.5
	if enemy.take_phase_rush():
		factor = PHASE_RUSH
	_cooldown = enemy.roll_attack_cooldown(factor)
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
			_hop(enemy.route_direction(delta), delta)
		EnemyData.MoveStyle.FLY:
			_fly(delta)
		EnemyData.MoveStyle.PROWL:
			if enemy.has_clear_path(enemy.target.global_position):
				_fly(delta)
			else:
				enemy.move_toward_velocity(enemy.route_direction(delta) * enemy.behavior.move_speed, delta)
		EnemyData.MoveStyle.BOUNCE:
			_bounce(offset)
		EnemyData.MoveStyle.STAY:
			enemy.move_toward_velocity(Vector2.ZERO, delta)
		_:
			var toward: Vector2 = enemy.route_direction(delta)
			enemy.move_toward_velocity(_desired_direction(offset, toward) * enemy.behavior.move_speed, delta)
	enemy.look_at_target()
	if enemy.behavior.move_style == EnemyData.MoveStyle.PHASE:
		_update_phase(delta)
	_cooldown -= delta
	if _cooldown <= 0.0 and offset.length() <= enemy.behavior.attack_range and not _is_ghost() and _can_attack():
		machine.transition_to(&"BossAttack" if enemy.has_boss_attacks() else &"Telegraph")


func _is_ghost() -> bool:
	return enemy.behavior.move_style == EnemyData.MoveStyle.PHASE and enemy.is_hidden()


## Embestir contra algo que tapa el camino (un foso, una roca) lo dejaría empujando ahí: espera a
## tenerlo libre mientras camina rodeándolo.
func _can_attack() -> bool:
	if enemy.behavior.attack_kind != EnemyData.AttackKind.CHARGE or enemy.has_boss_attacks():
		return true
	if enemy.behavior.charge_axis_only:
		# Las rocas las rompe: solo un foso en el medio lo frena.
		var offset: Vector2 = enemy.to_target()
		if absf(offset.x) > AXIS_TOLERANCE and absf(offset.y) > AXIS_TOLERANCE:
			return false
		return enemy.has_clear_path(enemy.target.global_position, PhysicsLayers.PIT)
	return enemy.has_clear_path(enemy.target.global_position)


## Rueda derecho a move_speed; al chocar algo rebota. Arranca en diagonal, más o menos hacia el
## jugador.
func _bounce(offset: Vector2) -> void:
	if _roll_direction == Vector2.ZERO:
		_roll_direction = Vector2(1.0 if offset.x >= 0.0 else -1.0, 1.0 if offset.y >= 0.0 else -1.0).normalized()
	enemy.move_velocity = _roll_direction * enemy.behavior.move_speed
	enemy.apply_velocity()
	if enemy.get_slide_collision_count() > 0:
		var normal: Vector2 = enemy.get_slide_collision(0).get_normal()
		if _roll_direction.dot(normal) < 0.0:
			_roll_direction = _roll_direction.bounce(normal).normalized()
	enemy.visual.set_look(_roll_direction)


## `toward`: hacia el jugador, rodeando lo que tape el camino.
func _desired_direction(offset: Vector2, toward: Vector2) -> Vector2:
	if enemy.behavior.move_style != EnemyData.MoveStyle.KEEP_DISTANCE:
		return toward
	var distance: float = offset.length()
	if distance > enemy.behavior.preferred_distance + DISTANCE_MARGIN:
		return toward
	if distance < enemy.behavior.preferred_distance - DISTANCE_MARGIN:
		return -offset.normalized()
	return offset.normalized().orthogonal() * _strafe_sign * STRAFE_FACTOR


## Salta hacia el jugador (rodeando lo que tape el camino) cada hop_interval y entre salto y salto
## frena.
func _hop(toward: Vector2, delta: float) -> void:
	_hop_left -= delta
	if _hop_left > 0.0:
		enemy.move_toward_velocity(Vector2.ZERO, delta)
		return
	_hop_left = enemy.behavior.hop_interval
	enemy.move_velocity = toward * enemy.behavior.move_speed * HOP_BURST
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
