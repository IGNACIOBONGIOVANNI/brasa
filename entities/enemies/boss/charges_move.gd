class_name ChargesMove
extends BossMove
## CHARGES: `count` embestidas seguidas a `speed` px/s. Antes de cada una se frena y muestra
## `warn_time` s la línea por donde va a pasar; corta al chocar (sacudida y, con `pattern`, una
## lluvia de balas). Si un foso o una roca tapan el camino hasta el jugador no embiste: termina y el
## jefe vuelve a caminar, rodeándolo (así no se queda embistiendo contra el foso).

## Lo más que dura una embestida.
const MAX_DASH_TIME: float = 1.0
## Pausa entre embestidas.
const GAP_TIME: float = 0.2
const BUMP_TRAUMA: float = 0.4
const BULLET_SCENE: PackedScene = preload("res://entities/bullets/bullet.tscn")

enum Step { AIM, DASH, GAP }

var _step: Step = Step.AIM
var _left: int = 0
var _time: float = 0.0
var _direction: Vector2 = Vector2.DOWN
var _beam_color: Color
var _blocked: bool = false


func _begin() -> void:
	_left = attack.count
	_beam_color = enemy.beam.color
	enemy.beam.color = enemy.data.body_color.lightened(0.35)
	_aim()


func _tick(delta: float) -> bool:
	if _blocked:
		return true
	_time += delta
	match _step:
		Step.AIM:
			hold(delta)
			_point_at_target()
			enemy.beam.preview(enemy.global_position, _direction)
			if _time >= attack.warn_time:
				enemy.beam.stop()
				enemy.visual.set_charging(true)
				AudioManager.play_sfx(&"charge", 0.05)
				_next(Step.DASH)
		Step.DASH:
			enemy.move_velocity = _direction * attack.speed
			enemy.apply_velocity()
			if enemy.get_slide_collision_count() > 0:
				_bump()
				_end_dash()
			elif _time >= MAX_DASH_TIME:
				_end_dash()
		Step.GAP:
			enemy.move_toward_velocity(Vector2.ZERO, delta)
			if _time >= GAP_TIME:
				if _left <= 0:
					return true
				_aim()
	return false


func _end() -> void:
	enemy.beam.stop()
	enemy.beam.color = _beam_color
	enemy.visual.set_charging(false)


func _aim() -> void:
	if not enemy.has_target() or not enemy.has_clear_path(target_position()):
		_blocked = true
		return
	_point_at_target()
	_next(Step.AIM)


func _end_dash() -> void:
	enemy.visual.set_charging(false)
	enemy.move_velocity *= 0.3
	_left -= 1
	_next(Step.GAP)


func _bump() -> void:
	EventBus.shake_requested.emit(BUMP_TRAUMA)
	AudioManager.play_sfx(&"rock_break", 0.1)
	if attack.pattern == null:
		return
	var spec := ShotSpec.from_pattern(attack.pattern)
	spec.speed *= enemy.bullet_speed_multiplier
	for direction: Vector2 in PatternMath.ring(attack.pattern.count, rng().randf() * TAU):
		Bullet.spawn(enemy.get_tree(), BULLET_SCENE, spec, enemy.global_position + direction * enemy.data.body_radius,
				direction, PhysicsLayers.ENEMY_BULLET, PhysicsLayers.WALL | PhysicsLayers.PLAYER_HURTBOX)


func _point_at_target() -> void:
	var offset: Vector2 = target_position() - enemy.global_position
	if offset != Vector2.ZERO:
		_direction = offset.normalized()
		enemy.visual.set_look(_direction)


func _next(step: Step) -> void:
	_step = step
	_time = 0.0
