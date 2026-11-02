class_name SnipeMove
extends BossMove
## SNIPE: salta a una punta de la sala lejos del jugador y le apunta con una mira láser que lo sigue
## `warn_time` s. Después la mira queda trabada `lock_time` s (titila blanca: hay que rodar, de costado
## no da el tiempo) y dispara un rayo por esa línea. `count` disparos seguidos (los siguientes apuntan
## un poco menos). Una roca en el medio también lo frena.

const HEIGHT: float = 120.0
## Salto hasta la punta: sube, vuela y baja.
const JUMP_TIME: float = 0.55
## Cuánto dura el disparo.
const FIRE_TIME: float = 0.14
## Los disparos después del primero apuntan esta fracción de warn_time.
const FOLLOW_UP_AIM: float = 0.65
## Qué tan adentro de las esquinas se para.
const PERCH_INSET: float = 22.0
const SHOT_TRAUMA: float = 0.35

enum Step { JUMP, AIM, LOCK, FIRE }

var _step: Step = Step.JUMP
var _left: int = 0
var _time: float = 0.0
var _from: Vector2 = Vector2.ZERO
var _perch: Vector2 = Vector2.ZERO


func _begin() -> void:
	_left = attack.count
	_from = enemy.global_position
	_perch = _pick_perch()
	enemy.set_airborne(true)
	AudioManager.play_sfx(&"leap", 0.1)
	_next(Step.JUMP)


func _tick(delta: float) -> bool:
	_time += delta
	match _step:
		Step.JUMP:
			var t: float = minf(_time / JUMP_TIME, 1.0)
			enemy.global_position = _from.lerp(_perch, t)
			enemy.visual.set_lift(HEIGHT * 4.0 * t * (1.0 - t))
			if t >= 1.0:
				enemy.visual.set_lift(0.0)
				enemy.set_airborne(false)
				EventBus.shake_requested.emit(SHOT_TRAUMA * 0.5)
				_aim()
		Step.AIM:
			hold(delta)
			_point_at_target()
			enemy.beam.preview(enemy.beam_origin(), enemy.beam_direction, true)
			if _time >= _aim_time():
				AudioManager.play_sfx(&"telegraph", 0.02)
				_next(Step.LOCK)
		Step.LOCK:
			hold(delta)
			enemy.beam.preview(enemy.beam_origin(), enemy.beam_direction, true, true)
			if _time >= attack.lock_time:
				AudioManager.play_sfx(&"sniper", 0.05)
				EventBus.shake_requested.emit(SHOT_TRAUMA)
				_next(Step.FIRE)
		Step.FIRE:
			hold(delta)
			enemy.beam.fire(enemy.beam_origin(), enemy.beam_direction, attack.damage)
			if _time >= FIRE_TIME:
				enemy.beam.stop()
				_left -= 1
				if _left <= 0:
					return true
				_aim()
	return false


func _end() -> void:
	enemy.beam.stop()
	enemy.visual.set_lift(0.0)
	enemy.set_airborne(false)


func _aim() -> void:
	AudioManager.play_sfx(&"aim", 0.05)
	_point_at_target()
	_next(Step.AIM)


func _aim_time() -> float:
	return attack.warn_time if _left == attack.count else attack.warn_time * FOLLOW_UP_AIM


func _point_at_target() -> void:
	var offset: Vector2 = target_position() - enemy.global_position
	if offset != Vector2.ZERO:
		enemy.beam_direction = offset.normalized()


func _next(step: Step) -> void:
	_step = step
	_time = 0.0


## Una de las dos esquinas más lejos del jugador (al azar), donde se pueda parar.
func _pick_perch() -> Vector2:
	var area: Rect2 = enemy.room_rect().grow(-(PERCH_INSET + enemy.data.body_radius))
	var corners: Array[Vector2] = [area.position, Vector2(area.end.x, area.position.y), area.end,
			Vector2(area.position.x, area.end.y)]
	var player: Vector2 = target_position()
	corners.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_to(player) > b.distance_to(player))
	return enemy.landing_spot(corners[rng().randi_range(0, 1)])
