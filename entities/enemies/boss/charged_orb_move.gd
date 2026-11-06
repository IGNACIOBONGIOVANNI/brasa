class_name ChargedOrbMove
extends BossMove
## CHARGED_ORB: junta fuego arriba de la cabeza durante `warn_time` s (una ChargedOrb que crece hasta
## `radius`) y la tira hacia el jugador a `speed` px/s como una bala enorme y lenta que pega `damage`
## (un corazón entero). El Pulso la borra como a cualquier bala. `count` bolas seguidas.

const ORB_SCENE: PackedScene = preload("res://entities/enemies/charged_orb.tscn")
## A qué altura sobre el jefe la junta.
const HOLD_HEIGHT: float = 26.0
const THROW_TRAUMA: float = 0.35
## Pausa después de tirar la última.
const AFTER_THROW: float = 0.3
## La bola empieza de este tamaño (fracción de `radius`).
const START_SIZE: float = 0.15

var _orb: ChargedOrb
var _left: int = 0
var _charge: float = 0.0
var _wait: float = 0.0


func _begin() -> void:
	_left = attack.count
	_start_charge()


func _tick(delta: float) -> bool:
	hold(delta)
	if _left <= 0:
		_wait += delta
		return _wait >= AFTER_THROW
	_charge += delta
	if is_instance_valid(_orb):
		_orb.global_position = _hold_point()
		_orb.radius = attack.radius * clampf(_charge / attack.warn_time, START_SIZE, 1.0)
	if _charge >= attack.warn_time:
		_throw()
		_left -= 1
		if _left > 0:
			_start_charge()
	return false


func _end() -> void:
	if is_instance_valid(_orb):
		_orb.queue_free()
	_orb = null


func _hold_point() -> Vector2:
	return clamp_to_room(enemy.global_position + Vector2(0, -HOLD_HEIGHT), attack.radius + 2.0)


func _start_charge() -> void:
	_charge = 0.0
	if is_instance_valid(_orb):
		_orb.queue_free()
	_orb = Fx.spawn(enemy.get_tree(), ORB_SCENE, _hold_point()) as ChargedOrb
	_orb.radius = attack.radius * START_SIZE
	if attack.pattern != null:
		_orb.color = attack.pattern.bullet_color
	AudioManager.play_sfx(&"rail_charge", 0.05)


func _throw() -> void:
	var at: Vector2 = _hold_point()
	if is_instance_valid(_orb):
		_orb.queue_free()
	_orb = null
	if attack.pattern == null:
		return
	var spec := ShotSpec.from_pattern(attack.pattern)
	spec.damage = attack.damage
	spec.radius = attack.radius
	spec.speed = attack.speed * enemy.bullet_speed_multiplier
	var offset: Vector2 = target_position() - at
	var direction: Vector2 = offset.normalized() if offset != Vector2.ZERO else Vector2.DOWN
	Bullet.spawn(enemy.get_tree(), Bullet.default_scene(), spec, at, direction, PhysicsLayers.ENEMY_BULLET,
			PhysicsLayers.WALL | PhysicsLayers.PLAYER_HURTBOX)
	enemy.visual.play_hit()
	EventBus.shake_requested.emit(THROW_TRAUMA)
	AudioManager.play_sfx(&"rocket", 0.05)
